require('dotenv').config();

const path        = require('path');
const express     = require('express');
const helmet      = require('helmet');
const cors        = require('cors');
const morgan      = require('morgan');
const compression = require('compression');
const cookieParser = require('cookie-parser');

const routes = require('./routes');
const { errorHandler } = require('./middleware/errorHandler');
const { defaultLimiter } = require('./middleware/rateLimiter');
const logger = require('./utils/logger');

const app = express();

// ── Health check — before every middleware ────────────────────────────────
// Render (and any infrastructure probe) sends GET /v1/health with no Origin
// header. Registering this route first guarantees it is never blocked by
// CORS, rate-limiting, authentication, or any other middleware.
app.get('/v1/health', (_req, res) =>
  res.json({ status: 'ok', timestamp: new Date().toISOString(), version: '1.0.0' })
);

// ── Security ──────────────────────────────────────────────────────────────
app.use(helmet());
app.set('trust proxy', 1);

// ── CORS ──────────────────────────────────────────────────────────────────
// CORS_ORIGINS is a comma-separated list of allowed browser origins.
// The special value "*" permits any browser origin (suitable for open/demo APIs).
// Requests without an Origin header are server-to-server or CLI tools — CORS
// does not apply to them; pass them through unconditionally.
const rawOrigins = (process.env.CORS_ORIGINS || '').split(',').map((o) => o.trim()).filter(Boolean);
const allowAllOrigins = rawOrigins.includes('*');

app.use(cors({
  origin: (origin, cb) => {
    if (!origin) return cb(null, true);           // no Origin = not a browser cross-origin request
    if (allowAllOrigins) return cb(null, true);   // CORS_ORIGINS=*
    if (rawOrigins.includes(origin)) return cb(null, true);
    cb(new Error(`CORS: origin ${origin} is not allowed`));
  },
  credentials: true,
}));

// ── Body / Cookie ─────────────────────────────────────────────────────────
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(compression());

// ── Logging ───────────────────────────────────────────────────────────────
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev', {
  stream: { write: (msg) => logger.http(msg.trim()) },
}));

// ── Rate limiting ─────────────────────────────────────────────────────────
app.use('/v1', defaultLimiter);

// ── Static files — uploaded images ────────────────────────────────────────
const uploadDir = process.env.UPLOAD_DIR
  ? path.resolve(process.env.UPLOAD_DIR)
  : path.join(__dirname, '..', 'uploads', 'images');
app.use('/uploads/images', express.static(uploadDir));

// ── Routes ────────────────────────────────────────────────────────────────
app.use('/v1', routes);

// ── 404 ───────────────────────────────────────────────────────────────────
app.use((req, res) =>
  res.status(404).json({ error: { code: 'NOT_FOUND', message: `Route ${req.method} ${req.path} not found.` } })
);

// ── Error handler ─────────────────────────────────────────────────────────
app.use(errorHandler);

module.exports = app;
