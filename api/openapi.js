// Hand-authored, not generated from JSDoc annotations scattered across
// controllers — simpler to keep accurate, and there's no ambiguity about
// what the "source of truth" is. Served at /docs via swagger-ui-express
// (see app.js). Full prose reference: ../docs/API.md.
const bearerAuth = { bearerAuth: [] };

module.exports = {
    openapi: "3.0.3",
    info: {
        title: "Wearable Health & Shopping API",
        version: "1.0.0",
        description:
            "Backend for the FitRing wearable health + shopping app. See ../docs/API.md for the full prose reference, including the worked auth example and idempotency notes.",
    },
    servers: [{ url: "http://localhost:3000" }],
    components: {
        securitySchemes: {
            bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT" },
        },
        schemas: {
            Error: {
                type: "object",
                properties: { error: { type: "string" } },
            },
        },
    },
    paths: {
        "/healthz": {
            get: {
                summary: "Liveness probe",
                tags: ["Ops"],
                responses: { 200: { description: "OK" } },
            },
        },
        "/auth/login": {
            post: {
                summary: "Log in (creates the user on first login)",
                tags: ["Auth"],
                requestBody: {
                    required: true,
                    content: {
                        "application/json": {
                            schema: {
                                type: "object",
                                required: ["email", "password"],
                                properties: {
                                    email: { type: "string", format: "email" },
                                    password: { type: "string" },
                                    name: { type: "string", description: "Only used on first login" },
                                },
                            },
                        },
                    },
                },
                responses: {
                    200: { description: "Signed JWT + user profile" },
                    400: { description: "Missing email/password", content: { "application/json": { schema: { $ref: "#/components/schemas/Error" } } } },
                    401: { description: "Wrong password" },
                    429: { description: "Too many attempts (rate limited)" },
                },
            },
        },
        "/auth/logout": {
            post: {
                summary: "Log out (stateless — see docs/DECISIONS.md)",
                tags: ["Auth"],
                security: [bearerAuth],
                responses: { 200: { description: "Acknowledged" }, 401: { description: "Missing/invalid token" } },
            },
        },
        "/devices": {
            post: {
                summary: "Register (upsert) a device",
                tags: ["Devices"],
                security: [bearerAuth],
                responses: { 201: { description: "Device row" } },
            },
            get: {
                summary: "List a user's devices",
                tags: ["Devices"],
                security: [bearerAuth],
                parameters: [{ name: "userId", in: "query", required: true, schema: { type: "string" } }],
                responses: { 200: { description: "Device list" } },
            },
        },
        "/health/readings": {
            post: {
                summary: "Batch-upload health readings (idempotent)",
                tags: ["Health"],
                security: [bearerAuth],
                responses: { 201: { description: "{ synced, duplicatesSkipped, results }" } },
            },
            get: {
                summary: "Paginated reading history",
                tags: ["Health"],
                security: [bearerAuth],
                parameters: [
                    { name: "userId", in: "query", required: true, schema: { type: "string" } },
                    { name: "page", in: "query", schema: { type: "integer", default: 1 } },
                    { name: "limit", in: "query", schema: { type: "integer", default: 50, maximum: 100 } },
                ],
                responses: { 200: { description: "{ data, page, limit }" } },
            },
        },
        "/health/summary": {
            get: {
                summary: "Daily/weekly aggregated summary (last 7 days)",
                tags: ["Health"],
                security: [bearerAuth],
                parameters: [
                    { name: "userId", in: "query", required: true, schema: { type: "string" } },
                    { name: "period", in: "query", schema: { type: "string", enum: ["daily", "weekly"] } },
                ],
                responses: { 200: { description: "Array of summary buckets" } },
            },
        },
        "/products": {
            get: {
                summary: "List products (paginated, optional search)",
                tags: ["Shopping"],
                parameters: [
                    { name: "page", in: "query", schema: { type: "integer", default: 1 } },
                    { name: "limit", in: "query", schema: { type: "integer", default: 20, maximum: 100 } },
                    { name: "q", in: "query", description: "Case-insensitive name search", schema: { type: "string" } },
                ],
                responses: { 200: { description: "{ data, page, limit, total }" } },
            },
        },
        "/products/{id}": {
            get: {
                summary: "Get one product",
                tags: ["Shopping"],
                parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
                responses: { 200: { description: "Product" }, 404: { description: "Not found" } },
            },
        },
        "/cart": {
            post: {
                summary: "Add to cart (increment-only upsert)",
                tags: ["Shopping"],
                security: [bearerAuth],
                responses: { 201: { description: "Cart item row" } },
            },
            get: {
                summary: "Get the caller's cart",
                tags: ["Shopping"],
                security: [bearerAuth],
                parameters: [{ name: "userId", in: "query", required: true, schema: { type: "string" } }],
                responses: { 200: { description: "{ items, totalAmount }" } },
            },
        },
        "/cart/{id}": {
            patch: {
                summary: "Set a line item to an exact quantity",
                tags: ["Shopping"],
                security: [bearerAuth],
                parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
                responses: { 200: { description: "Updated row" }, 404: { description: "Not owned by caller" } },
            },
            delete: {
                summary: "Remove a line item",
                tags: ["Shopping"],
                security: [bearerAuth],
                parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
                responses: { 204: { description: "Removed" }, 404: { description: "Not owned by caller" } },
            },
        },
        "/orders": {
            post: {
                summary: "Checkout — converts the cart into an order",
                tags: ["Shopping"],
                security: [bearerAuth],
                responses: {
                    201: { description: "Order summary" },
                    400: { description: "Cart is empty" },
                    409: { description: "Insufficient stock for one or more items" },
                },
            },
            get: {
                summary: "Order history",
                tags: ["Shopping"],
                security: [bearerAuth],
                parameters: [{ name: "userId", in: "query", required: true, schema: { type: "string" } }],
                responses: { 200: { description: "Orders, each with item_count" } },
            },
        },
        "/orders/{id}/cancel": {
            post: {
                summary: "Cancel a pending order (restores stock)",
                tags: ["Shopping"],
                security: [bearerAuth],
                parameters: [{ name: "id", in: "path", required: true, schema: { type: "string" } }],
                responses: {
                    200: { description: "Cancelled order" },
                    404: { description: "Not found / not owned by caller" },
                    409: { description: "Order isn't in a cancellable state" },
                },
            },
        },
    },
};
