const express = require("express");
const cors = require("cors");
const db = require("./db");
const authRoutes = require("./auth.routes");

const app = express();

app.use(cors());
app.use(express.json());

// ==========================================
// AUTH API
// ==========================================
app.use("/auth", authRoutes);

// ==========================================
// DEVICES API
// ==========================================

app.post("/devices", async (req, res) => {
    const { deviceId, name, userId } = req.body;

    if (!deviceId || !name || !userId) {
        return res.status(400).json({
            error: "deviceId, name and userId are required",
        });
    }

    try {
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

        return res.status(201).json(result.rows[0]);

    } catch (err) {
        console.error("Device Registration Error:", err);

        // Invalid userId foreign key
        if (err.code === "23503") {
            return res.status(400).json({
                error: "Invalid userId",
            });
        }

        return res.status(500).json({
            error: "Failed to register device",
        });
    }
});


app.get("/devices", async (req, res) => {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    try {
        const result = await db.query(
            `
            SELECT *
            FROM devices
            WHERE user_id = $1
            ORDER BY created_at DESC
            `,
            [userId]
        );

        return res.status(200).json(result.rows);

    } catch (err) {
        console.error("Get Devices Error:", err);

        return res.status(500).json({
            error: "Failed to fetch devices",
        });
    }
});

// ==========================================
// HEALTH DATA API
// ==========================================
app.post("/health/readings", async (req, res) => {
    const { userId, readings } = req.body;

    // ------------------------------------------
    // Validate userId
    // ------------------------------------------
    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    // ------------------------------------------
    // Validate readings array
    // ------------------------------------------
    if (!Array.isArray(readings) || readings.length === 0) {
        return res.status(400).json({
            error: "readings must be a non-empty array",
        });
    }

    // ------------------------------------------
    // Validate individual readings
    // ------------------------------------------
    for (const reading of readings) {
        if (!reading.deviceId) {
            return res.status(400).json({
                error: "deviceId is required for every reading",
            });
        }

        if (reading.heartRate == null) {
            return res.status(400).json({
                error: "heartRate is required for every reading",
            });
        }

        if (reading.spo2 == null) {
            return res.status(400).json({
                error: "spo2 is required for every reading",
            });
        }

        if (reading.steps == null) {
            return res.status(400).json({
                error: "steps is required for every reading",
            });
        }

        if (!reading.timestamp) {
            return res.status(400).json({
                error: "timestamp is required for every reading",
            });
        }

        // ------------------------------------------
        // Validate timestamp
        // ------------------------------------------
        const timestamp = new Date(reading.timestamp);

        if (Number.isNaN(timestamp.getTime())) {
            return res.status(400).json({
                error: `Invalid timestamp: ${reading.timestamp}`,
            });
        }
    }

    let synced = 0;
    let duplicatesSkipped = 0;

    try {
        // ------------------------------------------
        // Insert each reading
        // ------------------------------------------
        for (const reading of readings) {
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
                [
                    reading.deviceId,
                    userId,
                    reading.heartRate,
                    reading.spo2,
                    reading.steps,
                    reading.timestamp,
                ]
            );

            if (result.rowCount === 1) {
                synced++;
            } else {
                duplicatesSkipped++;
            }
        }

        return res.status(201).json({
            synced,
            duplicatesSkipped,
        });

    } catch (error) {
        console.error("POST /health/readings error:", error);

        // Invalid user/device foreign key
        if (error.code === "23503") {
            return res.status(400).json({
                error: "Invalid userId or deviceId",
            });
        }

        return res.status(500).json({
            error: "Failed to sync health readings",
        });
    }
});

app.get("/health/readings", async (req, res) => {
    const { userId } = req.query;

    const page = Math.max(
        parseInt(req.query.page, 10) || 1,
        1
    );

    const limit = Math.min(
        Math.max(
            parseInt(req.query.limit, 10) || 50,
            1
        ),
        100
    );

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    const offset = (page - 1) * limit;

    try {
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

        return res.status(200).json({
            data: result.rows,
            page,
            limit,
        });

    } catch (err) {
        console.error("Get Readings Error:", err);

        return res.status(500).json({
            error: "Failed to fetch health history",
        });
    }
});

