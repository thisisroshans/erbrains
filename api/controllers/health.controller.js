const healthReadingModel = require("../models/healthReading.model");
const { ensureSelf } = require("../middleware/auth");

async function postReadings(req, res) {
    const { userId, readings } = req.body;

    // ------------------------------------------
    // Validate userId
    // ------------------------------------------
    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    if (!ensureSelf(req, res, userId)) return;

    // ------------------------------------------
    // Validate readings array
    // ------------------------------------------
    if (!Array.isArray(readings) || readings.length === 0) {
        return res.status(400).json({
            error: "readings must be a non-empty array",
        });
    }

    // ------------------------------------------
    // Validate individual readings
    // ------------------------------------------
    for (const reading of readings) {
        if (!reading.deviceId) {
            return res.status(400).json({
                error: "deviceId is required for every reading",
            });
        }

        if (reading.heartRate == null) {
            return res.status(400).json({
                error: "heartRate is required for every reading",
            });
        }

        if (reading.spo2 == null) {
            return res.status(400).json({
                error: "spo2 is required for every reading",
            });
        }

        if (reading.steps == null) {
            return res.status(400).json({
                error: "steps is required for every reading",
            });
        }

        if (!reading.timestamp) {
            return res.status(400).json({
                error: "timestamp is required for every reading",
            });
        }

        // ------------------------------------------
        // Validate timestamp
        // ------------------------------------------
        const timestamp = new Date(reading.timestamp);

        if (Number.isNaN(timestamp.getTime())) {
            return res.status(400).json({
                error: `Invalid timestamp: ${reading.timestamp}`,
            });
        }
    }

    let synced = 0;
    let duplicatesSkipped = 0;

    try {
        // ------------------------------------------
        // Insert each reading
        // ------------------------------------------
        for (const reading of readings) {
            const inserted = await healthReadingModel.insertReading({
                deviceId: reading.deviceId,
                userId,
                heartRate: reading.heartRate,
                spo2: reading.spo2,
                steps: reading.steps,
                timestamp: reading.timestamp,
            });

            if (inserted) {
                synced++;
            } else {
                duplicatesSkipped++;
            }
        }

        return res.status(201).json({
            synced,
            duplicatesSkipped,
        });

    } catch (error) {
        console.error("POST /health/readings error:", error);

        // Invalid user/device foreign key
        if (error.code === "23503") {
            return res.status(400).json({
                error: "Invalid userId or deviceId",
            });
        }

        return res.status(500).json({
            error: "Failed to sync health readings",
        });
    }
}

async function getReadings(req, res) {
    const { userId } = req.query;

    const page = Math.max(
        parseInt(req.query.page, 10) || 1,
        1
    );

    const limit = Math.min(
        Math.max(
            parseInt(req.query.limit, 10) || 50,
            1
        ),
        100
    );

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    if (!ensureSelf(req, res, userId)) return;

    const offset = (page - 1) * limit;

    try {
        const data = await healthReadingModel.findByUser(userId, { limit, offset });

        return res.status(200).json({
            data,
            page,
            limit,
        });

    } catch (err) {
        console.error("Get Readings Error:", err);

        return res.status(500).json({
            error: "Failed to fetch health history",
        });
    }
}

async function getSummary(req, res) {
    const {
        userId,
        period = "daily",
    } = req.query;

    if (!userId) {
        return res.status(400).json({
            error: "userId is required",
        });
    }

    if (!ensureSelf(req, res, userId)) return;

    if (!["daily", "weekly"].includes(period)) {
        return res.status(400).json({
            error: "period must be either daily or weekly",
        });
    }

    try {
        const summary = await healthReadingModel.getSummary(userId, period);
        return res.status(200).json(summary);

    } catch (error) {
        console.error("GET /health/summary error:", error);

        return res.status(500).json({
            error: "Failed to generate summary",
        });
    }
}

module.exports = { postReadings, getReadings, getSummary };
