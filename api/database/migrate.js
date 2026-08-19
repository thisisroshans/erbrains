require("dotenv").config();

const fs = require("fs");
const path = require("path");
const { Pool } = require("pg");
const logger = require("../logger");

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

const MIGRATIONS_DIR = path.join(__dirname, "migrations");

async function ensureMigrationsTable() {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS schema_migrations (
            id         VARCHAR(255) PRIMARY KEY,
            applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
    `);
}

async function appliedMigrations() {
    const result = await pool.query("SELECT id FROM schema_migrations");
    return new Set(result.rows.map((row) => row.id));
}

/**
 * Applies every migrations/*.sql file not already recorded in
 * schema_migrations, in filename order (hence the numbered prefixes).
 * Each file runs and gets recorded in the same query round-trip it was
 * read in — not wrapped in one giant transaction across all pending
 * files, so a later migration's own DDL failure doesn't roll back ones
 * that already succeeded ahead of it.
 */
async function runMigrations() {
    if (!fs.existsSync(MIGRATIONS_DIR)) return;

    const files = fs.readdirSync(MIGRATIONS_DIR).filter((f) => f.endsWith(".sql")).sort();
    const applied = await appliedMigrations();

    for (const file of files) {
        if (applied.has(file)) continue;

        const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), "utf8");
        logger.info(`Applying migration ${file}...`);
        await pool.query(sql);
        await pool.query("INSERT INTO schema_migrations (id) VALUES ($1)", [file]);
        logger.info(`Applied ${file}`);
    }
}

async function main() {
    // schema.sql is the original idempotent baseline — still applied in
    // full every run (see docs/DATABASE.md for why). Everything since is a
    // tracked migration instead of growing schema.sql's guarded-ALTER tail
    // indefinitely.
    const schemaSql = fs.readFileSync(path.join(__dirname, "schema.sql"), "utf8");
    await pool.query(schemaSql);
    logger.info("Base schema applied.");

    await ensureMigrationsTable();
    await runMigrations();

    logger.info("Migrations complete.");
    await pool.end();
}

main().catch((err) => {
    logger.error({ err }, "Migration failed");
    process.exit(1);
});
