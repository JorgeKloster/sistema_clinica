DROP INDEX IF EXISTS idx_appointment_patient_starts;

ALTER TABLE patient DROP COLUMN medications;
ALTER TABLE patient DROP COLUMN medical_conditions;
ALTER TABLE patient DROP COLUMN allergies;
