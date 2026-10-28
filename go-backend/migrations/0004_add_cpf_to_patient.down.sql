ALTER TABLE patient
DROP CONSTRAINT patient_cpf_unique;

ALTER TABLE patient
DROP COLUMN cpf;