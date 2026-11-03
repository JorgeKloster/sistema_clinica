DROP INDEX IF EXISTS idx_audit_table_name;
DROP INDEX IF EXISTS idx_audit_changed_at;
DROP INDEX IF EXISTS idx_audit_changed_by_id;

ALTER TABLE audit_log
DROP COLUMN IF EXISTS changed_by_email;
