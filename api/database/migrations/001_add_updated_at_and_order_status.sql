-- Migration 001: audit timestamps + a real order status lifecycle.
--
-- Tracked by database/migrate.js in schema_migrations, unlike schema.sql
-- (the original idempotent baseline, still applied in full every run —
-- see docs/DATABASE.md for why that split exists). Schema changes from
-- this point forward go through numbered files like this one instead of
-- growing schema.sql's own guarded-ALTER tail indefinitely.

ALTER TABLE users      ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE devices    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE cart_items ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE orders     ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_devices_updated_at ON devices;
CREATE TRIGGER trg_devices_updated_at BEFORE UPDATE ON devices
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_cart_items_updated_at ON cart_items;
CREATE TRIGGER trg_cart_items_updated_at BEFORE UPDATE ON cart_items
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_orders_updated_at ON orders;
CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- orders.status previously had no CHECK constraint, and order.model.js
-- inserted every order as 'completed' immediately — no real lifecycle.
-- Stock validation + order cancellation (this pass) need one: an order
-- starts pending, and becomes completed or cancelled. Existing rows
-- (already 'completed') are untouched; only the default changes, so
-- future inserts start pending.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'orders_status_check'
    ) THEN
        ALTER TABLE orders ADD CONSTRAINT orders_status_check
            CHECK (status IN ('pending', 'completed', 'cancelled'));
    END IF;
END $$;

ALTER TABLE orders ALTER COLUMN status SET DEFAULT 'pending';
