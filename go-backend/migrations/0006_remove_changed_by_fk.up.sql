-- Remove FK from audit log

ALTER TABLE audit_log
DROP CONSTRAINT IF EXISTS audit_log_changed_by_fkey;

-- Keep the column as INT only

ALTER TABLE audit_log
ALTER COLUMN changed_by TYPE INT;