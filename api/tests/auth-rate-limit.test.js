// Separate file so Jest's per-file module isolation gives this test a
// fresh rate-limiter instance, decoupled from auth.test.js's own login
// calls — otherwise the two would share one 15-minute request budget and
// the test order would silently matter.
jest.mock("../db");

const request = require("supertest");
const db = require("../db");
const app = require("../app");

describe("POST /auth/login rate limiting", () => {
    it("allows up to the limit, then rejects further attempts with 429", async () => {
        db.query.mockResolvedValue({
            rows: [{ id: "user-1", email: "a@b.com", name: null, password_hash: "not-a-real-hash" }],
        });

        const attempt = () =>
            request(app).post("/auth/login").send({ email: "a@b.com", password: "wrong" });

        // First 5 attempts are rejected on password (401), not by the
        // limiter — only the 6th should ever see 429.
        for (let i = 0; i < 5; i++) {
            const res = await attempt();
            expect(res.status).toBe(401);
        }

        const limited = await attempt();
        expect(limited.status).toBe(429);
    });
});
