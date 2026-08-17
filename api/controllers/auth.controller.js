const userModel = require("../models/user.model");
const { hashPassword } = require("../utils/password");

/**
 * POST /auth/login
 *
 * Local-development authentication:
 * - Validates email/password
 * - Finds user by email
 * - Automatically creates user if not found
 * - Verifies password for existing users
 * - Returns a mock auth token
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
                passwordHash: hashPassword(password),
                name: name ? String(name).trim() : null,
            });
        }

        // --------------------------------------------------
        // User exists -> verify password
        // --------------------------------------------------
        else if (user.password_hash !== hashPassword(password)) {
            return res.status(401).json({
                error: "Invalid email or password",
            });
        }

        // --------------------------------------------------
        // Generate local-development auth token
        // --------------------------------------------------
        const tokenPayload = {
            userId: user.id,
            email: user.email,
            issuedAt: Date.now(),
        };

        const token = Buffer
            .from(JSON.stringify(tokenPayload))
            .toString("base64url");

        return res.status(200).json({
            token,
            user: {
                id: user.id,
                email: user.email,
                name: user.name,
            },
        });

    } catch (error) {
        console.error("POST /auth/login error:", error);

        return res.status(500).json({
            error: "Internal server error",
        });
    }
}

module.exports = { login };
