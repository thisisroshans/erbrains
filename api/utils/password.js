const bcrypt = require("bcryptjs");

const SALT_ROUNDS = 10;

/**
 * bcryptjs — a pure-JS bcrypt implementation, not the native `bcrypt`
 * package. No node-gyp/native build step, which matters here: a reviewer
 * running this on an arbitrary machine shouldn't need a C++ toolchain just
 * to `npm install`. Slower per-hash than native bcrypt, an acceptable
 * trade at this app's login volume — see docs/DECISIONS.md.
 */
function hashPassword(password) {
    return bcrypt.hash(String(password), SALT_ROUNDS);
}

function verifyPassword(password, hash) {
    return bcrypt.compare(String(password), hash);
}

module.exports = { hashPassword, verifyPassword };
