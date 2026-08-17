-- Sample catalog data for the shopping module.
-- Run with: npm run db:seed

-- image_url points at a placeholder image service (placehold.co) — there's
-- no real product photography for this project. Swap for real asset URLs
-- (or an uploads/CDN path) whenever those exist.
INSERT INTO products (name, description, price, stock, image_url)
VALUES
    ('FitRing Smart Ring', 'Wearable ring that tracks heart rate, SpO2 and steps.', 149.99, 50, 'https://placehold.co/400x400/232532/e9e9ed?text=FitRing+Ring'),
    ('FitRing Charging Dock', 'USB-C charging dock for the FitRing smart ring.', 24.99, 200, 'https://placehold.co/400x400/232532/e9e9ed?text=Charging+Dock'),
    ('Replacement Silicone Band', 'Comfort-fit silicone band, available in multiple sizes.', 9.99, 500, 'https://placehold.co/400x400/232532/e9e9ed?text=Silicone+Band'),
    ('Sleep & Recovery Add-on', 'Companion sensor for advanced sleep tracking.', 59.99, 75, 'https://placehold.co/400x400/232532/e9e9ed?text=Sleep+Add-on'),
    ('Travel Case', 'Compact protective case for your wearable and accessories.', 19.99, 150, 'https://placehold.co/400x400/232532/e9e9ed?text=Travel+Case')
ON CONFLICT (name) DO UPDATE SET image_url = EXCLUDED.image_url;
