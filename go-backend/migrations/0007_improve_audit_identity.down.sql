ALTER TABLE audit_log
ADD COLUMN record_id INT NOT NULL DEFAULT 0;

ALTER TABLE audit_log
DROP COLUMN IF EXISTS changed_by_name;

ALTER TABLE audit_log
RENAME COLUMN changed_by_id TO changed_by;

ALTER TABLE audit_log
ADD CONSTRAINT audit_log_changed_by_fkey
FOREIGN KEY (changed_by)
REFERENCES users(user_id);