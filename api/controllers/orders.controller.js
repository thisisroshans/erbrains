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
        console.error("Checkout Error:", err);

        if (err.statusCode === 400) {
            return res.status(400).json({
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
        res.status(500).json({ error: 'Failed to fetch orders' });
    }
}

module.exports = { placeOrder, listOrders };
