const express = require("express");
const controller = require("../controllers/orders.controller");

const router = express.Router();

router.post("/", controller.placeOrder);
router.get("/", controller.listOrders);
router.post("/:id/cancel", controller.cancelOrder);

module.exports = router;
