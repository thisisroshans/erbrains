jest.mock("../db");

const request = require("supertest");
const db = require("../db");
const app = require("../app");
const { authHeader } = require("./helpers/auth");

describe("POST /health/readings", () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    it("rejects a request with no userId", async () => {
        const res = await request(app)
            .post("/health/readings")
            .set("Authorization", authHeader("user-1"))
            .send({ readings: [] });

        expect(res.status).toBe(400);
    });

    it("rejects a request with an empty readings array", async () => {
        const res = await request(app)
            .post("/health/readings")
            .set("Authorization", authHeader("user-1"))
            .send({ userId: "user-1", readings: [] });

        expect(res.status).toBe(400);
    });

    it("rejects a reading missing a required field", async () => {
        const res = await request(app)
            .post("/health/readings")
            .set("Authorization", authHeader("user-1"))
            .send({
                userId: "user-1",
                readings: [
                    {
                        deviceId: "FITRING-001",
                        heartRate: 78,
                        spo2: 98,
                        // steps missing
                        timestamp: "2026-08-17T10:30:00Z",
                    },
                ],
            });

        expect(res.status).toBe(400);
    });

    it("rejects a reading with an invalid timestamp", async () => {
        const res = await request(app)
            .post("/health/readings")
            .set("Authorization", authHeader("user-1"))
            .send({
                userId: "user-1",
                readings: [
                    {
                        deviceId: "FITRING-001",
                        heartRate: 78,
                        spo2: 98,
                        steps: 100,
                        timestamp: "not-a-date",
                    },
                ],
            });

        expect(res.status).toBe(400);
    });

    it("rejects a userId that doesn't match the authenticated caller", async () => {
        const res = await request(app)
            .post("/health/readings")
            .set("Authorization", authHeader("user-1"))
            .send({
                userId: "someone-else",
                readings: [
                    {
                        deviceId: "FITRING-001",
                        heartRate: 78,
                        spo2: 98,
                        steps: 100,
                        timestamp: "2026-08-17T10:30:00Z",
                    },
                ],
            });

        expect(res.status).toBe(403);
    });

    it("syncs new readings and skips duplicates already stored (ON CONFLICT DO NOTHING)", async () => {
        // First reading is new (row returned), second is a duplicate (no row returned)
        db.query
            .mockResolvedValueOnce({ rowCount: 1, rows: [{ id: "r1" }] })
            .mockResolvedValueOnce({ rowCount: 0, rows: [] });

        const res = await request(app)
            .post("/health/readings")
            .set("Authorization", authHeader("user-1"))
            .send({
                userId: "user-1",
                readings: [
                    {
                        deviceId: "FITRING-001",
                        heartRate: 78,
                        spo2: 98,
                        steps: 6420,
                        timestamp: "2026-08-17T10:30:00Z",
                    },
                    {
                        deviceId: "FITRING-001",
                        heartRate: 78,
                        spo2: 98,
                        steps: 6420,
                        timestamp: "2026-08-17T10:30:00Z",
                    },
                ],
            });

        expect(res.status).toBe(201);
        expect(res.body).toEqual({
            synced: 1,
            duplicatesSkipped: 1,
            results: [
                { deviceId: "FITRING-001", timestamp: "2026-08-17T10:30:00Z", status: "synced" },
                { deviceId: "FITRING-001", timestamp: "2026-08-17T10:30:00Z", status: "duplicate" },
            ],
        });
        expect(db.query).toHaveBeenCalledTimes(2);
    });

    it("maps a foreign key violation to a 400", async () => {
        const fkError = new Error("violates foreign key constraint");
        fkError.code = "23503";
        db.query.mockRejectedValueOnce(fkError);

        const res = await request(app)
            .post("/health/readings")
            .set("Authorization", authHeader("unknown-user"))
            .send({
                userId: "unknown-user",
                readings: [
                    {
                        deviceId: "FITRING-001",
                        heartRate: 78,
                        spo2: 98,
                        steps: 6420,
                        timestamp: "2026-08-17T10:30:00Z",
                    },
                ],
            });

        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/Invalid/);
    });
});

describe("GET /health/readings", () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    it("rejects a request with no userId", async () => {
        const res = await request(app)
            .get("/health/readings")
            .set("Authorization", authHeader("user-1"));

        expect(res.status).toBe(400);
    });

    it("clamps limit to a maximum of 100 so the UI can't be asked to load unbounded records", async () => {
        db.query.mockResolvedValueOnce({ rows: [] });

        const res = await request(app)
            .get("/health/readings")
            .set("Authorization", authHeader("user-1"))
            .query({ userId: "user-1", limit: "5000" });

        expect(res.status).toBe(200);
        expect(res.body.limit).toBe(100);

        const [, params] = db.query.mock.calls[0];
        expect(params[1]).toBe(100);
    });
});
