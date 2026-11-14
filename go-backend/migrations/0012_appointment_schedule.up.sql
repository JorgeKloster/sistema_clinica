-- Alinha a tabela appointment ao que a agenda precisa:
--  * início e fim do atendimento (a duração varia: 30 min, 1h, 2h...)
--  * status sempre preenchido
--  * um profissional não pode ter dois atendimentos ao mesmo tempo
--
-- starts_at/ends_at são horário local da clínica (TIMESTAMP sem fuso).

CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE appointment ADD COLUMN starts_at TIMESTAMP;
ALTER TABLE appointment ADD COLUMN ends_at TIMESTAMP;

-- Linhas antigas (se existirem): usa date + time e assume 1 hora.
UPDATE appointment
SET starts_at = "date" + "time",
    ends_at   = "date" + "time" + INTERVAL '1 hour';

ALTER TABLE appointment ALTER COLUMN starts_at SET NOT NULL;
ALTER TABLE appointment ALTER COLUMN ends_at SET NOT NULL;

ALTER TABLE appointment
ADD CONSTRAINT appointment_time_order CHECK (ends_at > starts_at);

UPDATE appointment SET status = 'scheduled' WHERE status IS NULL;
ALTER TABLE appointment ALTER COLUMN status SET DEFAULT 'scheduled';
ALTER TABLE appointment ALTER COLUMN status SET NOT NULL;

-- Remove as colunas antigas (os índices que usavam "date" caem junto).
ALTER TABLE appointment DROP COLUMN "date";
ALTER TABLE appointment DROP COLUMN "time";

CREATE INDEX idx_appointment_clinic_starts ON appointment(clinic_id, starts_at);
CREATE INDEX idx_appointment_doctor_starts ON appointment(doctor_id, starts_at);

-- Sem sobreposição por profissional; agendamentos cancelados liberam o horário.
ALTER TABLE appointment
ADD CONSTRAINT appointment_doctor_no_overlap
EXCLUDE USING gist (
    doctor_id WITH =,
    tsrange(starts_at, ends_at) WITH &&
) WHERE (status <> 'canceled');
