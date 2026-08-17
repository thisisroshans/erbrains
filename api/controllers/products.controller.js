const productModel = require("../models/product.model");

async function listProducts(req, res) {
    try {
        const products = await productModel.findAll();
        res.status(200).json(products);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch products' });
    }
}

async function getProduct(req, res) {
    try {
        const product = await productModel.findById(req.params.id);
        if (!product) return res.status(404).json({ error: 'Product not found' });
        res.status(200).json(product);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch product details' });
    }
}

module.exports = { listProducts, getProduct };
