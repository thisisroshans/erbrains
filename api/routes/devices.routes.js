const express = require("express");
const controller = require("../controllers/devices.controller");

const router = express.Router();

router.post("/", controller.registerDevice);
router.get("/", controller.listDevices);

module.exports = router;
