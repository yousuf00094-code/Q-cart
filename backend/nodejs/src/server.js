require('dotenv').config();

const app    = require('./app');
const { pool } = require('./config/database');
const logger = require('./utils/logger');
const { runMigrations } = require('../scripts/migrate');

const PORT = parseInt(process.env.PORT || '3000', 10);

const start = () => {
  logger.info('Starting Q Cart API...');

  const server = app.listen(PORT, '0.0.0.0', () => {
    logger.info(`Listening on host 0.0.0.0 port ${PORT} [${process.env.NODE_ENV || 'development'}]`);
    logger.info('Health endpoint ready');

    // Run migrations after port is bound so health checks pass immediately.
    // A migration failure is logged but never crashes the server.
    logger.info('[migrate] Migration started');
    runMigrations()
      .then(() => logger.info('[migrate] Migration completed'))
      .catch((err) => logger.error('[migrate] Migration failed — server remains up', { error: err.message }));
  });

  const shutdown = async (signal) => {
    logger.info(`${signal} received — shutting down gracefully`);
    server.close(async () => {
      await pool.end();
      logger.info('Database pool closed');
      process.exit(0);
    });
    setTimeout(() => {
      logger.error('Forced shutdown after timeout');
      process.exit(1);
    }, 10000);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT',  () => shutdown('SIGINT'));
  process.on('uncaughtException', (err) => {
    logger.error('Uncaught exception', { error: err.message, stack: err.stack });
    process.exit(1);
  });
  process.on('unhandledRejection', (reason) => {
    logger.error('Unhandled rejection', { reason });
    process.exit(1);
  });
};

start();
