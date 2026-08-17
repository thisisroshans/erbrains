-- Sample catalog data for the shopping module.
-- Run with: npm run db:seed

INSERT INTO products (name, description, price, stock)
VALUES
    ('FitRing Smart Ring', 'Wearable ring that tracks heart rate, SpO2 and steps.', 149.99, 50),
    ('FitRing Charging Dock', 'USB-C charging dock for the FitRing smart ring.', 24.99, 200),
    ('Replacement Silicone Band', 'Comfort-fit silicone band, available in multiple sizes.', 9.99, 500),
    ('Sleep & Recovery Add-on', 'Companion sensor for advanced sleep tracking.', 59.99, 75),
    ('Travel Case', 'Compact protective case for your wearable and accessories.', 19.99, 150)
ON CONFLICT DO NOTHING;
