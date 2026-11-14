UPDATE appointment SET status = 'confirmed' WHERE status = 'in_progress';

ALTER TABLE appointment DROP CONSTRAINT IF EXISTS appointment_status_check;
ALTER TABLE appointment ADD CONSTRAINT appointment_status_check
    CHECK (status IN ('scheduled','confirmed','completed','canceled'));

ALTER TABLE appointment DROP COLUMN clinical_notes;
ALTER TABLE appointment DROP COLUMN finished_at;
ALTER TABLE appointment DROP COLUMN started_at;

ALTER TABLE procedure DROP CONSTRAINT IF EXISTS procedure_duration_range;
ALTER TABLE procedure DROP COLUMN duration_minutes;
