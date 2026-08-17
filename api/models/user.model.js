const db = require("../db");

async function findByEmail(normalizedEmail) {
    const result = await db.query(
        `
        SELECT id, email, name, password_hash
        FROM users
        WHERE LOWER(email) = $1
        LIMIT 1
        `,
        [normalizedEmail]
    );
    return result.rows[0] || null;
}

async function create({ email, passwordHash, name }) {
    const result = await db.query(
        `
        INSERT INTO users (email, password_hash, name)
        VALUES ($1, $2, $3)
        RETURNING id, email, name
        `,
        [email, passwordHash, name]
    );
    return result.rows[0];
}

module.exports = { findByEmail, create };
