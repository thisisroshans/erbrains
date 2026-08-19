const userModel = require("../models/user.model");
const { hashPassword, verifyPassword } = require("../utils/password");
const { signToken } = require("../utils/jwt");

/**
 * POST /auth/login
 *
 * Local-development authentication:
 * - Validates email/password
 * - Finds user by email
 * - Automatically creates user if not found
 * - Verifies password for existing users
 * - Returns a signed JWT (see utils/jwt.js)
 */
async function login(req, res) {
    try {
        const { email, password, name } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                error: "Email and password are required",
            });
        }

        const normalizedEmail = String(email).trim().toLowerCase();

        let user = await userModel.findByEmail(normalizedEmail);

        // --------------------------------------------------
        // User does not exist -> create user automatically
        // --------------------------------------------------
        if (!user) {
            user = await userModel.create({
                email: normalizedEmail,
                passwordHash: await hashPassword(password),
                name: name ? String(name).trim() : null,
            });
        }

        // --------------------------------------------------
        // User exists -> verify password
        // --------------------------------------------------
        else if (!(await verifyPassword(password, user.password_hash))) {
            return res.status(401).json({
                error: "Invalid email or password",
            });
        }

        const token = signToken({ userId: user.id, email: user.email });

        return res.status(200).json({
            token,
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
            },
        });

    } catch (error) {
        req.log?.error({ err: error }, "POST /auth/login error");

        return res.status(500).json({
            error: "Internal server error",
        });
    }
}

/**
 * POST /auth/logout
 *
 * The token is a stateless, self-contained JWT — there's no server-side
 * session to destroy, so this doesn't blacklist anything. It exists for a
 * complete REST surface (the assignment lists logout as a required auth
 * feature) and to give the client an explicit endpoint to call; the actual
 * security boundary is the token's own 7-day expiry, not revocation. A
 * revocation list was considered and deliberately not built — see
 * docs/DECISIONS.md for the trade-off.
 */
async function logout(req, res) {
    return res.status(200).json({ success: true });
}

module.exports = { login, logout };