app.get("/health/summary", async (req, res) => {
    const {
        userId,
        period = "daily",
    } = req.query;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    if (!["daily", "weekly"].includes(period)) {
        return res.status(400).json({
            error: "period must be either daily or weekly",
        });
    }

    try {
        const truncation =
            period === "weekly"
                ? "week"
                : "day";

        const result = await db.query(
            `
            SELECT
                DATE_TRUNC('${truncation}', reading_timestamp) AS period_date,
                AVG(heart_rate)::INT AS avg_heart_rate,
                MIN(heart_rate) AS min_heart_rate,
                MAX(heart_rate) AS max_heart_rate,
                AVG(spo2)::INT AS avg_spo2,
                MAX(steps) AS total_steps
            FROM health_readings
            WHERE user_id = $1
              AND reading_timestamp >= NOW() - INTERVAL '7 days'
            GROUP BY period_date
            ORDER BY period_date ASC
            `,
            [userId]
        );

        return res.status(200).json(result.rows);

    } catch (error) {
        console.error("GET /health/summary error:", error);

        return res.status(500).json({
            error: "Failed to generate summary",
        });
    }
});

// ==========================================
// SHOPPING API
// ==========================================

app.get('/products', async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM products ORDER BY created_at DESC');
        res.status(200).json(result.rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch products' });
    }
});

app.get('/products/:id', async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM products WHERE id = $1', [req.params.id]);
        if (result.rows.length === 0) return res.status(404).json({ error: 'Product not found' });
        res.status(200).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch product details' });
    }
});

app.post('/cart', async (req, res) => {
    const { userId, productId, quantity } = req.body;

    if (!userId || !productId || quantity == null) {
        return res.status(400).json({
            error: "userId, productId and quantity are required",
        });
    }

    if (!Number.isInteger(quantity) || quantity <= 0) {
        return res.status(400).json({
            error: "quantity must be a positive integer",
        });
    }

    try {
        const result = await db.query(
            `INSERT INTO cart_items (user_id, product_id, quantity)
             VALUES ($1, $2, $3)
             ON CONFLICT (user_id, product_id)
             DO UPDATE SET quantity = cart_items.quantity + EXCLUDED.quantity
             RETURNING *`,
            [userId, productId, quantity]
        );
        res.status(201).json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Failed to update cart' });
    }
});

app.get('/cart', async (req, res) => {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    try {
        const result = await db.query(
            `SELECT c.id AS cart_item_id, c.quantity, p.id AS product_id, p.name, p.price,
             (c.quantity * p.price) AS subtotal
             FROM cart_items c
             JOIN products p ON c.product_id = p.id
             WHERE c.user_id = $1`,
            [userId]
        );

        const totalAmount = result.rows.reduce((sum, item) => sum + parseFloat(item.subtotal), 0);
        res.status(200).json({ items: result.rows, totalAmount });
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch cart' });
    }
});

app.post("/orders", async (req, res) => {
    const { userId } = req.body;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    try {
        const result = await db.transaction(async (client) => {

            // 1. Get cart items
            const cartRes = await client.query(
                `
                SELECT
                    c.product_id,
                    c.quantity,
                    p.price
                FROM cart_items c
                JOIN products p
                    ON c.product_id = p.id
                WHERE c.user_id = $1
                `,
                [userId]
            );

            if (cartRes.rows.length === 0) {
                const error = new Error("Cart is empty");
                error.statusCode = 400;
                throw error;
            }

            // 2. Calculate total
            const totalAmount = cartRes.rows.reduce(
                (sum, item) =>
                    sum +
                    Number(item.quantity) *
                    Number(item.price),
                0
            );

            // 3. Create order
            const orderRes = await client.query(
                `
                INSERT INTO orders (
                    user_id,
                    total_amount,
                    status
                )
                VALUES ($1, $2, 'completed')
                RETURNING id
                `,
                [userId, totalAmount]
            );

            const orderId = orderRes.rows[0].id;

            // 4. Create order items
            for (const item of cartRes.rows) {
                await client.query(
                    `
                    INSERT INTO order_items (
                        order_id,
                        product_id,
                        quantity,
                        price_at_purchase
                    )
                    VALUES ($1, $2, $3, $4)
                    `,
                    [
                        orderId,
                        item.product_id,
                        item.quantity,
                        item.price,
                    ]
                );
            }

            // 5. Clear cart
            await client.query(
                `
                DELETE FROM cart_items
                WHERE user_id = $1
                `,
                [userId]
            );

            return {
                orderId,
                totalAmount,
                status: "completed",
            };
        });

        return res.status(201).json(result);

    } catch (err) {
        console.error("Checkout Error:", err);

        if (err.statusCode === 400) {
            return res.status(400).json({
                error: err.message,
            });
        }

        return res.status(500).json({
            error: "Failed to process order",
        });
    }
});

app.get('/orders', async (req, res) => {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    try {
        const result = await db.query(
            `SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC`,
            [userId]
        );
        res.status(200).json(result.rows);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch orders' });
    }
});

module.exports = app;
