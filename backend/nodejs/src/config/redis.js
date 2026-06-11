const Redis = require('ioredis');

let client = null;

const getClient = () => {
  if (client) return client;
  if (!process.env.REDIS_URL) return null;

  client = new Redis(process.env.REDIS_URL, {
    maxRetriesPerRequest: 3,
    enableReadyCheck: false,
    lazyConnect: true,
    connectTimeout: 5000,
  });

  client.on('error', (err) => {
    // Log but don't crash — app degrades gracefully without Redis
    console.error('[Redis] connection error:', err.message);
  });

  return client;
};

module.exports = { getClient };
