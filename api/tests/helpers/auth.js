// Builds the same base64url token shape auth.routes.js issues, so tests
// can exercise routes now that requireAuth guards everything except
// /auth/login and the public product GETs.

function makeToken(userId, email = "user@example.com") {
    return Buffer
        .from(JSON.stringify({ userId, email, issuedAt: Date.now() }))
        .toString("base64url");
}

function authHeader(userId, email) {
    return `Bearer ${makeToken(userId, email)}`;
}

module.exports = { makeToken, authHeader };
