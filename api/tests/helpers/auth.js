// Issues a real, signed JWT the same way utils/jwt.js does, so tests
// exercise the actual verification path in middleware/auth.js instead of
// a hand-rolled stand-in.

const { signToken } = require("../../utils/jwt");

function makeToken(userId, email = "user@example.com") {
    return signToken({ userId, email });
}

function authHeader(userId, email) {
    return `Bearer ${makeToken(userId, email)}`;
}

module.exports = { makeToken, authHeader };
