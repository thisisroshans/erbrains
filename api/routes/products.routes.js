const express = require("express");
const controller = require("../controllers/products.controller");

const router = express.Router();

router.get("/", controller.listProducts);
router.get("/:id", controller.getProduct);

module.exports = router;
