const pino = require("pino");

// One shared logger: pino-http (see app.js) attaches a request-scoped
// child of this to req.log for anything happening inside a request;
// standalone scripts (database/migrate.js, database/seed.js) import this
// directly. Structured JSON output — replaces the ad hoc console.error
// calls that used to be scattered across every controller's catch block.
module.exports = pino({
    level: process.env.LOG_LEVEL || "info",
});
