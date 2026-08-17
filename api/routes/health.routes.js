const express = require("express");
const controller = require("../controllers/health.controller");

const router = express.Router();

router.post("/readings", controller.postReadings);
router.get("/readings", controller.getReadings);
router.get("/summary", controller.getSummary);

module.exports = router;
