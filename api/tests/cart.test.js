jest.mock("../db");

const request = require("supertest");
const db = require("../db");
const app = require("../app");

describe("POST /cart", () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    it("rejects a request missing required fields", async () => {
        const res = await request(app)
            .post("/cart")
            .send({ userId: "user-1", productId: "prod-1" });

        expect(res.status).toBe(400);
    });

    it("rejects a non-positive quantity", async () => {
        const res = await request(app)
            .post("/cart")
            .send({ userId: "user-1", productId: "prod-1", quantity: 0 });

        expect(res.status).toBe(400);
    });

    it("rejects a non-integer quantity", async () => {
        const res = await request(app)
            .post("/cart")
            .send({ userId: "user-1", productId: "prod-1", quantity: 1.5 });

        expect(res.status).toBe(400);
    });

    it("merges quantity into the existing line item via ON CONFLICT", async () => {
        db.query.mockResolvedValueOnce({
            rows: [{ id: "cart-1", user_id: "user-1", product_id: "prod-1", quantity: 3 }],
        });

        const res = await request(app)
            .post("/cart")
            .send({ userId: "user-1", productId: "prod-1", quantity: 2 });

        expect(res.status).toBe(201);
        expect(res.body.quantity).toBe(3);

        const [sql] = db.query.mock.calls[0];
        expect(sql).toMatch(/ON CONFLICT \(user_id, product_id\)/);
    });
});

describe("GET /cart", () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    it("rejects a request with no userId", async () => {
        const res = await request(app).get("/cart");
        expect(res.status).toBe(400);
    });

    it("sums subtotals (returned as numeric strings by pg) into a numeric total", async () => {
        db.query.mockResolvedValueOnce({
            rows: [
                { cart_item_id: "1", quantity: 2, product_id: "p1", name: "A", price: "9.99", subtotal: "19.98" },
                { cart_item_id: "2", quantity: 1, product_id: "p2", name: "B", price: "24.99", subtotal: "24.99" },
            ],
        });

        const res = await request(app).get("/cart").query({ userId: "user-1" });

        expect(res.status).toBe(200);
        expect(res.body.items).toHaveLength(2);
        expect(res.body.totalAmount).toBeCloseTo(44.97, 2);
    });
});
