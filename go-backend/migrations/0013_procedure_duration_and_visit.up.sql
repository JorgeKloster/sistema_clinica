-- Duração sugerida do procedimento (o agendamento pode ajustá-la).
ALTER TABLE procedure ADD COLUMN duration_minutes INT NOT NULL DEFAULT 60;
ALTER TABLE procedure ADD CONSTRAINT procedure_duration_range
    CHECK (duration_minutes BETWEEN 5 AND 480);

-- Atendimento: início/fim reais e anotações clínicas.
ALTER TABLE appointment ADD COLUMN started_at TIMESTAMP;
ALTER TABLE appointment ADD COLUMN finished_at TIMESTAMP;
ALTER TABLE appointment ADD COLUMN clinical_notes TEXT;

-- Novo status: in_progress (atendimento iniciado).
ALTER TABLE appointment DROP CONSTRAINT IF EXISTS appointment_status_check;
ALTER TABLE appointment ADD CONSTRAINT appointment_status_check
    CHECK (status IN ('scheduled','confirmed','in_progress','completed','canceled'));
