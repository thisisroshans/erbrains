require("dotenv").config();

const fs = require("fs");
const path = require("path");
const { Pool } = require("pg");
const { hashPassword } = require("../utils/password");

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

const DEMO_EMAIL = "demo@erbrains.io";
const DEMO_PASSWORD = "password123";
const DEMO_NAME = "Jordan Lee";
const DEMO_DEVICE_ID = "FITRING-001";

async function seedProducts() {
    const sql = fs.readFileSync(path.join(__dirname, "seed.sql"), "utf8");
    await pool.query(sql);
}

async function seedDemoUser() {
    const result = await pool.query(
        `
        INSERT INTO users (email, password_hash, name)
        VALUES ($1, $2, $3)
        ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name, password_hash = EXCLUDED.password_hash
        RETURNING id
        `,
        [DEMO_EMAIL, await hashPassword(DEMO_PASSWORD), DEMO_NAME]
    );

    return result.rows[0].id;
}

async function seedDemoDevice(userId) {
    await pool.query(
        `
        INSERT INTO devices (id, user_id, name, status)
        VALUES ($1, $2, $3, 'connected')
        ON CONFLICT (id) DO UPDATE SET status = 'connected', user_id = $2
        `,
        [DEMO_DEVICE_ID, userId, "Demo FitRing"]
    );
}

// Backfills readings every 15 minutes for the last 3 days, so History/summary
// screens have something to render immediately. Re-running is a no-op thanks
// to the (device_id, reading_timestamp) unique constraint.
async function seedHealthReadings(userId) {
    const intervalMs = 15 * 60 * 1000;
    const totalReadings = 96 * 3; // 3 days at 15-minute steps
    const now = Date.now();

    let synced = 0;

    for (let i = totalReadings; i >= 0; i--) {
        const stepInDay = (totalReadings - i) % 96;
        const timestamp = new Date(now - i * intervalMs).toISOString();
        const heartRate = 60 + Math.round(Math.random() * 40);
        const spo2 = 95 + Math.round(Math.random() * 4);
        const steps = stepInDay * 70;

        const result = await pool.query(
            `
            INSERT INTO health_readings (
                device_id, user_id, heart_rate, spo2, steps, reading_timestamp
            )
            VALUES ($1, $2, $3, $4, $5, $6)
            ON CONFLICT (device_id, reading_timestamp) DO NOTHING
            `,
            [DEMO_DEVICE_ID, userId, heartRate, spo2, steps, timestamp]
        );

        if (result.rowCount === 1) {
            synced++;
        }
    }

    return synced;
}

// Creates one completed order directly (bypassing the cart) so /orders has
// history to show. Skipped if the demo user already has an order.
async function seedDemoOrder(userId) {
    const existing = await pool.query(
        `SELECT id FROM orders WHERE user_id = $1 LIMIT 1`,
        [userId]
    );

    if (existing.rows.length > 0) {
        return existing.rows[0].id;
    }

    const products = await pool.query(
        `SELECT id, price FROM products ORDER BY created_at ASC LIMIT 2`
    );

    if (products.rows.length === 0) {
        return null;
    }

    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        const items = products.rows.map((p) => ({
            productId: p.id,
            quantity: 1,
            price: Number(p.price),
        }));

        const totalAmount = items.reduce(
            (sum, item) => sum + item.quantity * item.price,
            0
        );

        const orderRes = await client.query(
            `
            INSERT INTO orders (user_id, total_amount, status)
            VALUES ($1, $2, 'completed')
            RETURNING id
            `,
            [userId, totalAmount]
        );

        const orderId = orderRes.rows[0].id;

        for (const item of items) {
            await client.query(
                `
                INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase)
                VALUES ($1, $2, $3, $4)
                `,
                [orderId, item.productId, item.quantity, item.price]
            );
        }

        await client.query("COMMIT");
        return orderId;
    } catch (err) {
        await client.query("ROLLBACK");
        throw err;
    } finally {
        client.release();
    }
}

async function seed() {
    console.log("Seeding products...");
    await seedProducts();

    console.log("Seeding demo user...");
    const userId = await seedDemoUser();

    console.log("Seeding demo device...");
    await seedDemoDevice(userId);

    console.log("Seeding health readings...");
    const synced = await seedHealthReadings(userId);

    console.log("Seeding a demo order...");
    const orderId = await seedDemoOrder(userId);

    console.log("");
    console.log("Seed complete:");
    console.log(`  demo login  -> email: ${DEMO_EMAIL}  password: ${DEMO_PASSWORD}  name: ${DEMO_NAME}`);
    console.log(`  demo device -> ${DEMO_DEVICE_ID}`);
    console.log(`  readings    -> ${synced} new reading(s) inserted`);
    console.log(`  demo order  -> ${orderId ?? "skipped (no products)"}`);
}

// Only run automatically when invoked as a script (`npm run db:seed`), not
// when required by tests.
if (require.main === module) {
    seed()
        .then(() => pool.end())
        .catch((err) => {
            console.error("Seeding failed:", err);
            process.exit(1);
        });
}

module.exports = {
    seed,
    hashPassword,
    DEMO_EMAIL,
    DEMO_PASSWORD,
    DEMO_NAME,
    DEMO_DEVICE_ID,
};
