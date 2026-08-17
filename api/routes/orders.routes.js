const express = require("express");
const controller = require("../controllers/orders.controller");

const router = express.Router();

router.post("/", controller.placeOrder);
router.get("/", controller.listOrders);

module.exports = router;
