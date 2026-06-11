'use strict';

/**
 * Runs all SQL migration files in order, then seeds demo data.
 * Safe to run on every deploy — all SQL files are idempotent.
 */

const { Client } = require('pg');
const fs   = require('fs');
const path = require('path');

const migrations = [
  path.join(__dirname, '../src/db/migrations/001_initial_schema.sql'),
  path.join(__dirname, '../src/db/migrations/002_supplier_apis.sql'),
];

const seeds = [
  path.join(__dirname, '../src/db/seeds/002_demo_accounts.sql'),
];

async function run() {
  const client = new Client({ connectionString: process.env.DATABASE_URL });
  await client.connect();
  console.log('[migrate] Connected to PostgreSQL');

  for (const file of migrations) {
    console.log(`[migrate] Running migration: ${path.basename(file)}`);
    const sql = fs.readFileSync(file, 'utf8');
    await client.query(sql);
    console.log(`[migrate] Done: ${path.basename(file)}`);
  }

  const shouldSeed = process.env.SEED_DEMO_DATA === 'true';
  if (shouldSeed) {
    for (const file of seeds) {
      console.log(`[migrate] Running seed: ${path.basename(file)}`);
      const sql = fs.readFileSync(file, 'utf8');
      await client.query(sql);
      console.log(`[migrate] Done: ${path.basename(file)}`);
    }
  }

  await client.end();
  console.log('[migrate] All done.');
}

run().catch(err => {
  console.error('[migrate] FATAL:', err.message);
  process.exit(1);
});
