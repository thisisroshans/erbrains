jest.mock("../db");

const request = require("supertest");
const db = require("../db");
const app = require("../app");

describe("GET /products", () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    it("returns a paginated envelope, not a bare array", async () => {
        db.query
            .mockResolvedValueOnce({ rows: [{ id: "p1", name: "Widget" }] })
            .mockResolvedValueOnce({ rows: [{ total: 1 }] });

        const res = await request(app).get("/products");

        expect(res.status).toBe(200);
        expect(res.body).toEqual({
            data: [{ id: "p1", name: "Widget" }],
            page: 1,
            limit: 20,
            total: 1,
        });
    });

    it("clamps limit to a maximum of 100", async () => {
        db.query.mockResolvedValueOnce({ rows: [] }).mockResolvedValueOnce({ rows: [{ total: 0 }] });

        const res = await request(app).get("/products").query({ limit: "5000" });

        expect(res.body.limit).toBe(100);
    });

    it("passes a search term through as a case-insensitive filter", async () => {
        db.query.mockResolvedValueOnce({ rows: [] }).mockResolvedValueOnce({ rows: [{ total: 0 }] });

        await request(app).get("/products").query({ q: "ring" });

        const [dataSql, dataParams] = db.query.mock.calls[0];
        expect(dataSql).toMatch(/ILIKE/);
        expect(dataParams).toContain("%ring%");
    });
});

describe("GET /products/:id", () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    it("returns 404 for an unknown product", async () => {
        db.query.mockResolvedValueOnce({ rows: [] });

        const res = await request(app).get("/products/does-not-exist");

        expect(res.status).toBe(404);
    });

    it("returns the product when found", async () => {
        db.query.mockResolvedValueOnce({ rows: [{ id: "p1", name: "Widget" }] });

        const res = await request(app).get("/products/p1");

        expect(res.status).toBe(200);
        expect(res.body).toEqual({ id: "p1", name: "Widget" });
    });
});
