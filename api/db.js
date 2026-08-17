const { Pool } = require("pg");
require("dotenv").config();

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

pool.on("error", (err) => {
    console.error("Unexpected PostgreSQL pool error:", err);
});

module.exports = {
    query: (text, params) => pool.query(text, params),

    transaction: async (callback) => {
        const client = await pool.connect();

        try {
            await client.query("BEGIN");

            const result = await callback(client);

            await client.query("COMMIT");

            return result;
        } catch (error) {
            await client.query("ROLLBACK");
            throw error;
        } finally {
            client.release();
        }
    },
};