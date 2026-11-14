-- Excluir um profissional ou um procedimento não pode apagar em cascata
-- os agendamentos (histórico clínico). Passa a ser bloqueado (RESTRICT);
-- a API devolve 409 nesses casos.

ALTER TABLE appointment
DROP CONSTRAINT IF EXISTS appointment_doctor_id_fkey;

ALTER TABLE appointment
ADD CONSTRAINT appointment_doctor_id_fkey
FOREIGN KEY (doctor_id) REFERENCES users(user_id) ON DELETE RESTRICT;

ALTER TABLE appointment
DROP CONSTRAINT IF EXISTS appointment_procedure_id_fkey;

ALTER TABLE appointment
ADD CONSTRAINT appointment_procedure_id_fkey
FOREIGN KEY (procedure_id) REFERENCES procedure(procedure_id) ON DELETE RESTRICT;
