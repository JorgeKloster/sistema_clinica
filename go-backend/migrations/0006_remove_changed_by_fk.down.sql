ALTER TABLE audit_log
ADD CONSTRAINT audit_log_changed_by_fkey
FOREIGN KEY (changed_by)
REFERENCES users(user_id);