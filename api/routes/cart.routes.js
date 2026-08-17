const express = require("express");
const controller = require("../controllers/cart.controller");

const router = express.Router();

router.post("/", controller.addItem);
router.get("/", controller.getCart);
router.patch("/:id", controller.updateItem);
router.delete("/:id", controller.removeItem);

module.exports = router;
