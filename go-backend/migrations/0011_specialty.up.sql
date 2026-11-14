-- Especialidades oferecidas por cada clínica.
-- users.specialty continua guardando o nome (texto); a API valida que o
-- nome exista nesta tabela para a clínica do usuário.

CREATE TABLE specialty (
    specialty_id SERIAL PRIMARY KEY,
    clinic_id INT NOT NULL REFERENCES clinic(clinic_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sem duplicatas por clínica, ignorando maiúsculas/minúsculas.
CREATE UNIQUE INDEX specialty_clinic_name_unique
ON specialty (clinic_id, lower(name));

-- Lista padrão para clínicas novas.
CREATE OR REPLACE FUNCTION seed_default_specialties()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO specialty (clinic_id, name)
  SELECT NEW.clinic_id, s
  FROM unnest(ARRAY[
    'Dentista',
    'Fisioterapeuta',
    'Oftalmologista',
    'Dermatologista',
    'Nutricionista',
    'Psicólogo',
    'Fonoaudiólogo',
    'Clínico Geral'
  ]) AS s
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_clinic_seed_specialties
AFTER INSERT ON clinic
FOR EACH ROW
EXECUTE FUNCTION seed_default_specialties();

-- Clínicas que já existem: lista padrão...
INSERT INTO specialty (clinic_id, name)
SELECT c.clinic_id, s.name
FROM clinic c
CROSS JOIN (VALUES
    ('Dentista'),
    ('Fisioterapeuta'),
    ('Oftalmologista'),
    ('Dermatologista'),
    ('Nutricionista'),
    ('Psicólogo'),
    ('Fonoaudiólogo'),
    ('Clínico Geral')
) AS s(name)
ON CONFLICT DO NOTHING;

-- ...mais o que os profissionais já cadastrados tinham em texto livre.
INSERT INTO specialty (clinic_id, name)
SELECT DISTINCT u.clinic_id, btrim(u.specialty)
FROM users u
WHERE u.clinic_id IS NOT NULL
  AND u.specialty IS NOT NULL
  AND btrim(u.specialty) <> ''
ON CONFLICT DO NOTHING;
