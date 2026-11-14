ALTER TABLE appointment
DROP CONSTRAINT IF EXISTS appointment_doctor_id_fkey;

ALTER TABLE appointment
ADD CONSTRAINT appointment_doctor_id_fkey
FOREIGN KEY (doctor_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE appointment
DROP CONSTRAINT IF EXISTS appointment_procedure_id_fkey;

ALTER TABLE appointment
ADD CONSTRAINT appointment_procedure_id_fkey
FOREIGN KEY (procedure_id) REFERENCES procedure(procedure_id) ON DELETE CASCADE;
