const db = require("../db");

async function upsert({ deviceId, userId, name }) {
    const result = await db.query(
        `
        INSERT INTO devices (
            id,
            user_id,
            name,
            status
        )
        VALUES ($1, $2, $3, 'connected')
        ON CONFLICT (id)
        DO UPDATE SET
            status = 'connected',
            user_id = $2
        RETURNING *
        `,
        [deviceId, userId, name]
    );
    return result.rows[0];
}

async function findByUser(userId) {
    const result = await db.query(
        `
        SELECT *
        FROM devices
        WHERE user_id = $1
        ORDER BY created_at DESC
        `,
        [userId]
    );
    return result.rows;
}

module.exports = { upsert, findByUser };
