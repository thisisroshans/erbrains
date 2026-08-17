jest.mock("../db");

const request = require("supertest");
const db = require("../db");
const app = require("../app");
const { authHeader } = require("./helpers/auth");

describe("requireAuth middleware", () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    it("lets GET /products through with no token (public route)", async () => {
        db.query.mockResolvedValueOnce({ rows: [] });

        const res = await request(app).get("/products");

        expect(res.status).toBe(200);
    });

    it("rejects a protected route with no Authorization header", async () => {
        const res = await request(app).get("/cart").query({ userId: "user-1" });

        expect(res.status).toBe(401);
    });

    it("rejects a malformed token", async () => {
        const res = await request(app)
            .get("/cart")
            .query({ userId: "user-1" })
            .set("Authorization", "Bearer not-a-real-token");

        expect(res.status).toBe(401);
    });

    it("rejects a token whose userId doesn't match the requested userId", async () => {
        const res = await request(app)
            .get("/cart")
            .query({ userId: "someone-else" })
            .set("Authorization", authHeader("user-1"));

        expect(res.status).toBe(403);
    });

    it("allows a matching token through to the handler", async () => {
        db.query.mockResolvedValueOnce({ rows: [] });

        const res = await request(app)
            .get("/cart")
            .query({ userId: "user-1" })
            .set("Authorization", authHeader("user-1"));

        expect(res.status).toBe(200);
    });
});
