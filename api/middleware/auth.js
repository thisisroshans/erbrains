const { verifyToken } = require("../utils/jwt");

/**
 * Verifies the JWT issued by POST /auth/login (see utils/jwt.js) and
 * exposes the caller's identity as req.auth. Every route mounted after
 * requireAuth in app.js requires a valid, unexpired token; routes that
 * also take a userId in the body/query should additionally call
 * ensureSelf so a valid token for user A can't be used to read or write
 * user B's data just by passing a different userId.
 */
function requireAuth(req, res, next) {
    const header = req.headers.authorization || "";
    const [scheme, token] = header.split(" ");

    if (scheme !== "Bearer" || !token) {
        return res.status(401).json({
            error: "Missing or invalid authorization token",
        });
    }

    const payload = verifyToken(token);

    if (!payload) {
        return res.status(401).json({
            error: "Missing or invalid authorization token",
        });
    }

    req.auth = { userId: payload.userId, email: payload.email };
    next();
}

/**
 * Call from inside a route handler once you have the userId the request
 * claims to act on. Returns false (and has already sent a 403) if it
 * doesn't match the authenticated caller.
 */
function ensureSelf(req, res, userId) {
    if (!userId || userId !== req.auth.userId) {
        res.status(403).json({
            error: "Cannot act on behalf of another user",
        });
        return false;
    }

    return true;
}

module.exports = { requireAuth, ensureSelf };
