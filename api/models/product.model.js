const db = require("../db");

/**
 * Paginated, optionally filtered by a case-insensitive name search.
 * Two queries (page + total count) rather than a window function — the
 * catalog is small and this keeps the SQL readable; a COUNT(*) OVER()
 * would be the next step if the catalog ever grew large enough to matter.
 */
async function findAll({ page = 1, limit = 20, q } = {}) {
    const offset = (page - 1) * limit;
    const where = q ? "WHERE name ILIKE $1" : "";
    const searchParam = q ? [`%${q}%`] : [];

    const dataResult = await db.query(
        `SELECT * FROM products ${where}
         ORDER BY created_at DESC
         LIMIT $${searchParam.length + 1} OFFSET $${searchParam.length + 2}`,
        [...searchParam, limit, offset]
    );

    const countResult = await db.query(
        `SELECT COUNT(*)::INT AS total FROM products ${where}`,
        searchParam
    );

    return { data: dataResult.rows, total: countResult.rows[0].total };
}

async function findById(id) {
    const result = await db.query("SELECT * FROM products WHERE id = $1", [id]);
    return result.rows[0] || null;
}

module.exports = { findAll, findById };
