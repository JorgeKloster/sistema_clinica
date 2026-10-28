ALTER TABLE patient
ADD COLUMN cpf VARCHAR(11);

ALTER TABLE patient
ADD CONSTRAINT patient_cpf_unique
UNIQUE (clinic_id, cpf);
