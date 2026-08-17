const db = require("../db");

/**
 * Converts the user's current cart into an order: snapshot prices into
 * order_items, then empty the cart — all inside one transaction so a
 * mid-way failure can't leave a half-charged cart. Throws an Error with
 * statusCode 400 if the cart is empty.
 */
async function createFromCart(userId) {
    return db.transaction(async (client) => {
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

        const totalAmount = cartRes.rows.reduce(
            (sum, item) => sum + Number(item.quantity) * Number(item.price),
            0
        );

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
                [orderId, item.product_id, item.quantity, item.price]
            );
        }

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
}

async function findByUser(userId) {
    const result = await db.query(
        `
        SELECT
            o.*,
            (
                SELECT COUNT(*)::INT
                FROM order_items oi
                WHERE oi.order_id = o.id
            ) AS item_count
        FROM orders o
        WHERE o.user_id = $1
        ORDER BY o.created_at DESC
        `,
        [userId]
    );
    return result.rows;
}

module.exports = { createFromCart, findByUser };
