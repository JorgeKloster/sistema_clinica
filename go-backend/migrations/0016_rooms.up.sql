-- Salas e recursos da clínica.
--  * room_type: tipos de sala por clínica (consultório médico, odontológico...)
--  * room: salas, cada uma com um tipo e a lista de recursos (um por linha)
--  * procedure.room_id: sala em que o procedimento é realizado (obrigatória)
--  * appointment.room_id: sala do agendamento (copiada do procedimento);
--    duas consultas não podem ocupar a mesma sala ao mesmo tempo.

CREATE TABLE room_type (
    room_type_id SERIAL PRIMARY KEY,
    clinic_id INT NOT NULL REFERENCES clinic(clinic_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX room_type_clinic_name_unique
ON room_type (clinic_id, lower(name));

-- Tipos padrão para clínicas novas.
CREATE OR REPLACE FUNCTION seed_default_room_types()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO room_type (clinic_id, name)
  SELECT NEW.clinic_id, t
  FROM unnest(ARRAY[
    'Consultório médico',
    'Consultório odontológico',
    'Sala de fisioterapia',
    'Sala de exames',
    'Sala de procedimentos'
  ]) AS t
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_clinic_seed_room_types
AFTER INSERT ON clinic
FOR EACH ROW
EXECUTE FUNCTION seed_default_room_types();

-- Clínicas que já existem.
INSERT INTO room_type (clinic_id, name)
SELECT c.clinic_id, t.name
FROM clinic c
CROSS JOIN (VALUES
    ('Consultório médico'),
    ('Consultório odontológico'),
    ('Sala de fisioterapia'),
    ('Sala de exames'),
    ('Sala de procedimentos')
) AS t(name)
ON CONFLICT DO NOTHING;

CREATE TABLE room (
    room_id SERIAL PRIMARY KEY,
    clinic_id INT NOT NULL REFERENCES clinic(clinic_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    room_type_id INT NOT NULL REFERENCES room_type(room_type_id) ON DELETE RESTRICT,
    resources TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by INT REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE UNIQUE INDEX room_clinic_name_unique ON room (clinic_id, lower(name));
CREATE INDEX idx_room_clinic_id ON room (clinic_id);

CREATE TRIGGER trg_room_updated_at
BEFORE UPDATE ON room
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- Procedimentos já cadastrados: uma sala inicial por clínica ("Sala 1"), que
-- o administrador pode renomear e redistribuir depois.
INSERT INTO room (clinic_id, name, room_type_id)
SELECT c.clinic_id,
       'Sala 1',
       (SELECT rt.room_type_id FROM room_type rt
        WHERE rt.clinic_id = c.clinic_id AND rt.name = 'Sala de procedimentos')
FROM clinic c
WHERE EXISTS (SELECT 1 FROM procedure p WHERE p.clinic_id = c.clinic_id);

ALTER TABLE procedure ADD COLUMN room_id INT REFERENCES room(room_id) ON DELETE RESTRICT;

UPDATE procedure p
SET room_id = (SELECT r.room_id FROM room r
               WHERE r.clinic_id = p.clinic_id AND r.name = 'Sala 1');

ALTER TABLE procedure ALTER COLUMN room_id SET NOT NULL;
CREATE INDEX idx_procedure_room_id ON procedure (room_id);

-- Agendamentos já existentes: recebem a sala do procedimento, exceto os que
-- conflitariam com outro agendamento da mesma sala (ficam sem sala, pois o
-- horário já estava duplicado). Cancelados nunca ocupam sala.
ALTER TABLE appointment ADD COLUMN room_id INT REFERENCES room(room_id) ON DELETE RESTRICT;

DO $$
DECLARE
  a RECORD;
BEGIN
  FOR a IN
    SELECT ap.appointment_id, ap.starts_at, ap.ends_at, ap.status, pr.room_id
    FROM appointment ap
    JOIN procedure pr ON pr.procedure_id = ap.procedure_id
    ORDER BY ap.starts_at, ap.appointment_id
  LOOP
    IF a.status = 'canceled' OR NOT EXISTS (
      SELECT 1 FROM appointment b
      WHERE b.room_id = a.room_id
        AND b.status <> 'canceled'
        AND b.appointment_id <> a.appointment_id
        AND tsrange(b.starts_at, b.ends_at) && tsrange(a.starts_at, a.ends_at)
    ) THEN
      UPDATE appointment SET room_id = a.room_id WHERE appointment_id = a.appointment_id;
    END IF;
  END LOOP;
END $$;

CREATE INDEX idx_appointment_room_starts ON appointment (room_id, starts_at);

ALTER TABLE appointment ADD CONSTRAINT appointment_room_no_overlap
EXCLUDE USING gist (
    room_id WITH =,
    tsrange(starts_at, ends_at) WITH &&
) WHERE (status <> 'canceled');
