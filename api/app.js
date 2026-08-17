const express = require("express");
const cors = require("cors");
const { requireAuth } = require("./middleware/auth");

const authRoutes = require("./routes/auth.routes");
const productsRoutes = require("./routes/products.routes");
const devicesRoutes = require("./routes/devices.routes");
const healthRoutes = require("./routes/health.routes");
const cartRoutes = require("./routes/cart.routes");
const ordersRoutes = require("./routes/orders.routes");

const app = express();

app.use(cors());
app.use(express.json());

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

module.exports = app;
