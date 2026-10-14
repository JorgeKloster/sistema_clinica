-- Drop triggers
DROP TRIGGER IF EXISTS trg_users_audit ON users;
DROP TRIGGER IF EXISTS trg_clinic_audit ON clinic;
DROP TRIGGER IF EXISTS trg_patient_audit ON patient;
DROP TRIGGER IF EXISTS trg_procedure_audit ON procedure;
DROP TRIGGER IF EXISTS trg_appointment_audit ON appointment;

-- Drop function
DROP FUNCTION IF EXISTS log_audit;

-- Drop audit log table
DROP TABLE IF EXISTS audit_log;

-- Remove updated_by columns
ALTER TABLE clinic DROP COLUMN IF EXISTS updated_by;
ALTER TABLE users DROP COLUMN IF EXISTS updated_by;
ALTER TABLE patient DROP COLUMN IF EXISTS updated_by;
ALTER TABLE procedure DROP COLUMN IF EXISTS updated_by;
ALTER TABLE appointment DROP COLUMN IF EXISTS updated_by;
