-- Excluir um paciente não pode apagar em cascata o histórico de
-- agendamentos. Passa a ser bloqueado (RESTRICT); a API devolve 409.

ALTER TABLE appointment
DROP CONSTRAINT IF EXISTS appointment_patient_id_fkey;

ALTER TABLE appointment
ADD CONSTRAINT appointment_patient_id_fkey
FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE RESTRICT;
