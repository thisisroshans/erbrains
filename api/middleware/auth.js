/**
 * Verifies the opaque token issued by POST /auth/login (a base64url blob,
 * not a JWT — see auth.routes.js) and exposes the caller's identity as
 * req.auth. Every route mounted after requireAuth in app.js requires a
 * valid token; routes that also take a userId in the body/query should
 * additionally call ensureSelf so a valid token for user A can't be used
 * to read or write user B's data just by passing a different userId.
 */

function decodeToken(token) {
    try {
        const json = Buffer.from(token, "base64url").toString("utf8");
        const payload = JSON.parse(json);

        if (!payload || typeof payload.userId !== "string" || typeof payload.email !== "string") {
            return null;
        }

        return payload;
    } catch {
        return null;
    }
}

function requireAuth(req, res, next) {
    const header = req.headers.authorization || "";
    const [scheme, token] = header.split(" ");

    if (scheme !== "Bearer" || !token) {
        return res.status(401).json({
            error: "Missing or invalid authorization token",
        });
    }

    const payload = decodeToken(token);

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
