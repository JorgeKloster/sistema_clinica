-- Informações de saúde do paciente, exibidas no atendimento.
ALTER TABLE patient ADD COLUMN allergies TEXT;
ALTER TABLE patient ADD COLUMN medical_conditions TEXT;
ALTER TABLE patient ADD COLUMN medications TEXT;

-- Histórico do paciente: busca por paciente em ordem cronológica.
CREATE INDEX idx_appointment_patient_starts ON appointment(patient_id, starts_at);
