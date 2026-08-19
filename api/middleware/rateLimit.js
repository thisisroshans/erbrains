const rateLimit = require("express-rate-limit");

/**
 * Brute-force protection on login specifically — 5 attempts per 15 minutes
 * per IP. Applied only here, not globally: every other route already
 * requires a valid token, so the attack this defends against (guessing a
 * password) doesn't apply to them.
 */
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: "Too many login attempts — try again in a few minutes" },
});

module.exports = { loginLimiter };
