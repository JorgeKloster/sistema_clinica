-- Quando e por quem as informações de saúde do paciente foram alteradas
-- (alergias, condições e medicamentos vêm da 0014).
ALTER TABLE patient ADD COLUMN health_updated_at TIMESTAMP;
ALTER TABLE patient ADD COLUMN health_updated_by INT REFERENCES users(user_id) ON DELETE SET NULL;
