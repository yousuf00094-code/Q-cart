require('dotenv').config();

const app    = require('./app');
const { pool } = require('./config/database');
const logger = require('./utils/logger');

const PORT = parseInt(process.env.PORT || '3000', 10);

const start = async () => {
  // Verify DB connectivity before accepting traffic
  try {
    await pool.query('SELECT 1');
    logger.info('PostgreSQL connection established');
  } catch (err) {
    logger.error('Failed to connect to PostgreSQL', { error: err.message });
    process.exit(1);
  }

  const server = app.listen(PORT, '0.0.0.0', () => {
    logger.info(`Q Cart API listening on port ${PORT} [${process.env.NODE_ENV || 'development'}]`);
  });

  // Graceful shutdown
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
