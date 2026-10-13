-- Add updated_by column to main tables
ALTER TABLE clinic ADD COLUMN updated_by INT REFERENCES users(user_id);
ALTER TABLE users ADD COLUMN updated_by INT REFERENCES users(user_id);
ALTER TABLE patient ADD COLUMN updated_by INT REFERENCES users(user_id);
ALTER TABLE procedure ADD COLUMN updated_by INT REFERENCES users(user_id);
ALTER TABLE appointment ADD COLUMN updated_by INT REFERENCES users(user_id);

-- Create audit log table
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id INT NOT NULL,
    action TEXT CHECK (action IN ('insert','update','delete')),
    changed_by INT REFERENCES users(user_id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_data JSONB,
    new_data JSONB
);

-- Generic function to insert audit log entries
CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log(table_name, record_id, action, changed_by, old_data, new_data)
    VALUES (TG_TABLE_NAME, NEW.user_id, 'update', NEW.updated_by, row_to_json(OLD), row_to_json(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log(table_name, record_id, action, changed_by, new_data)
    VALUES (TG_TABLE_NAME, NEW.user_id, 'insert', NEW.updated_by, row_to_json(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log(table_name, record_id, action, changed_by, old_data)
    VALUES (TG_TABLE_NAME, OLD.user_id, 'delete', OLD.updated_by, row_to_json(OLD));
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Attach audit triggers (example for users table)
CREATE TRIGGER trg_users_audit
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW
EXECUTE FUNCTION log_audit();

-- Repeat for other tables
CREATE TRIGGER trg_clinic_audit
AFTER INSERT OR UPDATE OR DELETE ON clinic
FOR EACH ROW
EXECUTE FUNCTION log_audit();

CREATE TRIGGER trg_patient_audit
AFTER INSERT OR UPDATE OR DELETE ON patient
FOR EACH ROW
EXECUTE FUNCTION log_audit();

CREATE TRIGGER trg_procedure_audit
AFTER INSERT OR UPDATE OR DELETE ON procedure
FOR EACH ROW
EXECUTE FUNCTION log_audit();

CREATE TRIGGER trg_appointment_audit
AFTER INSERT OR UPDATE OR DELETE ON appointment
FOR EACH ROW
EXECUTE FUNCTION log_audit();
