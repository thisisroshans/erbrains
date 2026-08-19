const productModel = require("../models/product.model");

async function listProducts(req, res) {
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 20, 1), 100);
    const q = req.query.q ? String(req.query.q).trim() : undefined;

    try {
        const { data, total } = await productModel.findAll({ page, limit, q });
        res.status(200).json({ data, page, limit, total });
    } catch (err) {
        req.log?.error({ err }, "List products error");
        res.status(500).json({ error: 'Failed to fetch products' });
    }
}

async function getProduct(req, res) {
    try {
        const product = await productModel.findById(req.params.id);
        if (!product) return res.status(404).json({ error: 'Product not found' });
        res.status(200).json(product);
    } catch (err) {
        req.log?.error({ err }, "Get product error");
        res.status(500).json({ error: 'Failed to fetch product details' });
    }
}

module.exports = { listProducts, getProduct };
