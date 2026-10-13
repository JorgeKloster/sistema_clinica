-- Clinics
CREATE TABLE clinic (
    clinic_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- System Users (staff: admin, doctor, receptionist)
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    clinic_id INT REFERENCES clinic(clinic_id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) CHECK (role IN ('admin','doctor','receptionist')),
    specialty VARCHAR(100), -- only relevant if role = 'doctor'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_clinic_id ON users(clinic_id);
CREATE INDEX idx_users_specialty ON users(specialty);

-- Patients
CREATE TABLE patient (
    patient_id SERIAL PRIMARY KEY,
    clinic_id INT REFERENCES clinic(clinic_id) ON DELETE CASCADE,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    birth_date DATE,
    gender VARCHAR(20),
    email VARCHAR(255),
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_patient_email ON patient(email);
CREATE INDEX idx_patient_clinic_id ON patient(clinic_id);

-- Procedures
CREATE TABLE procedure (
    procedure_id SERIAL PRIMARY KEY,
    clinic_id INT REFERENCES clinic(clinic_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    specialty VARCHAR(100),
    price NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_procedure_clinic_id ON procedure(clinic_id);

-- Appointments
CREATE TABLE appointment (
    appointment_id SERIAL PRIMARY KEY,
    clinic_id INT REFERENCES clinic(clinic_id) ON DELETE CASCADE,
    patient_id INT REFERENCES patient(patient_id) ON DELETE CASCADE,
    doctor_id INT REFERENCES users(user_id) ON DELETE CASCADE, -- doctor is a users with role='doctor'
    procedure_id INT REFERENCES procedure(procedure_id) ON DELETE CASCADE,
    date DATE NOT NULL,
    time TIME NOT NULL,
    status VARCHAR(50) CHECK (status IN ('scheduled','confirmed','completed','canceled')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_appointment_clinic_date ON appointment(clinic_id, date);
CREATE INDEX idx_appointment_patient_id ON appointment(patient_id);
CREATE INDEX idx_appointment_doctor_date ON appointment(doctor_id, date);
CREATE INDEX idx_appointment_procedure_id ON appointment(procedure_id);
