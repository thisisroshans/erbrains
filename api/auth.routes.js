const express = require("express");
const crypto = require("crypto");
const db = require("./db");

const router = express.Router();

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
router.post("/login", async (req, res) => {
    try {
        const { email, password, name } = req.body;

        // Validate required fields
        if (!email || !password) {
            return res.status(400).json({
                error: "Email and password are required",
            });
        }

        const normalizedEmail = String(email).trim().toLowerCase();

        // Find existing user
        let result = await db.query(
            `
            SELECT id, email, name, password_hash
            FROM users
            WHERE LOWER(email) = $1
            LIMIT 1
            `,
            [normalizedEmail]
        );

        let user;

        // --------------------------------------------------
        // User does not exist -> create user automatically
        // --------------------------------------------------
        if (result.rows.length === 0) {
            const passwordHash = crypto
                .createHash("sha256")
                .update(String(password))
                .digest("hex");

            result = await db.query(
                `
                INSERT INTO users (email, password_hash, name)
                VALUES ($1, $2, $3)
                RETURNING id, email, name
                `,
                [normalizedEmail, passwordHash, name ? String(name).trim() : null]
            );

            user = result.rows[0];
        }

        // --------------------------------------------------
        // User exists -> verify password
        // --------------------------------------------------
        else {
            user = result.rows[0];

            const passwordHash = crypto
                .createHash("sha256")
                .update(String(password))
                .digest("hex");

            if (user.password_hash !== passwordHash) {
                return res.status(401).json({
                    error: "Invalid email or password",
                });
            }
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

        // --------------------------------------------------
        // Successful response
        // --------------------------------------------------
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
});

module.exports = router;