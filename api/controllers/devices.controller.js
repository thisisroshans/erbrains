const deviceModel = require("../models/device.model");
const { ensureSelf } = require("../middleware/auth");

async function registerDevice(req, res) {
    const { deviceId, name, userId } = req.body;

    if (!deviceId || !name || !userId) {
        return res.status(400).json({
            error: "deviceId, name and userId are required",
        });
    }

    if (!ensureSelf(req, res, userId)) return;

    try {
        const device = await deviceModel.upsert({ deviceId, userId, name });
        return res.status(201).json(device);

    } catch (err) {
        req.log?.error({ err }, "Device registration error");

        // Invalid userId foreign key
        if (err.code === "23503") {
            return res.status(400).json({
                error: "Invalid userId",
            });
        }

        return res.status(500).json({
            error: "Failed to register device",
        });
    }
}

async function listDevices(req, res) {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    if (!ensureSelf(req, res, userId)) return;

    try {
        const devices = await deviceModel.findByUser(userId);
        return res.status(200).json(devices);

    } catch (err) {
        req.log?.error({ err }, "Get devices error");

        return res.status(500).json({
            error: "Failed to fetch devices",
        });
    }
}

module.exports = { registerDevice, listDevices };
