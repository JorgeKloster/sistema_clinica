-- Remove dependency on user_id column
CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
BEGIN

  IF TG_OP = 'UPDATE' THEN

    INSERT INTO audit_log(
      table_name,
      action,
      changed_by,
      old_data,
      new_data
    )
    VALUES (
      TG_TABLE_NAME,
      'update',
      NEW.updated_by,
      row_to_json(OLD),
      row_to_json(NEW)
    );

    RETURN NEW;

  ELSIF TG_OP = 'INSERT' THEN

    INSERT INTO audit_log(
      table_name,
      action,
      changed_by,
      new_data
    )
    VALUES (
      TG_TABLE_NAME,
      'insert',
      NEW.updated_by,
      row_to_json(NEW)
    );

    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN

    INSERT INTO audit_log(
      table_name,
      action,
      changed_by,
      old_data
    )
    VALUES (
      TG_TABLE_NAME,
      'delete',
      OLD.updated_by,
      row_to_json(OLD)
    );

    RETURN OLD;

  END IF;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE audit_log
DROP COLUMN IF EXISTS record_id;