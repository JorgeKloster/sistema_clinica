-- Store email snapshot as well

ALTER TABLE audit_log
ADD COLUMN IF NOT EXISTS changed_by_email TEXT;

-- Performance indexes

CREATE INDEX IF NOT EXISTS idx_audit_table_name
ON audit_log(table_name);

CREATE INDEX IF NOT EXISTS idx_audit_changed_at
ON audit_log(changed_at);

CREATE INDEX IF NOT EXISTS idx_audit_changed_by_id
ON audit_log(changed_by_id);

-- Update trigger

CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
DECLARE
    v_user_name TEXT;
    v_user_email TEXT;
BEGIN

    IF TG_OP <> 'DELETE' THEN

        SELECT
            first_name || ' ' || last_name,
            email
        INTO
            v_user_name,
            v_user_email
        FROM users
        WHERE user_id = NEW.updated_by;

    ELSE

        SELECT
            first_name || ' ' || last_name,
            email
        INTO
            v_user_name,
            v_user_email
        FROM users
        WHERE user_id = OLD.updated_by;

    END IF;

    IF TG_OP = 'UPDATE' THEN

        INSERT INTO audit_log(
            table_name,
            action,
            changed_by_id,
            changed_by_name,
            changed_by_email,
            old_data,
            new_data
        )
        VALUES (
            TG_TABLE_NAME,
            'update',
            NEW.updated_by,
            v_user_name,
            v_user_email,
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
            changed_by_email,
            new_data
        )
        VALUES (
            TG_TABLE_NAME,
            'insert',
            NEW.updated_by,
            v_user_name,
            v_user_email,
            row_to_json(NEW)
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO audit_log(
            table_name,
            action,
            changed_by_id,
            changed_by_name,
            changed_by_email,
            old_data
        )
        VALUES (
            TG_TABLE_NAME,
            'delete',
            OLD.updated_by,
            v_user_name,
            v_user_email,
            row_to_json(OLD)
        );

        RETURN OLD;

    END IF;
END;
$$ LANGUAGE plpgsql;