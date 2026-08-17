const express = require("express");
const cors = require("cors");
const db = require("./db");
const authRoutes = require("./auth.routes");

require("dotenv").config();

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


app.get('/devices', async (req, res) => {
    const { userId } = req.query;
    try {
        const result = await db.query(
            'SELECT * FROM devices WHERE user_id = $1 ORDER BY created_at DESC',
            [userId]
        );
        res.status(200).json(result.rows);
    } catch (err) {
        console.error('Get Devices Error:', err);
        res.status(500).json({ error: 'Failed to fetch devices' });
    }
});

// ==========================================
// HEALTH DATA API
// ==========================================

app.post("/health/readings", async (req, res) => {
    const { userId, readings } = req.body;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    if (!Array.isArray(readings)) {
        return res.status(400).json({
            error: "Invalid readings payload",
        });
    }

    let insertedCount = 0;

    try {
        for (const record of readings) {
            const result = await db.query(
                `
                INSERT INTO health_readings
                    (
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
                    record.deviceId,
                    userId,
                    record.heartRate,
                    record.spo2,
                    record.steps,
                    record.timestamp,
                ]
            );

            if (result.rowCount > 0) {
                insertedCount++;
            }
        }

        return res.status(201).json({
            message: "Synchronization successful",
            totalReceived: readings.length,
            newRecordsStored: insertedCount,
            duplicatesSkipped: readings.length - insertedCount,
        });
    } catch (err) {
        console.error("Sync Error:", err);

        return res.status(500).json({
            error: "Failed to sync health data",
        });
    }
});

app.get('/health/readings', async (req, res) => {
    // Pagination limits the payload to avoid crashing the UI
    const { userId, page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    try {
        const result = await db.query(
            `SELECT * FROM health_readings 
             WHERE user_id = $1 
             ORDER BY reading_timestamp DESC 
             LIMIT $2 OFFSET $3`,
            [userId, limit, offset]
        );
        res.status(200).json({
            data: result.rows,
            page: parseInt(page),
            limit: parseInt(limit)
        });
    } catch (err) {
        console.error('Get Readings Error:', err);
        res.status(500).json({ error: 'Failed to fetch health history' });
    }
});

app.get('/health/summary', async (req, res) => {
    const { userId } = req.query;
    try {
        // Aggregates data by day for the last 7 days for the UI charts
        const result = await db.query(
            `SELECT 
                DATE_TRUNC('day', reading_timestamp) AS date,
                AVG(heart_rate)::INT AS avg_heart_rate,
                AVG(spo2)::INT AS avg_spo2,
                SUM(steps)::INT AS total_steps
             FROM health_readings
             WHERE user_id = $1 AND reading_timestamp >= NOW() - INTERVAL '7 days'
             GROUP BY date
             ORDER BY date ASC`,
            [userId]
        );
        res.status(200).json(result.rows);
    } catch (err) {
        console.error('Summary Error:', err);
        res.status(500).json({ error: 'Failed to generate summary' });
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

app.post('/orders', async (req, res) => {
    const { userId } = req.body;
    
    try {
        await db.query('BEGIN'); // Start Transaction

        // 1. Get cart items & calculate total
        const cartRes = await db.query(
            `SELECT c.product_id, c.quantity, p.price 
             FROM cart_items c JOIN products p ON c.product_id = p.id 
             WHERE c.user_id = $1`, 
            [userId]
        );
        
        if (cartRes.rows.length === 0) {
            await db.query('ROLLBACK');
            return res.status(400).json({ error: 'Cart is empty' });
        }

        const totalAmount = cartRes.rows.reduce((sum, item) => sum + (item.quantity * item.price), 0);

        // 2. Create the Order
        const orderRes = await db.query(
            `INSERT INTO orders (user_id, total_amount, status) VALUES ($1, $2, 'completed') RETURNING id`,
            [userId, totalAmount]
        );
        const orderId = orderRes.rows[0].id;

        // 3. Move items to order_items
        for (const item of cartRes.rows) {
            await db.query(
                `INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase) 
                 VALUES ($1, $2, $3, $4)`,
                [orderId, item.product_id, item.quantity, item.price]
            );
        }

        // 4. Clear the Cart
        await db.query('DELETE FROM cart_items WHERE user_id = $1', [userId]);

        await db.query('COMMIT'); // Commit Transaction
        res.status(201).json({ orderId, totalAmount, status: 'completed' });

    } catch (err) {
        await db.query('ROLLBACK'); // Cancel everything if anything fails
        console.error('Checkout Error:', err);
        res.status(500).json({ error: 'Failed to process order' });
    }
});

app.get('/orders', async (req, res) => {
    const { userId } = req.query;
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

// ==========================================
// START SERVER
// ==========================================

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});