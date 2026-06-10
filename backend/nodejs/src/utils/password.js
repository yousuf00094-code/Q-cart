const bcrypt = require('bcryptjs');

const ROUNDS = parseInt(process.env.BCRYPT_ROUNDS || '12', 10);

const hash   = (plain)        => bcrypt.hash(plain, ROUNDS);
const verify = (plain, hashed) => bcrypt.compare(plain, hashed);

module.exports = { hash, verify };
