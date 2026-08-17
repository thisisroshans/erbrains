const db = require("../db");

async function findAll() {
    const result = await db.query("SELECT * FROM products ORDER BY created_at DESC");
    return result.rows;
}

async function findById(id) {
    const result = await db.query("SELECT * FROM products WHERE id = $1", [id]);
    return result.rows[0] || null;
}

module.exports = { findAll, findById };
