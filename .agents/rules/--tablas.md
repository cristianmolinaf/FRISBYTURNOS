---
trigger: always_on
---

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE rol_usuario AS ENUM ('superadmin', 'jefe_zona', 'administrador', 'colaborador');
CREATE TYPE estado_solicitud AS ENUM ('pendiente', 'aprobada', 'rechazada');
CREATE TYPE tipo_novedad AS ENUM ('descanso', 'cita_medica', 'calamidad', 'sugerencia');

CREATE TABLE zonas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre VARCHAR(100) NOT NULL,
  jefe_zona_id UUID
);

CREATE TABLE restaurantes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre VARCHAR(100) NOT NULL,
  zona_id UUID REFERENCES zonas(id),
  direccion VARCHAR(255)
);

CREATE TABLE perfiles (
  id UUID PRIMARY KEY, 
  cedula VARCHAR(20) UNIQUE NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  correo VARCHAR(150) UNIQUE NOT NULL,
  rol rol_usuario NOT NULL DEFAULT 'colaborador',
  restaurante_id UUID REFERENCES restaurantes(id),
  estacion_principal VARCHAR(50), 
  equipo VARCHAR(50), 
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE zonas ADD CONSTRAINT fk_jefe_zona FOREIGN KEY (jefe_zona_id) REFERENCES perfiles(id);

CREATE TABLE turnos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  colaborador_id UUID REFERENCES perfiles(id) NOT NULL,
  supervisor_id UUID REFERENCES perfiles(id) NOT NULL,
  restaurante_id UUID REFERENCES restaurantes(id) NOT NULL,
  fecha DATE NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  pausa_inicio TIME,
  pausa_fin TIME,
  estacion VARCHAR(50) NOT NULL,
  estado VARCHAR(20) DEFAULT 'programado',
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mercado_turnos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  turno_id UUID REFERENCES turnos(id) NOT NULL,
  solicitante_id UUID REFERENCES perfiles(id) NOT NULL,
  receptor_id UUID REFERENCES perfiles(id),
  estado estado_solicitud DEFAULT 'pendiente',
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE disponibilidad (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  colaborador_id UUID REFERENCES perfiles(id) NOT NULL,
  fecha DATE NOT NULL,
  motivo tipo_novedad NOT NULL,
  detalles TEXT,
  estado estado_solicitud DEFAULT 'pendiente',
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE notificaciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id UUID REFERENCES perfiles(id) NOT NULL,
  titulo VARCHAR(100) NOT NULL,
  mensaje TEXT NOT NULL,
  leido BOOLEAN DEFAULT FALSE,
  creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
