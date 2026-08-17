jest.mock("../db");

const request = require("supertest");
const db = require("../db");
const app = require("../app");
const { authHeader } = require("./helpers/auth");

function useTransaction(clientQueryImpl) {
    const clientQuery = jest.fn(clientQueryImpl);

    db.transaction.mockImplementation(async (callback) => {
        return callback({ query: clientQuery });
    });

    return clientQuery;
}

describe("POST /orders", () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    it("rejects a request with no userId", async () => {
        const res = await request(app)
            .post("/orders")
            .set("Authorization", authHeader("user-1"))
            .send({});

        expect(res.status).toBe(400);
        expect(db.transaction).not.toHaveBeenCalled();
    });

    it("rejects a userId that doesn't match the authenticated caller", async () => {
        const res = await request(app)
            .post("/orders")
            .set("Authorization", authHeader("user-1"))
            .send({ userId: "someone-else" });

        expect(res.status).toBe(403);
        expect(db.transaction).not.toHaveBeenCalled();
    });

    it("rejects checkout when the cart is empty", async () => {
        useTransaction(async () => ({ rows: [] }));

        const res = await request(app)
            .post("/orders")
            .set("Authorization", authHeader("user-1"))
            .send({ userId: "user-1" });

        expect(res.status).toBe(400);
        expect(res.body.error).toBe("Cart is empty");
    });

    it("creates an order, snapshots line items, and empties the cart in one transaction", async () => {
        const clientQuery = useTransaction(async (sql) => {
            if (sql.includes("FROM cart_items")) {
                return {
                    rows: [
                        { product_id: "prod-1", quantity: 2, price: "9.99" },
                        { product_id: "prod-2", quantity: 1, price: "24.99" },
                    ],
                };
            }
            if (sql.includes("INSERT INTO orders")) {
                return { rows: [{ id: "order-1" }] };
            }
            // INSERT INTO order_items / DELETE FROM cart_items
            return { rows: [] };
        });

        const res = await request(app)
            .post("/orders")
            .set("Authorization", authHeader("user-1"))
            .send({ userId: "user-1" });

        expect(res.status).toBe(201);
        expect(res.body).toEqual({
            orderId: "order-1",
            totalAmount: 2 * 9.99 + 24.99,
            status: "completed",
        });

        const sqlCalls = clientQuery.mock.calls.map(([sql]) => sql);
        expect(sqlCalls.some((sql) => sql.includes("INSERT INTO order_items"))).toBe(true);
        expect(sqlCalls.filter((sql) => sql.includes("INSERT INTO order_items"))).toHaveLength(2);
        expect(sqlCalls.some((sql) => sql.includes("DELETE FROM cart_items"))).toBe(true);
    });

    it("returns 500 and does not swallow unexpected transaction failures", async () => {
        db.transaction.mockRejectedValueOnce(new Error("connection lost"));

        const res = await request(app)
            .post("/orders")
            .set("Authorization", authHeader("user-1"))
            .send({ userId: "user-1" });

        expect(res.status).toBe(500);
    });
});

describe("GET /orders", () => {
    beforeEach(() => {
        jest.resetAllMocks();
    });

    it("rejects a request with no userId", async () => {
        const res = await request(app)
            .get("/orders")
            .set("Authorization", authHeader("user-1"));

        expect(res.status).toBe(400);
    });

    it("returns the user's order history with a per-order item count", async () => {
        db.query.mockResolvedValueOnce({
            rows: [{
                id: "order-1",
                user_id: "user-1",
                total_amount: "34.98",
                status: "completed",
                item_count: 2,
            }],
        });

        const res = await request(app)
            .get("/orders")
            .set("Authorization", authHeader("user-1"))
            .query({ userId: "user-1" });

        expect(res.status).toBe(200);
        expect(res.body).toHaveLength(1);
        expect(res.body[0].item_count).toBe(2);

        const [sql] = db.query.mock.calls[0];
        expect(sql).toMatch(/COUNT\(\*\)/);
    });
});
