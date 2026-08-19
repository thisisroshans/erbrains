const orderModel = require("../models/order.model");
const { ensureSelf } = require("../middleware/auth");

async function placeOrder(req, res) {
    const { userId } = req.body;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    if (!ensureSelf(req, res, userId)) return;

    try {
        const result = await orderModel.createFromCart(userId);
        return res.status(201).json(result);

    } catch (err) {
        req.log?.error({ err }, "Checkout error");

        if (err.statusCode) {
            return res.status(err.statusCode).json({
                error: err.message,
            });
        }

        return res.status(500).json({
            error: "Failed to process order",
        });
    }
}

async function listOrders(req, res) {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    if (!ensureSelf(req, res, userId)) return;

    try {
        const orders = await orderModel.findByUser(userId);
        res.status(200).json(orders);
    } catch (err) {
        req.log?.error({ err }, "Fetch orders error");
        res.status(500).json({ error: 'Failed to fetch orders' });
    }
}

/**
 * Ownership is enforced in the model's own query (scoped to
 * user_id = req.auth.userId), not a separate check here — same pattern as
 * cart.model.js's updateQuantity/deleteItem.
 */
async function cancelOrder(req, res) {
    try {
        const order = await orderModel.cancelOrder(req.params.id, req.auth.userId);
        return res.status(200).json(order);
    } catch (err) {
        req.log?.error({ err }, "Cancel order error");

        if (err.statusCode) {
            return res.status(err.statusCode).json({ error: err.message });
        }

        return res.status(500).json({ error: "Failed to cancel order" });
    }
}

module.exports = { placeOrder, listOrders, cancelOrder };
