# Governed AIGen Music generation

The default `text2music` path in this fork is routed through the AIGen Music local service rather than directly to ACE-Step.

```text
React UI
  -> ACE-Step UI Express server
      -> AIGen Music :8100
          -> resource admission
          -> serialized generation
          -> provenance / lyric integrity
          -> ACE-Step :8001
```

## Supported governed controls

The first governed path carries:

- simple song description or custom style prompt
- authored lyrics
- instrumental mode
- title
- vocal language
- duration
- BPM
- key / scale
- time signature
- DiT model
- thinking
- deterministic/random seed
- inference steps
- audio format
- one candidate per job

Authored lyrics use the AIGen Music `VERBATIM` policy.

## Candidate count

AIGen Music v1 currently requires provider batch size 1. The UI's bulk-generation mechanism already submits separate jobs; that is the preferred basis for multiple first-class candidates.

A provider batch greater than 1 is rejected rather than silently collapsing several ACE outputs into one artifact.

## Advanced controls

Text-to-music requests using controls that have not yet been promoted into the governed contract are rejected explicitly. They are not silently ignored and they do not fall back around the resource governor.

Examples include:

- reference audio
- audio-code hints
- LoRA
- non-default low-level sampler / LM controls
- AutoGen
- track extraction/completion controls

These can be promoted incrementally as first-class AIGen Music contracts.

## Legacy ACE modes

Non-text generation modes such as cover/repaint remain on the upstream direct-ACE implementation temporarily. They are considered legacy migration paths and are not yet protected by the full AIGen resource boundary.

## Runtime status

The UI backend exposes:

```text
GET /api/generate/runtime
```

which proxies AIGen Music `GET /v1/runtime`. It reports states such as:

- `STOPPED`
- `READY`
- `BUSY`
- `BLOCKED_BY_RESOURCES`
- `ERROR`

A stopped or resource-blocked ACE runtime does not prevent the rest of the UI from running.

## Failure semantics

If AIGen Music rejects a generation because of memory pressure or an unavailable ACE runtime:

- no direct ACE fallback occurs for text-to-music
- the local generation record is marked failed
- the HTTP error is returned to the frontend
- LM Studio or other external processes are never terminated automatically
