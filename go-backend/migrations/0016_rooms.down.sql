ALTER TABLE appointment DROP CONSTRAINT IF EXISTS appointment_room_no_overlap;
DROP INDEX IF EXISTS idx_appointment_room_starts;
ALTER TABLE appointment DROP COLUMN room_id;

DROP INDEX IF EXISTS idx_procedure_room_id;
ALTER TABLE procedure DROP COLUMN room_id;

DROP TABLE room;

DROP TRIGGER IF EXISTS trg_clinic_seed_room_types ON clinic;
DROP FUNCTION IF EXISTS seed_default_room_types();
DROP TABLE room_type;
