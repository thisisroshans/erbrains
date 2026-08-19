const jwt = require("jsonwebtoken");

// Mobile session, not a web app's — long-lived on purpose so the user isn't
// re-prompted to log in every few hours. No refresh-token rotation: that's
// a deliberate scope line, not an oversight — see docs/DECISIONS.md.
const EXPIRES_IN = "7d";

function secret() {
    const value = process.env.JWT_SECRET;
    if (!value) {
        throw new Error("JWT_SECRET is not set — see .env.example");
    }
    return value;
}

function signToken({ userId, email }) {
    return jwt.sign({ userId, email }, secret(), { expiresIn: EXPIRES_IN });
}

/**
 * Returns the decoded { userId, email }, or null if the token is missing,
 * malformed, expired, or has an invalid signature — every failure mode
 * collapses to the same "not authenticated" outcome for the caller.
 */
function verifyToken(token) {
    try {
        const payload = jwt.verify(token, secret());
        if (typeof payload.userId !== "string" || typeof payload.email !== "string") {
            return null;
        }
        return { userId: payload.userId, email: payload.email };
    } catch {
        return null;
    }
}

module.exports = { signToken, verifyToken };
