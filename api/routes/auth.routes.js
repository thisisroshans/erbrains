const express = require("express");
const authController = require("../controllers/auth.controller");
const { requireAuth } = require("../middleware/auth");
const { loginLimiter } = require("../middleware/rateLimit");

const router = express.Router();

router.post("/login", loginLimiter, authController.login);
router.post("/logout", requireAuth, authController.logout);

module.exports = router;
