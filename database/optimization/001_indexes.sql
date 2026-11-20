-- Supports the assessment query's city equality and created_at range filters.
CREATE INDEX IF NOT EXISTS idx_bookings_city_created_org_status
ON hotel_bookings (city, created_at, org_id, status);

-- Supports looking up lifecycle events for a booking in time order.
CREATE INDEX IF NOT EXISTS idx_booking_events_booking_created
ON booking_events (booking_id, created_at);