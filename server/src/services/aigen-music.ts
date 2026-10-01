import { config } from '../config/index.js';

export class AigenMusicError extends Error {
  statusCode: number;
  code: string;

  constructor(statusCode: number, code: string, message: string) {
    super(message);
    this.name = 'AigenMusicError';
    this.statusCode = statusCode;
    this.code = code;
  }
}

type GenerationParams = Record<string, any>;

export interface AigenRuntimeStatus {
  runtime_state: string;
  snapshot?: {
    pressure?: string;
    ml_footprint_gib?: number;
    available_gib?: number;
    swap_used_gib?: number;
    ace_running?: boolean;
    loaded_models?: Array<{
      source?: string;
      identifier?: string;
      display_name?: string;
      size_gib?: number | null;
      status?: string | null;
    }>;
  };
  default_ace_admission?: {
    state?: string;
    admitted?: boolean;
    reasons?: string[];
    projected_ml_footprint_gib?: number;
    safe_batch_size?: number;
  };
}

export interface AigenJobStatus {
  status: 'queued' | 'running' | 'succeeded' | 'failed';
  queuePosition?: number;
  progress?: number;
  stage?: string;
  result?: {
    audioUrls: string[];
    duration?: number;
    bpm?: number;
    keyScale?: string;
    timeSignature?: string;
    status: string;
  };
  error?: string;
}

function endpoint(path: string): string {
  return `${config.aigenMusic.apiUrl.replace(/\/$/, '')}${path}`;
}

async function readError(response: Response): Promise<AigenMusicError> {
  let body: any = null;
  try {
    body = await response.json();
  } catch {
    // fall through
  }

  const detail = body?.detail;
  const code =
    (typeof detail === 'object' && detail?.code) ||
    body?.code ||
    'AIGEN_MUSIC_ERROR';
  const reasons =
    typeof detail === 'object' && Array.isArray(detail?.admission?.reasons)
      ? detail.admission.reasons.join('; ')
      : null;
  const message =
    reasons ||
    (typeof detail === 'object' && detail?.message) ||
    (typeof detail === 'string' ? detail : null) ||
    body?.message ||
    body?.error ||
    `AIGen Music request failed with HTTP ${response.status}`;

  return new AigenMusicError(response.status, String(code), String(message));
}

function assertSupportedTextToMusic(params: GenerationParams): void {
  const unsupported: string[] = [];

  if (params.referenceAudioUrl) unsupported.push('reference audio');
  if (params.sourceAudioUrl) unsupported.push('source audio');
  if (params.audioCodes) unsupported.push('audio-code hints');
  if (params.autogen) unsupported.push('AutoGen');
  if (params.loraLoaded) unsupported.push('LoRA');

  // These controls exist in upstream ACE-Step UI but are not yet first-class
  // in the governed AIGen Music v1 contract. Default values are safe because
  // ACE receives the same defaults through the provider.
  if (params.guidanceScale != null && params.guidanceScale !== 7.0) {
    unsupported.push('guidance scale');
  }
  if (params.inferMethod != null && params.inferMethod !== 'ode') {
    unsupported.push('inference method');
  }
  if (params.shift != null && params.shift !== 3.0) unsupported.push('shift');
  if (params.lmTemperature != null && params.lmTemperature !== 0.85) {
    unsupported.push('LM temperature');
  }
  if (params.lmCfgScale != null && params.lmCfgScale !== 2.0) {
    unsupported.push('LM CFG scale');
  }
  if (params.lmTopK != null && params.lmTopK !== 0) unsupported.push('LM top-k');
  if (params.lmTopP != null && params.lmTopP !== 0.9) unsupported.push('LM top-p');
  if (
    params.lmNegativePrompt &&
    params.lmNegativePrompt !== 'NO USER INPUT'
  ) {
    unsupported.push('LM negative prompt');
  }
  if (params.useAdg) unsupported.push('ADG');
  if (params.customTimesteps) unsupported.push('custom timesteps');
  if (params.getScores) unsupported.push('auto score');
  if (params.getLrc) unsupported.push('auto LRC');
  if (params.trackName) unsupported.push('track extraction/completion');
  if (Array.isArray(params.completeTrackClasses) && params.completeTrackClasses.length) {
    unsupported.push('track classes');
  }
  if (params.enhance) unsupported.push('AI enhance');
  if (params.repaintingStart != null && params.repaintingStart !== 0) {
    unsupported.push('repainting start');
  }
  if (params.repaintingEnd != null && params.repaintingEnd !== -1) {
    unsupported.push('repainting end');
  }
  if (
    params.instruction &&
    params.instruction !== 'Fill the audio semantic mask based on the given conditions:'
  ) {
    unsupported.push('custom instruction');
  }
  if (params.audioCoverStrength != null && params.audioCoverStrength !== 1.0) {
    unsupported.push('audio cover strength');
  }
  if (params.cfgIntervalStart != null && params.cfgIntervalStart !== 0.0) {
    unsupported.push('CFG interval start');
  }
  if (params.cfgIntervalEnd != null && params.cfgIntervalEnd !== 1.0) {
    unsupported.push('CFG interval end');
  }
  if (params.useCotMetas != null && params.useCotMetas !== true) {
    unsupported.push('CoT metadata toggle');
  }
  if (params.useCotCaption != null && params.useCotCaption !== true) {
    unsupported.push('CoT caption toggle');
  }
  if (params.useCotLanguage != null && params.useCotLanguage !== true) {
    unsupported.push('CoT language toggle');
  }
  if (params.constrainedDecodingDebug) unsupported.push('constrained decoding debug');
  if (params.allowLmBatch != null && params.allowLmBatch !== true) {
    unsupported.push('LM batch toggle');
  }
  if (params.scoreScale != null && params.scoreScale !== 0.5) {
    unsupported.push('score scale');
  }
  if (params.lmBatchChunkSize != null && params.lmBatchChunkSize !== 8) {
    unsupported.push('LM batch chunk size');
  }
  if (params.isFormatCaption) unsupported.push('format-caption state');

  if (unsupported.length) {
    throw new AigenMusicError(
      422,
      'UNSUPPORTED_GOVERNED_CONTROLS',
      `Governed text-to-music does not yet support: ${unsupported.join(', ')}`
    );
  }
}

