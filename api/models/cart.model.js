const db = require("../db");

async function upsertItem({ userId, productId, quantity }) {
    const result = await db.query(
        `INSERT INTO cart_items (user_id, product_id, quantity)
         VALUES ($1, $2, $3)
         ON CONFLICT (user_id, product_id)
         DO UPDATE SET quantity = cart_items.quantity + EXCLUDED.quantity
         RETURNING *`,
        [userId, productId, quantity]
    );
    return result.rows[0];
}

async function findByUser(userId) {
    const result = await db.query(
        `SELECT c.id AS cart_item_id, c.quantity, p.id AS product_id, p.name, p.price, p.image_url,
         (c.quantity * p.price) AS subtotal
         FROM cart_items c
         JOIN products p ON c.product_id = p.id
         WHERE c.user_id = $1`,
        [userId]
    );
    return result.rows;
}

async function updateQuantity({ id, userId, quantity }) {
    const result = await db.query(
        `UPDATE cart_items
         SET quantity = $1
         WHERE id = $2 AND user_id = $3
         RETURNING *`,
        [quantity, id, userId]
    );
    return result.rows[0] || null;
}

async function deleteItem({ id, userId }) {
    const result = await db.query(
        `DELETE FROM cart_items
         WHERE id = $1 AND user_id = $2
         RETURNING id`,
        [id, userId]
    );
    return result.rows.length > 0;
}

module.exports = { upsertItem, findByUser, updateQuantity, deleteItem };
