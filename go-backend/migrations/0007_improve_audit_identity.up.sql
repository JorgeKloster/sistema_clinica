-- Remove FK

ALTER TABLE audit_log
DROP CONSTRAINT IF EXISTS audit_log_changed_by_fkey;

-- Rename changed_by

ALTER TABLE audit_log
RENAME COLUMN changed_by TO changed_by_id;

-- Store user snapshot

ALTER TABLE audit_log
ADD COLUMN changed_by_name TEXT;

-- Remove record_id because the JSON already contains the PK

ALTER TABLE audit_log
DROP COLUMN IF EXISTS record_id;

-- Replace trigger

CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
DECLARE
    v_user_name TEXT;
BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT
            first_name || ' ' || last_name
        INTO v_user_name
        FROM users
        WHERE user_id = NEW.updated_by;

    ELSE

        SELECT
            first_name || ' ' || last_name
        INTO v_user_name
        FROM users
        WHERE user_id = OLD.updated_by;

    END IF;

    IF TG_OP = 'UPDATE' THEN

        INSERT INTO audit_log(
            table_name,
            action,
            changed_by_id,
            changed_by_name,
            old_data,
            new_data
        )
        VALUES (
            TG_TABLE_NAME,
            'update',
            NEW.updated_by,
            v_user_name,
            row_to_json(OLD),
            row_to_json(NEW)
        );

        RETURN NEW;

    ELSIF TG_OP = 'INSERT' THEN

        INSERT INTO audit_log(
            table_name,
            action,
            changed_by_id,
            changed_by_name,
            new_data
        )
        VALUES (
            TG_TABLE_NAME,
            'insert',
            NEW.updated_by,
            v_user_name,
            row_to_json(NEW)
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO audit_log(
            table_name,
            action,
            changed_by_id,
            changed_by_name,
            old_data
        )
        VALUES (
            TG_TABLE_NAME,
            'delete',
            OLD.updated_by,
            v_user_name,
            row_to_json(OLD)
        );

        RETURN OLD;

    END IF;
END;
$$ LANGUAGE plpgsql;