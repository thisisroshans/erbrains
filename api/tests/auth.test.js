jest.mock("../db");

const request = require("supertest");
const db = require("../db");
const app = require("../app");
const { hashPassword } = require("../utils/password");
const { verifyToken } = require("../utils/jwt");

describe("POST /auth/login", () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    it("creates a new user on first login and returns a valid signed token", async () => {
        db.query
            .mockResolvedValueOnce({ rows: [] }) // findByEmail: no existing user
            .mockResolvedValueOnce({
                rows: [{ id: "user-1", email: "new@example.com", name: "New User" }],
            }); // create

        const res = await request(app)
            .post("/auth/login")
            .send({ email: "new@example.com", password: "hunter2", name: "New User" });

        expect(res.status).toBe(200);
        expect(res.body.user).toEqual({ id: "user-1", email: "new@example.com", name: "New User" });

        const payload = verifyToken(res.body.token);
        expect(payload).toEqual({ userId: "user-1", email: "new@example.com" });
    });

    it("logs in an existing user with the correct password", async () => {
        const realHash = await hashPassword("correct-password");
        db.query.mockResolvedValueOnce({
            rows: [{ id: "user-1", email: "existing@example.com", name: "Existing", password_hash: realHash }],
        });

        const res = await request(app)
            .post("/auth/login")
            .send({ email: "existing@example.com", password: "correct-password" });

        expect(res.status).toBe(200);
        expect(verifyToken(res.body.token)).toEqual({ userId: "user-1", email: "existing@example.com" });
    });

    it("rejects an existing user with the wrong password", async () => {
        const realHash = await hashPassword("correct-password");
        db.query.mockResolvedValueOnce({
            rows: [{ id: "user-1", email: "existing@example.com", name: "Existing", password_hash: realHash }],
        });

        const res = await request(app)
            .post("/auth/login")
            .send({ email: "existing@example.com", password: "wrong-password" });

        expect(res.status).toBe(401);
    });

    it("rejects a request with no email or password", async () => {
        const res = await request(app).post("/auth/login").send({ email: "only-email@example.com" });
        expect(res.status).toBe(400);
    });
});

describe("POST /auth/logout", () => {
    it("requires a valid token", async () => {
        const res = await request(app).post("/auth/logout");
        expect(res.status).toBe(401);
    });

    it("acknowledges logout for an authenticated caller", async () => {
        const { authHeader } = require("./helpers/auth");
        const res = await request(app).post("/auth/logout").set("Authorization", authHeader("user-1"));
        expect(res.status).toBe(200);
        expect(res.body).toEqual({ success: true });
    });
});

describe("JWT verification (utils/jwt.js)", () => {
    const { signToken } = require("../utils/jwt");
    const jwt = require("jsonwebtoken");

    it("round-trips a valid token", () => {
        const token = signToken({ userId: "user-1", email: "a@b.com" });
        expect(verifyToken(token)).toEqual({ userId: "user-1", email: "a@b.com" });
    });

    it("rejects an expired token", () => {
        const expired = jwt.sign({ userId: "user-1", email: "a@b.com" }, process.env.JWT_SECRET, {
            expiresIn: "-1s",
        });
        expect(verifyToken(expired)).toBeNull();
    });

    it("rejects a token signed with a different secret (tampered/forged)", () => {
        const forged = jwt.sign({ userId: "user-1", email: "a@b.com" }, "wrong-secret", { expiresIn: "1h" });
        expect(verifyToken(forged)).toBeNull();
    });

    it("rejects a well-formed but garbage token", () => {
        expect(verifyToken("not.a.jwt")).toBeNull();
    });
});
