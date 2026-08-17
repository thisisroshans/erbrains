const db = require("../db");

/**
 * Returns true if the reading was newly inserted, false if it was a
 * duplicate silently absorbed by the (device_id, reading_timestamp)
 * unique constraint.
 */
async function insertReading({ deviceId, userId, heartRate, spo2, steps, timestamp }) {
    const result = await db.query(
        `
        INSERT INTO health_readings (
            device_id,
            user_id,
            heart_rate,
            spo2,
            steps,
            reading_timestamp
        )
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (device_id, reading_timestamp)
        DO NOTHING
        RETURNING id
        `,
        [deviceId, userId, heartRate, spo2, steps, timestamp]
    );
    return result.rowCount === 1;
}

async function findByUser(userId, { limit, offset }) {
    const result = await db.query(
        `
        SELECT *
        FROM health_readings
        WHERE user_id = $1
        ORDER BY reading_timestamp DESC
        LIMIT $2
        OFFSET $3
        `,
        [userId, limit, offset]
    );
    return result.rows;
}

async function getSummary(userId, period) {
    const truncation = period === "weekly" ? "week" : "day";

    const result = await db.query(
        `
        SELECT
            DATE_TRUNC('${truncation}', reading_timestamp) AS period_date,
            AVG(heart_rate)::INT AS avg_heart_rate,
            MIN(heart_rate) AS min_heart_rate,
            MAX(heart_rate) AS max_heart_rate,
            AVG(spo2)::INT AS avg_spo2,
            MIN(spo2) AS min_spo2,
            MAX(steps) AS total_steps
        FROM health_readings
        WHERE user_id = $1
          AND reading_timestamp >= NOW() - INTERVAL '7 days'
        GROUP BY period_date
        ORDER BY period_date ASC
        `,
        [userId]
    );
    return result.rows;
}

module.exports = { insertReading, findByUser, getSummary };