export function usesGovernedAigenGeneration(params: GenerationParams): boolean {
  const taskType = params.taskType || 'text2music';
  return taskType === 'text2music';
}

export async function submitAigenGeneration(
  params: GenerationParams,
): Promise<{ jobId: string }> {
  assertSupportedTextToMusic(params);

  const prompt = params.customMode
    ? String(params.style || params.songDescription || '').trim()
    : String(params.songDescription || params.style || '').trim();

  if (!prompt) {
    throw new AigenMusicError(
      400,
      'MISSING_PROMPT',
      'A style or song description is required'
    );
  }

  const payload = {
    prompt,
    lyrics: params.instrumental ? '' : String(params.lyrics || ''),
    title: params.title || null,
    vocal_language: params.vocalLanguage || 'en',
    audio_format: params.audioFormat || 'flac',
    audio_duration:
      typeof params.duration === 'number' && params.duration > 0
        ? params.duration
        : null,
    bpm:
      typeof params.bpm === 'number' && params.bpm > 0
        ? params.bpm
        : null,
    key_scale: params.keyScale || null,
    time_signature: params.timeSignature || null,
    model: params.ditModel || 'acestep-v15-turbo',
    thinking: params.thinking ?? true,
    lyrics_policy: 'verbatim',
    use_random_seed: params.randomSeed ?? true,
    seed:
      typeof params.seed === 'number' && params.seed >= 0
        ? params.seed
        : 123456,
    batch_size: params.batchSize ?? 1,
    inference_steps: params.inferenceSteps ?? 8,
  };

  const response = await fetch(endpoint('/v1/generate'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    signal: AbortSignal.timeout(15_000),
  });

  if (!response.ok) throw await readError(response);
  const body = await response.json() as any;
  if (!body?.job_id) {
    throw new AigenMusicError(
      502,
      'MALFORMED_AIGEN_RESPONSE',
      'AIGen Music did not return a job ID'
    );
  }
  return { jobId: String(body.job_id) };
}

function mapState(state: string): AigenJobStatus['status'] {
  switch (state) {
    case 'QUEUED':
      return 'queued';
    case 'ADMITTED':
    case 'RUNNING':
      return 'running';
    case 'SUCCEEDED':
      return 'succeeded';
    case 'BLOCKED':
    case 'FAILED':
      return 'failed';
    default:
      return 'running';
  }
}

export async function getAigenJobStatus(jobId: string): Promise<AigenJobStatus> {
  const response = await fetch(endpoint(`/v1/jobs/${encodeURIComponent(jobId)}`), {
    signal: AbortSignal.timeout(5_000),
  });
  if (!response.ok) throw await readError(response);

  const body = await response.json() as any;
  const status = mapState(String(body?.state || ''));
  const request = body?.request || {};
  const extra = request?.extra || {};

  let result: AigenJobStatus['result'];
  if (status === 'succeeded' && body?.audio_url) {
    const audioUrl = new URL(String(body.audio_url), config.aigenMusic.apiUrl).toString();
    result = {
      audioUrls: [audioUrl],
      duration:
        typeof request.audio_duration === 'number'
          ? request.audio_duration
          : undefined,
      bpm: typeof extra.bpm === 'number' ? extra.bpm : undefined,
      keyScale: typeof extra.key_scale === 'string' ? extra.key_scale : undefined,
      timeSignature:
        typeof extra.time_signature === 'string'
          ? extra.time_signature
          : undefined,
      status: 'succeeded',
    };
  }

  return {
    status,
    queuePosition: status === 'queued' ? 1 : undefined,
    progress: status === 'succeeded' ? 100 : undefined,
    stage: body?.state,
    result,
    error: body?.error || undefined,
  };
}

export async function getAigenRuntime(): Promise<AigenRuntimeStatus> {
  const response = await fetch(endpoint('/v1/runtime'), {
    signal: AbortSignal.timeout(5_000),
  });
  if (!response.ok) throw await readError(response);
  return response.json() as Promise<AigenRuntimeStatus>;
}
