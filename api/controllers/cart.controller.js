const cartModel = require("../models/cart.model");
const { ensureSelf } = require("../middleware/auth");

async function addItem(req, res) {
    const { userId, productId, quantity } = req.body;

    if (!userId || !productId || quantity == null) {
        return res.status(400).json({
            error: "userId, productId and quantity are required",
        });
    }

    if (!ensureSelf(req, res, userId)) return;

    if (!Number.isInteger(quantity) || quantity <= 0) {
        return res.status(400).json({
            error: "quantity must be a positive integer",
        });
    }

    try {
        const item = await cartModel.upsertItem({ userId, productId, quantity });
        res.status(201).json(item);
    } catch (err) {
        res.status(500).json({ error: 'Failed to update cart' });
    }
}

async function getCart(req, res) {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    if (!ensureSelf(req, res, userId)) return;

    try {
        const items = await cartModel.findByUser(userId);
        const totalAmount = items.reduce((sum, item) => sum + parseFloat(item.subtotal), 0);
        res.status(200).json({ items, totalAmount });
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch cart' });
    }
}

// Sets a line item to an exact quantity — the counterpart to addItem's
// increment-only upsert. Ownership is enforced by scoping the update to
// the authenticated caller's user_id, not just the cart_items.id.
async function updateItem(req, res) {
    const { quantity } = req.body;

    if (!Number.isInteger(quantity) || quantity <= 0) {
        return res.status(400).json({
            error: "quantity must be a positive integer",
        });
    }

    try {
        const item = await cartModel.updateQuantity({
            id: req.params.id,
            userId: req.auth.userId,
            quantity,
        });

        if (!item) {
            return res.status(404).json({ error: 'Cart item not found' });
        }

        res.status(200).json(item);
    } catch (err) {
        res.status(500).json({ error: 'Failed to update cart item' });
    }
}

async function removeItem(req, res) {
    try {
        const deleted = await cartModel.deleteItem({
            id: req.params.id,
            userId: req.auth.userId,
        });

        if (!deleted) {
            return res.status(404).json({ error: 'Cart item not found' });
        }

        res.status(204).send();
    } catch (err) {
        res.status(500).json({ error: 'Failed to remove cart item' });
    }
}

module.exports = { addItem, getCart, updateItem, removeItem };
