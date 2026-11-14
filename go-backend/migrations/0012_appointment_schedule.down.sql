ALTER TABLE appointment DROP CONSTRAINT IF EXISTS appointment_doctor_no_overlap;

DROP INDEX IF EXISTS idx_appointment_clinic_starts;
DROP INDEX IF EXISTS idx_appointment_doctor_starts;

ALTER TABLE appointment ADD COLUMN "date" DATE;
ALTER TABLE appointment ADD COLUMN "time" TIME;

UPDATE appointment
SET "date" = starts_at::date,
    "time" = starts_at::time;

ALTER TABLE appointment ALTER COLUMN "date" SET NOT NULL;
ALTER TABLE appointment ALTER COLUMN "time" SET NOT NULL;

ALTER TABLE appointment DROP CONSTRAINT IF EXISTS appointment_time_order;
ALTER TABLE appointment DROP COLUMN starts_at;
ALTER TABLE appointment DROP COLUMN ends_at;

ALTER TABLE appointment ALTER COLUMN status DROP NOT NULL;
ALTER TABLE appointment ALTER COLUMN status DROP DEFAULT;

CREATE INDEX idx_appointment_clinic_date ON appointment(clinic_id, "date");
CREATE INDEX idx_appointment_doctor_date ON appointment(doctor_id, "date");
