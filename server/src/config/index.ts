import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const config = {
  port: parseInt(process.env.PORT || '3001', 10),
  nodeEnv: process.env.NODE_ENV || 'development',

  database: {
    path: process.env.DATABASE_PATH || path.join(__dirname, '../../data/acestep.db'),
  },

  // Direct ACE access remains for legacy routes during migration.
  // Governed generation will move to aigenMusic.apiUrl.
  acestep: {
    apiUrl: process.env.ACESTEP_API_URL || 'http://127.0.0.1:8001',
  },

  aigenMusic: {
    apiUrl: process.env.AIGEN_MUSIC_API_URL || 'http://127.0.0.1:8100',
  },

  pexels: {
    apiKey: process.env.PEXELS_API_KEY || '',
  },

  frontendUrl: process.env.FRONTEND_URL || 'http://localhost:3000',

  storage: {
    provider: 'local' as const,
    audioDir: process.env.AUDIO_DIR || path.join(__dirname, '../../public/audio'),
  },

  datasets: {
    dir: process.env.DATASETS_DIR || path.join(__dirname, '../../../ACE-Step-1.5/datasets'),
    uploadsDir: process.env.DATASETS_UPLOADS_DIR || path.join(__dirname, '../../../ACE-Step-1.5/datasets/uploads'),
  },

  jwt: {
    secret: process.env.JWT_SECRET || 'ace-step-ui-local-secret',
    expiresIn: '365d',
  },
};
