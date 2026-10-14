-- Drop triggers
DROP TRIGGER IF EXISTS trg_clinic_updated_at ON clinic;
DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
DROP TRIGGER IF EXISTS trg_patient_updated_at ON patient;
DROP TRIGGER IF EXISTS trg_procedure_updated_at ON procedure;
DROP TRIGGER IF EXISTS trg_appointment_updated_at ON appointment;

-- Drop function
DROP FUNCTION IF EXISTS set_updated_at;
