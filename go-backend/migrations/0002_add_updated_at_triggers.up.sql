-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach triggers to each table
CREATE TRIGGER trg_clinic_updated_at
BEFORE UPDATE ON clinic
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_patient_updated_at
BEFORE UPDATE ON patient
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_procedure_updated_at
BEFORE UPDATE ON procedure
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_appointment_updated_at
BEFORE UPDATE ON appointment
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();