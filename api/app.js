const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const pinoHttp = require("pino-http");
const swaggerUi = require("swagger-ui-express");

const { requireAuth } = require("./middleware/auth");
const logger = require("./logger");
const openapiSpec = require("./openapi");

const authRoutes = require("./routes/auth.routes");
const productsRoutes = require("./routes/products.routes");
const devicesRoutes = require("./routes/devices.routes");
const healthRoutes = require("./routes/health.routes");
const cartRoutes = require("./routes/cart.routes");
const ordersRoutes = require("./routes/orders.routes");

const app = express();

app.use(helmet());
app.use(
    cors({
        // Unset -> wide open, matching local dev against the emulator/
        // simulator with no fixed origin. Set CORS_ORIGIN (comma-separated)
        // anywhere that needs to lock this down.
        origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(",") : true,
    })
);
app.use(express.json());
app.use(pinoHttp({ logger, autoLogging: { ignore: (req) => req.url === "/healthz" } }));

// Ops liveness probe — deliberately outside the app's own /health/* data
// routes (a different top-level path, no collision) and not behind auth,
// since a load balancer/orchestrator checking it has no token.
app.get("/healthz", (req, res) => res.status(200).json({ status: "ok" }));

app.use("/docs", swaggerUi.serve, swaggerUi.setup(openapiSpec));

// ==========================================
// PUBLIC ROUTES
// ==========================================
app.use("/auth", authRoutes);
app.use("/products", productsRoutes);

// ==========================================
// PROTECTED ROUTES — every route below requires a valid bearer token,
// verified and scoped to its userId by requireAuth (middleware/auth.js).
// ==========================================
app.use("/devices", requireAuth, devicesRoutes);
app.use("/health", requireAuth, healthRoutes);
app.use("/cart", requireAuth, cartRoutes);
app.use("/orders", requireAuth, ordersRoutes);

app.use((req, res) => {
    res.status(404).json({ error: "Not found" });
});

// Safety net below every controller's own try/catch — catches anything a
// controller missed (a thrown error in middleware itself, a bug in a
// handler with no try/catch) so a raw stack trace never reaches a client.
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
    req.log?.error({ err }, "Unhandled error");
    res.status(500).json({ error: "Internal server error" });
});

module.exports = app;
