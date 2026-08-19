// Tests never depend on a real .env being present — CI won't have one.
// Only sets a fallback if the environment (a real .env, or CI secrets)
// hasn't already provided one.
process.env.JWT_SECRET = process.env.JWT_SECRET || "test-only-secret-not-for-production";

// pino-http logs every request by default (see app.js) — useful in dev,
// pure noise in a test run where the assertions already say what happened.
process.env.LOG_LEVEL = process.env.LOG_LEVEL || "silent";
