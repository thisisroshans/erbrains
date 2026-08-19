const db = require("../db");

/**
 * Converts the user's current cart into an order: validate stock, snapshot
 * prices into order_items, decrement stock, then empty the cart — all
 * inside one transaction so a mid-way failure can't leave a half-charged
 * cart or an oversold product. Throws an Error with statusCode 400 if the
 * cart is empty, 409 if any line item exceeds available stock.
 *
 * `FOR UPDATE OF p` locks only the product rows being checked (not
 * cart_items) for the transaction's duration — two concurrent checkouts
 * racing for the last unit of the same product get serialized instead of
 * both reading "enough stock" and both succeeding.
 */
async function createFromCart(userId) {
    return db.transaction(async (client) => {
        const cartRes = await client.query(
            `
            SELECT
                c.product_id,
                c.quantity,
                p.price,
                p.stock,
                p.name
            FROM cart_items c
            JOIN products p
                ON c.product_id = p.id
            WHERE c.user_id = $1
            FOR UPDATE OF p
            `,
            [userId]
        );

        if (cartRes.rows.length === 0) {
            const error = new Error("Cart is empty");
            error.statusCode = 400;
            throw error;
        }

        const insufficient = cartRes.rows.filter((item) => item.quantity > item.stock);
        if (insufficient.length > 0) {
            const error = new Error(
                `Insufficient stock for: ${insufficient.map((item) => item.name).join(", ")}`
            );
            error.statusCode = 409;
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

            await client.query(
                `UPDATE products SET stock = stock - $1 WHERE id = $2`,
                [item.quantity, item.product_id]
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

/**
 * Cancels an order owned by userId and restores the stock it reserved.
 * Any status except 'cancelled' is cancellable — there's no fulfillment
 * step in this app that would make a completed order un-cancellable, so
 * the only terminal state is 'cancelled' itself. Throws 404 if the order
 * doesn't exist or isn't owned by userId, 409 if already cancelled.
 */
async function cancelOrder(orderId, userId) {
    return db.transaction(async (client) => {
        const orderRes = await client.query(
            `SELECT id, status FROM orders WHERE id = $1 AND user_id = $2 FOR UPDATE`,
            [orderId, userId]
        );

        if (orderRes.rows.length === 0) {
            const error = new Error("Order not found");
            error.statusCode = 404;
            throw error;
        }

        if (orderRes.rows[0].status === "cancelled") {
            const error = new Error("Order is already cancelled");
            error.statusCode = 409;
            throw error;
        }

        const itemsRes = await client.query(
            `SELECT product_id, quantity FROM order_items WHERE order_id = $1`,
            [orderId]
        );

        for (const item of itemsRes.rows) {
            await client.query(
                `UPDATE products SET stock = stock + $1 WHERE id = $2`,
                [item.quantity, item.product_id]
            );
        }

        const updated = await client.query(
            `UPDATE orders SET status = 'cancelled' WHERE id = $1 RETURNING *`,
            [orderId]
        );

        return updated.rows[0];
    });
}

module.exports = { createFromCart, findByUser, cancelOrder };
