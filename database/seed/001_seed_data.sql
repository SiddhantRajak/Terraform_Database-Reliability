-- Deterministic sample data: 120 bookings across organizations, cities and statuses.
INSERT INTO hotel_bookings
(id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
SELECT
  gen_random_uuid(),
  (ARRAY[
    '11111111-1111-1111-1111-111111111111'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid
  ])[1 + (g % 3)],
  'hotel-' || (1 + (g % 12)),
  (ARRAY['delhi','mumbai','jaipur','pune','indore'])[1 + (g % 5)],
  CURRENT_DATE + (g % 30),
  CURRENT_DATE + (g % 30) + 2,
  (500 + (g * 37) % 15000)::numeric(12,2),
  (ARRAY['confirmed','pending','cancelled','completed'])[1 + (g % 4)],
  NOW() - ((g % 45) || ' days')::interval
FROM generate_series(1,120) AS g;

INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT b.id,
       (ARRAY['booking_created','booking_confirmed','booking_updated'])[1 + (rn % 3)],
       jsonb_build_object('source','seed','booking_status',b.status),
       b.created_at + interval '1 hour'
FROM (
  SELECT b.*, row_number() OVER (ORDER BY b.created_at) AS rn
  FROM hotel_bookings b
) AS b
WHERE b.rn % 2 = 0;
