-- =====================================================================
--  Sistema para gestion y seguimiento de los trabajos de grado de la UTS
--  Base de datos MySQL 8 / MariaDB 10.x  -  esquema trabajos_grado_uts
--  18 tablas normalizadas hasta 3FN.
--  Ejecutar completo desde phpMyAdmin (pestana SQL) o con:
--      mysql -u root < sql/01_base_datos_trabajos_grado.sql
-- =====================================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP DATABASE IF EXISTS trabajos_grado_uts;
CREATE DATABASE trabajos_grado_uts CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE trabajos_grado_uts;

-- ---------------------------------------------------------------------
-- 1. USUARIOS Y ROLES
--    Roles base: ESTUDIANTE, ADMINISTRADOR, COMITE, DOCENTE.
--    El docente se especializa por trabajo (DIRECTOR / EVALUADOR) en rol_docente.
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id_usuario          INT AUTO_INCREMENT PRIMARY KEY,
    correo              VARCHAR(120) NOT NULL,
    documento_identidad VARCHAR(20)  NOT NULL,
    nombres             VARCHAR(80)  NOT NULL,
    apellidos           VARCHAR(80)  NOT NULL,
    clave_hash          CHAR(64)     NOT NULL,
    sal                 VARCHAR(32)  NOT NULL,
    estado              ENUM('ACTIVO','INACTIVO','BLOQUEADO') NOT NULL DEFAULT 'ACTIVO',
    intentos_fallidos   INT          NOT NULL DEFAULT 0,
    CONSTRAINT uq_usuario_correo    UNIQUE (correo),
    CONSTRAINT uq_usuario_documento UNIQUE (documento_identidad)
) ENGINE=InnoDB;

CREATE TABLE rol (
    id_rol      INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(30)  NOT NULL,
    descripcion VARCHAR(150),
    CONSTRAINT uq_rol_nombre UNIQUE (nombre)
) ENGINE=InnoDB;

CREATE TABLE usuario_rol (
    id_usuario       INT NOT NULL,
    id_rol           INT NOT NULL,
    fecha_asignacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario, id_rol),
    CONSTRAINT fk_ur_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_ur_rol     FOREIGN KEY (id_rol)     REFERENCES rol(id_rol)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. CATALOGOS
-- ---------------------------------------------------------------------
CREATE TABLE programa_academico (
    id_programa INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(120) NOT NULL,
    facultad    VARCHAR(120) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE linea_investigacion (
    id_linea    INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(120) NOT NULL,
    descripcion VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE fase (
    id_fase INT AUTO_INCREMENT PRIMARY KEY,
    orden   INT          NOT NULL,
    nombre  VARCHAR(80)  NOT NULL,
    CONSTRAINT uq_fase_orden UNIQUE (orden)
) ENGINE=InnoDB;

CREATE TABLE parametro_sistema (
    clave       VARCHAR(50)  PRIMARY KEY,
    valor       VARCHAR(255) NOT NULL,
    descripcion VARCHAR(200)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. BANCO DE IDEAS
--    estado: PENDIENTE (espera aprobacion del comite), DISPONIBLE,
--            ASIGNADA (ya la tomo un trabajo), RECHAZADA.
-- ---------------------------------------------------------------------
CREATE TABLE banco_idea (
    id_idea           INT AUTO_INCREMENT PRIMARY KEY,
    titulo            VARCHAR(200) NOT NULL,
    descripcion       TEXT         NOT NULL,
    objetivos         TEXT,
    id_linea          INT          NOT NULL,
    propuesto_por     INT          NOT NULL,
    origen            ENUM('DOCENTE','ESTUDIANTE','COMITE') NOT NULL,
    director_sugerido INT          NULL,
    palabras_clave    VARCHAR(200),
    periodo_academico VARCHAR(10)  NOT NULL,
    nivel             VARCHAR(20)  NOT NULL,
    estado            ENUM('PENDIENTE','DISPONIBLE','ASIGNADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
    CONSTRAINT fk_idea_linea     FOREIGN KEY (id_linea)          REFERENCES linea_investigacion(id_linea),
    CONSTRAINT fk_idea_propuesto FOREIGN KEY (propuesto_por)     REFERENCES usuario(id_usuario),
    CONSTRAINT fk_idea_director  FOREIGN KEY (director_sugerido) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. TRABAJO DE GRADO
-- ---------------------------------------------------------------------
CREATE TABLE trabajo_grado (
    id_trabajo            INT AUTO_INCREMENT PRIMARY KEY,
    titulo                VARCHAR(200) NOT NULL,
    resumen               TEXT,
    id_linea              INT NOT NULL,
    id_programa           INT NOT NULL,
    id_idea               INT NULL,
    modalidad             ENUM('MONOGRAFIA','INVESTIGACION','DESARROLLO_SOFTWARE') NOT NULL,
    fase_actual           INT NOT NULL DEFAULT 1,
    estado                ENUM('ACTIVO','CERRADO','CANCELADO') NOT NULL DEFAULT 'ACTIVO',
    fecha_aprob_propuesta DATE NULL,
    fecha_limite_entrega  DATE NULL,
    numero_prorrogas      INT NOT NULL DEFAULT 0,
    repositorio_url       VARCHAR(500) NULL,
    fecha_cierre          DATETIME NULL,
    cerrado_por           INT NULL,
    CONSTRAINT fk_tg_linea    FOREIGN KEY (id_linea)    REFERENCES linea_investigacion(id_linea),
    CONSTRAINT fk_tg_programa FOREIGN KEY (id_programa) REFERENCES programa_academico(id_programa),
    CONSTRAINT fk_tg_idea     FOREIGN KEY (id_idea)     REFERENCES banco_idea(id_idea),
    CONSTRAINT fk_tg_fase     FOREIGN KEY (fase_actual) REFERENCES fase(id_fase),
    CONSTRAINT fk_tg_cerrado  FOREIGN KEY (cerrado_por) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

-- Un trabajo tiene 1 o 2 estudiantes (la regla "maximo 2" y "un solo trabajo
-- activo por estudiante" se valida en las paginas JSP).
CREATE TABLE trabajo_grado_estudiante (
    id_trabajo            INT NOT NULL,
    id_usuario_estudiante INT NOT NULL,
    PRIMARY KEY (id_trabajo, id_usuario_estudiante),
    CONSTRAINT fk_tge_trabajo    FOREIGN KEY (id_trabajo)            REFERENCES trabajo_grado(id_trabajo),
    CONSTRAINT fk_tge_estudiante FOREIGN KEY (id_usuario_estudiante) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

-- Rol del docente DENTRO de un trabajo especifico (DIRECTOR o EVALUADOR).
-- La UNIQUE (id_trabajo, id_usuario_docente) hace cumplir la regla del
-- docente: quien dirige un proyecto no puede evaluarlo.
CREATE TABLE rol_docente (
    id_rol_docente    INT AUTO_INCREMENT PRIMARY KEY,
    id_trabajo        INT NOT NULL,
    id_usuario_docente INT NOT NULL,
    tipo_rol          ENUM('DIRECTOR','EVALUADOR') NOT NULL,
    activo            TINYINT NOT NULL DEFAULT 1,
    fecha_asignacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_rol_docente UNIQUE (id_trabajo, id_usuario_docente),
    CONSTRAINT fk_rd_trabajo FOREIGN KEY (id_trabajo)         REFERENCES trabajo_grado(id_trabajo),
    CONSTRAINT fk_rd_docente FOREIGN KEY (id_usuario_docente) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. ENTREGAS (documentos por URL), EVALUACIONES, PAGOS, PRORROGAS
-- ---------------------------------------------------------------------
CREATE TABLE entrega (
    id_entrega     INT AUTO_INCREMENT PRIMARY KEY,
    id_trabajo     INT NOT NULL,
    id_fase        INT NOT NULL,
    tipo_documento ENUM('FD124','FD125','COMPROBANTE_PAGO') NOT NULL,
    version        INT NOT NULL DEFAULT 1,
    estado         ENUM('PENDIENTE','APROBADA','APLAZADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
    fecha_entrega  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_entrega_version UNIQUE (id_trabajo, id_fase, tipo_documento, version),
    CONSTRAINT fk_en_trabajo FOREIGN KEY (id_trabajo) REFERENCES trabajo_grado(id_trabajo),
    CONSTRAINT fk_en_fase    FOREIGN KEY (id_fase)    REFERENCES fase(id_fase)
) ENGINE=InnoDB;

CREATE TABLE documento (
    id_documento  INT AUTO_INCREMENT PRIMARY KEY,
    id_entrega    INT NOT NULL,
    url_documento VARCHAR(500) NOT NULL,
    subido_por    INT NOT NULL,
    fecha_subida  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_doc_entrega FOREIGN KEY (id_entrega) REFERENCES entrega(id_entrega),
    CONSTRAINT fk_doc_usuario FOREIGN KEY (subido_por) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

-- concepto NULL = evaluacion asignada pero todavia sin responder.
CREATE TABLE evaluacion (
    id_evaluacion         INT AUTO_INCREMENT PRIMARY KEY,
    id_entrega            INT NOT NULL,
    id_usuario_evaluador  INT NOT NULL,
    rol_evaluador         ENUM('DIRECTOR','EVALUADOR') NOT NULL,
    concepto              ENUM('APROBADO','APLAZADO','RECHAZADO') NULL,
    observaciones         TEXT,
    fecha_limite_respuesta DATETIME NULL,
    fecha_evaluacion      DATETIME NULL,
    CONSTRAINT uq_evaluacion UNIQUE (id_entrega, id_usuario_evaluador, rol_evaluador),
    CONSTRAINT fk_ev_entrega   FOREIGN KEY (id_entrega)           REFERENCES entrega(id_entrega),
    CONSTRAINT fk_ev_evaluador FOREIGN KEY (id_usuario_evaluador) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

-- El pago se registra por ESTUDIANTE (no por trabajo). Solo se guarda la URL
-- del comprobante: el sistema no recibe archivos.
CREATE TABLE pago (
    id_pago               INT AUTO_INCREMENT PRIMARY KEY,
    id_trabajo            INT NOT NULL,
    id_usuario_estudiante INT NOT NULL,
    tipo_pago             ENUM('DERECHOS_GRADO','PRORROGA') NOT NULL,
    valor                 DECIMAL(12,2) NOT NULL,
    comprobante_url       VARCHAR(500) NOT NULL,
    estado                ENUM('PENDIENTE','VERIFICADO','RECHAZADO') NOT NULL DEFAULT 'PENDIENTE',
    fecha_pago            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pago_trabajo    FOREIGN KEY (id_trabajo)            REFERENCES trabajo_grado(id_trabajo),
    CONSTRAINT fk_pago_estudiante FOREIGN KEY (id_usuario_estudiante) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE prorroga (
    id_prorroga       INT AUTO_INCREMENT PRIMARY KEY,
    id_trabajo        INT NOT NULL,
    numero_prorroga   INT NOT NULL,
    id_pago           INT NOT NULL,
    fecha_solicitud   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado            ENUM('PENDIENTE','APROBADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
    aprobada_por      INT NULL,
    fecha_aprobacion  DATETIME NULL,
    nuevo_plazo_fecha DATE NULL,
    CONSTRAINT uq_prorroga_pago UNIQUE (id_pago),
    CONSTRAINT fk_pr_trabajo FOREIGN KEY (id_trabajo)   REFERENCES trabajo_grado(id_trabajo),
    CONSTRAINT fk_pr_pago    FOREIGN KEY (id_pago)      REFERENCES pago(id_pago),
    CONSTRAINT fk_pr_aprobo  FOREIGN KEY (aprobada_por) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. CALENDARIO E HISTORICO
-- ---------------------------------------------------------------------
CREATE TABLE calendario_academico (
    id_evento    INT AUTO_INCREMENT PRIMARY KEY,
    titulo       VARCHAR(150) NOT NULL,
    descripcion  VARCHAR(255),
    id_fase      INT NULL,
    tipo_evento  ENUM('INSCRIPCION','ENTREGA','EVALUACION','CIERRE','OTRO') NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin    DATE NOT NULL,
    CONSTRAINT fk_cal_fase FOREIGN KEY (id_fase) REFERENCES fase(id_fase)
) ENGINE=InnoDB;

CREATE TABLE historico_trabajo_grado (
    id_historico    INT AUTO_INCREMENT PRIMARY KEY,
    id_trabajo      INT NOT NULL,
    campo_modificado VARCHAR(60) NOT NULL,
    valor_anterior  VARCHAR(255),
    valor_nuevo     VARCHAR(255),
    modificado_por  INT NOT NULL,
    fecha           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_hist_trabajo FOREIGN KEY (id_trabajo)     REFERENCES trabajo_grado(id_trabajo),
    CONSTRAINT fk_hist_usuario FOREIGN KEY (modificado_por) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
--  DATOS INICIALES
--  Clave de TODOS los usuarios de prueba: 1234
--  Se guarda SHA2(CONCAT(sal, clave), 256), igual que calcula acceso.jsp.
-- =====================================================================
INSERT INTO rol (id_rol, nombre, descripcion) VALUES
(1,'ESTUDIANTE','Registra su idea, su pago y su anteproyecto'),
(2,'ADMINISTRADOR','Gestiona usuarios, catalogos y parametros'),
(3,'COMITE','Comite / Coordinacion de Trabajos de Grado'),
(4,'DOCENTE','Docente: actua como director o evaluador segun el trabajo');

INSERT INTO fase (id_fase, orden, nombre) VALUES
(1,1,'Idea y pago'),
(2,2,'Anteproyecto'),
(3,3,'Evaluacion del anteproyecto'),
(4,4,'Informe de trabajo de grado'),
(5,5,'Evaluacion del trabajo de grado'),
(6,6,'Cierre final');

INSERT INTO programa_academico (id_programa, nombre, facultad) VALUES
(1,'Tecnologia en Desarrollo de Sistemas Informaticos','Facultad de Ingenierias'),
(2,'Ingenieria de Sistemas','Facultad de Ingenierias'),
(3,'Ingenieria Electronica','Facultad de Ingenierias'),
(4,'Tecnologia en Electricidad Industrial','Facultad de Ingenierias'),
(5,'Contaduria Publica','Facultad de Ciencias Socioeconomicas'),
(6,'Administracion de Empresas','Facultad de Ciencias Socioeconomicas'),
(7,'Tecnologia en Gestion Empresarial','Facultad de Ciencias Socioeconomicas'),
(8,'Tecnologia en Operacion y Mantenimiento Electromecanico','Facultad de Ingenierias'),
(9,'Profesional en Gestion Ambiental','Facultad de Ciencias Naturales'),
(10,'Tecnologia en Seguridad y Salud en el Trabajo','Facultad de Ciencias Naturales');

INSERT INTO linea_investigacion (id_linea, nombre, descripcion) VALUES
(1,'Ingenieria de software','Desarrollo, calidad y arquitectura de software'),
(2,'Sistemas de informacion','Sistemas de informacion empresariales y web'),
(3,'Redes y telecomunicaciones','Diseno y administracion de redes'),
(4,'Inteligencia artificial','Aprendizaje automatico y analitica de datos'),
(5,'Seguridad informatica','Proteccion de la informacion y ciberseguridad'),
(6,'IoT y automatizacion','Sensores, control y sistemas embebidos'),
(7,'Gestion empresarial','Procesos y organizacion empresarial'),
(8,'Medio ambiente y sostenibilidad','Gestion ambiental y energias limpias');

INSERT INTO parametro_sistema (clave, valor, descripcion) VALUES
('valor_derechos_grado','525000','Valor de los derechos de grado por estudiante (COP)'),
('plazo_dias','180','Dias de plazo para entregar tras la aprobacion de la propuesta'),
('dias_minimos_informe','90','Dias minimos desde la aprobacion de la propuesta para radicar el informe'),
('max_prorrogas','2','Numero maximo de prorrogas por trabajo'),
('dias_aviso_prorroga','30','Dias restantes a partir de los cuales se puede solicitar prorroga'),
('dias_prorroga','90','Dias que suma cada prorroga aprobada al plazo del trabajo'),
('url_fd124','https://sistemastg.uts.edu.co/formatos/FD124','Enlace al formato FD124 (anteproyecto)'),
('url_fd125','https://sistemastg.uts.edu.co/formatos/FD125','Enlace al formato FD125 (informe final)'),
('url_fd129','https://sistemastg.uts.edu.co/formatos/FD129','Enlace al formato FD129 (acta de evaluacion)'),
('url_reglamento','https://www.uts.edu.co/sitio/reglamento-trabajos-de-grado/','Enlace al reglamento de trabajos de grado');

-- ---- Usuarios (salt fijo por usuario solo para el dato de prueba) ----
INSERT INTO usuario (id_usuario, correo, documento_identidad, nombres, apellidos, sal, clave_hash, estado) VALUES
(1,'admin@uts.edu.co','1000000001','Administrador','Sistema','s01a1b2c3d4e5f60',SHA2(CONCAT('s01a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(2,'comite@uts.edu.co','1000000002','Marcela','Ortiz Prada','s02a1b2c3d4e5f60',SHA2(CONCAT('s02a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(3,'ana.rojas@uts.edu.co','1000000003','Ana Maria','Rojas Duarte','s03a1b2c3d4e5f60',SHA2(CONCAT('s03a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(4,'carlos.mendez@uts.edu.co','1000000004','Carlos Andres','Mendez Ruiz','s04a1b2c3d4e5f60',SHA2(CONCAT('s04a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(5,'laura.gomez@uts.edu.co','1000000005','Laura Patricia','Gomez Vargas','s05a1b2c3d4e5f60',SHA2(CONCAT('s05a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(6,'julian.jaimes@uts.edu.co','1000000006','Julian Barney','Jaimes Rincon','s06a1b2c3d4e5f60',SHA2(CONCAT('s06a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(7,'pedro.sanchez@uts.edu.co','1000000007','Pedro Luis','Sanchez Mora','s07a1b2c3d4e5f60',SHA2(CONCAT('s07a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(8,'estudiante1@uts.edu.co','1098000001','Juan Camilo','Campo Velandia','s08a1b2c3d4e5f60',SHA2(CONCAT('s08a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(9,'estudiante2@uts.edu.co','1098000002','Dylan','Celis Aldana','s09a1b2c3d4e5f60',SHA2(CONCAT('s09a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(10,'estudiante3@uts.edu.co','1098000003','Valentina','Prada Nino','s10a1b2c3d4e5f60',SHA2(CONCAT('s10a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(11,'estudiante4@uts.edu.co','1098000004','Santiago','Rueda Cardenas','s11a1b2c3d4e5f60',SHA2(CONCAT('s11a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(12,'estudiante5@uts.edu.co','1098000005','Daniela','Mantilla Pinto','s12a1b2c3d4e5f60',SHA2(CONCAT('s12a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(13,'estudiante6@uts.edu.co','1098000006','Mateo','Arenas Lizarazo','s13a1b2c3d4e5f60',SHA2(CONCAT('s13a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(14,'estudiante7@uts.edu.co','1098000007','Sofia','Camacho Barajas','s14a1b2c3d4e5f60',SHA2(CONCAT('s14a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(15,'estudiante8@uts.edu.co','1098000008','Andres Felipe','Ortega Silva','s15a1b2c3d4e5f60',SHA2(CONCAT('s15a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(16,'estudiante9@uts.edu.co','1098000009','Camila','Reyes Ardila','s16a1b2c3d4e5f60',SHA2(CONCAT('s16a1b2c3d4e5f60','1234'),256),'ACTIVO'),
(17,'estudiante10@uts.edu.co','1098000010','Nicolas','Pabon Garcia','s17a1b2c3d4e5f60',SHA2(CONCAT('s17a1b2c3d4e5f60','1234'),256),'ACTIVO');

INSERT INTO usuario_rol (id_usuario, id_rol) VALUES
(1,2),(2,3),(3,4),(4,4),(5,4),(6,4),(7,4),
(8,1),(9,1),(10,1),(11,1),(12,1),(13,1),(14,1),(15,1),(16,1),(17,1);

-- ---- Banco de ideas ----
INSERT INTO banco_idea (id_idea, titulo, descripcion, objetivos, id_linea, propuesto_por, origen, director_sugerido, palabras_clave, periodo_academico, nivel, estado) VALUES
(1,'Sistema de gestion de inventario para tiendas de barrio','Aplicacion web para controlar entradas, salidas y existencias de una tienda de barrio.','Disenar, implementar y probar un sistema de inventario web.',2,8,'ESTUDIANTE',3,'inventario, tienda, web','2026-2','TECNOLOGIA','PENDIENTE'),
(2,'Plataforma de seguimiento de citas medicas con recordatorios','Sistema web para agendar y consultar citas en una IPS de nivel 1.','Construir un prototipo funcional con roles de paciente y medico.',1,3,'DOCENTE',3,'citas, salud, web','2026-2','TECNOLOGIA','ASIGNADA'),
(3,'Deteccion de fraudes en transacciones con aprendizaje automatico','Modelo de clasificacion para detectar transacciones atipicas.','Entrenar y evaluar un modelo de deteccion de anomalias.',4,4,'DOCENTE',4,'fraude, machine learning, datos','2026-2','PROFESIONAL','ASIGNADA'),
(4,'Red de sensores para monitoreo de cultivos de cacao','Nodos IoT que miden humedad y temperatura y reportan a un panel web.','Implementar una red de 3 nodos con panel de consulta.',6,5,'DOCENTE',5,'iot, sensores, agricultura','2026-2','TECNOLOGIA','ASIGNADA'),
(5,'Aplicacion movil para el control de rutas del transporte urbano','App que muestra rutas y horarios del transporte urbano de Bucaramanga.','Desarrollar una app con consulta de rutas en tiempo casi real.',1,3,'DOCENTE',3,'movil, transporte, rutas','2026-2','TECNOLOGIA','ASIGNADA'),
(6,'Auditoria de seguridad a una red inalambrica institucional','Evaluacion de vulnerabilidades de una red WiFi con herramientas libres.','Aplicar una metodologia de pruebas y proponer controles.',5,6,'DOCENTE',6,'seguridad, wifi, auditoria','2026-2','PROFESIONAL','ASIGNADA'),
(7,'Sistema de reservas para canchas sinteticas','Aplicacion web para reservar canchas y consultar disponibilidad.','Implementar reservas con calendario y control de pagos.',2,7,'DOCENTE',7,'reservas, canchas, web','2026-2','TECNOLOGIA','ASIGNADA'),
(8,'Chatbot de atencion al estudiante para la UTS','Asistente conversacional que responde preguntas frecuentes de bienestar.','Disenar un chatbot con base de conocimiento editable.',4,4,'DOCENTE',4,'chatbot, nlp, bienestar','2026-2','PROFESIONAL','ASIGNADA'),
(9,'Tablero de indicadores para la gestion de residuos solidos','Panel que consolida mediciones de residuos por sede.','Construir un tablero con graficas y reportes por periodo.',8,5,'DOCENTE',5,'residuos, indicadores, ambiente','2026-2','TECNOLOGIA','DISPONIBLE'),
(10,'Aplicacion web para la gestion de mantenimiento de equipos','Control de ordenes de mantenimiento preventivo y correctivo.','Implementar ordenes, tecnicos y reportes de historial.',2,6,'COMITE',NULL,'mantenimiento, ordenes, web','2026-2','TECNOLOGIA','DISPONIBLE'),
(11,'Analisis de datos abiertos de movilidad en Santander','Procesamiento de datos abiertos para identificar patrones de movilidad.','Limpiar, analizar y visualizar datos abiertos de movilidad.',4,3,'DOCENTE',3,'datos abiertos, movilidad, analitica','2026-2','PROFESIONAL','DISPONIBLE'),
(12,'Sistema domotico basico con microcontroladores','Control de iluminacion y accesos de una vivienda con ESP32.','Prototipar el control y una interfaz de monitoreo.',6,7,'DOCENTE',7,'domotica, esp32, iot','2026-2','TECNOLOGIA','DISPONIBLE'),
(13,'Portal de emprendimiento universitario','Portal para publicar y conectar emprendimientos de estudiantes.','Desarrollar un portal con perfiles y busqueda.',7,8,'ESTUDIANTE',NULL,'emprendimiento, portal','2026-2','TECNOLOGIA','PENDIENTE'),
(14,'Generador de horarios academicos con algoritmos geneticos','Optimizador de horarios sin cruces para programas academicos.','Implementar el algoritmo y una interfaz de consulta.',4,5,'DOCENTE',5,'horarios, algoritmos geneticos','2026-2','PROFESIONAL','DISPONIBLE'),
(15,'Sistema de control de acceso con tarjetas RFID','Registro de ingresos con lector RFID y reportes web.','Integrar lector, base de datos y panel web.',6,7,'DOCENTE',7,'rfid, acceso, iot','2026-2','TECNOLOGIA','RECHAZADA'),
(16,'Aplicativo para la gestion de la biblioteca de aula','Prestamo y devolucion de libros de una biblioteca de aula.','Registrar libros, prestamos y multas.',2,16,'ESTUDIANTE',NULL,'biblioteca, prestamos','2026-2','TECNOLOGIA','DISPONIBLE');

-- ---- Trabajos de grado en cada fase ----
-- Fechas relativas a hoy para que las alertas de plazo siempre se vean.
INSERT INTO trabajo_grado (id_trabajo, titulo, resumen, id_linea, id_programa, id_idea, modalidad, fase_actual, estado, fecha_aprob_propuesta, fecha_limite_entrega, numero_prorrogas, repositorio_url, fecha_cierre, cerrado_por) VALUES
(1,'Sistema de gestion de inventario para tiendas de barrio','Aplicacion web para controlar entradas, salidas y existencias.',2,1,1,'DESARROLLO_SOFTWARE',1,'ACTIVO',NULL,NULL,0,NULL,NULL,NULL),
(2,'Plataforma de seguimiento de citas medicas con recordatorios','Sistema web de citas para una IPS.',1,1,2,'DESARROLLO_SOFTWARE',2,'ACTIVO',NULL,NULL,0,NULL,NULL,NULL),
(3,'Deteccion de fraudes en transacciones con aprendizaje automatico','Modelo de clasificacion de transacciones.',4,2,3,'INVESTIGACION',3,'ACTIVO',DATE_ADD(CURDATE(), INTERVAL -5 DAY),DATE_ADD(CURDATE(), INTERVAL 175 DAY),0,NULL,NULL,NULL),
(4,'Red de sensores para monitoreo de cultivos de cacao','Nodos IoT con panel web.',6,4,4,'DESARROLLO_SOFTWARE',4,'ACTIVO',DATE_ADD(CURDATE(), INTERVAL -120 DAY),DATE_ADD(CURDATE(), INTERVAL 60 DAY),0,NULL,NULL,NULL),
(5,'Aplicacion movil para el control de rutas del transporte urbano','App de rutas y horarios.',1,1,5,'DESARROLLO_SOFTWARE',5,'ACTIVO',DATE_ADD(CURDATE(), INTERVAL -175 DAY),DATE_ADD(CURDATE(), INTERVAL 5 DAY),0,'https://github.com/uts-demo/app-rutas',NULL,NULL),
(6,'Auditoria de seguridad a una red inalambrica institucional','Pruebas de seguridad a la red WiFi.',5,2,6,'MONOGRAFIA',6,'ACTIVO',DATE_ADD(CURDATE(), INTERVAL -150 DAY),DATE_ADD(CURDATE(), INTERVAL 30 DAY),0,NULL,NULL,NULL),
(7,'Sistema de reservas para canchas sinteticas','Reservas web para canchas.',2,1,7,'DESARROLLO_SOFTWARE',6,'CERRADO',DATE_ADD(CURDATE(), INTERVAL -200 DAY),DATE_ADD(CURDATE(), INTERVAL -20 DAY),0,'https://github.com/uts-demo/reservas-canchas',DATE_ADD(NOW(), INTERVAL -3 DAY),2);

UPDATE banco_idea SET estado='ASIGNADA' WHERE id_idea IN (2,3,4,5,6,7);

INSERT INTO trabajo_grado_estudiante (id_trabajo, id_usuario_estudiante) VALUES
(1,8),(1,9),(2,10),(3,11),(4,12),(5,13),(6,14),(7,15);

INSERT INTO rol_docente (id_trabajo, id_usuario_docente, tipo_rol) VALUES
(2,3,'DIRECTOR'),(2,4,'EVALUADOR'),
(3,4,'DIRECTOR'),(3,5,'EVALUADOR'),
(4,5,'DIRECTOR'),(4,6,'EVALUADOR'),
(5,3,'DIRECTOR'),(5,7,'EVALUADOR'),
(6,6,'DIRECTOR'),(6,3,'EVALUADOR'),
(7,7,'DIRECTOR'),(7,5,'EVALUADOR');

-- ---- Pagos (uno por estudiante) ----
INSERT INTO pago (id_pago, id_trabajo, id_usuario_estudiante, tipo_pago, valor, comprobante_url, estado) VALUES
(1,1,8,'DERECHOS_GRADO',525000,'https://drive.google.com/file/d/recibo-est1','PENDIENTE'),
(2,1,9,'DERECHOS_GRADO',525000,'https://drive.google.com/file/d/recibo-est2','PENDIENTE'),
(3,2,10,'DERECHOS_GRADO',525000,'https://drive.google.com/file/d/recibo-est3','VERIFICADO'),
(4,3,11,'DERECHOS_GRADO',525000,'https://drive.google.com/file/d/recibo-est4','VERIFICADO'),
(5,4,12,'DERECHOS_GRADO',525000,'https://drive.google.com/file/d/recibo-est5','VERIFICADO'),
(6,5,13,'DERECHOS_GRADO',525000,'https://drive.google.com/file/d/recibo-est6','VERIFICADO'),
(7,6,14,'DERECHOS_GRADO',525000,'https://drive.google.com/file/d/recibo-est7','VERIFICADO'),
(8,7,15,'DERECHOS_GRADO',525000,'https://drive.google.com/file/d/recibo-est8','VERIFICADO'),
(9,5,13,'PRORROGA',525000,'https://drive.google.com/file/d/prorroga-est6','PENDIENTE');

INSERT INTO prorroga (id_prorroga, id_trabajo, numero_prorroga, id_pago, estado) VALUES
(1,5,1,9,'PENDIENTE');

-- ---- Entregas, documentos y evaluaciones ----
INSERT INTO entrega (id_entrega, id_trabajo, id_fase, tipo_documento, version, estado) VALUES
(1,2,2,'FD124',1,'PENDIENTE'),
(2,3,2,'FD124',1,'APROBADA'),
(3,4,2,'FD124',1,'APROBADA'),
(4,5,2,'FD124',1,'APROBADA'),
(5,5,4,'FD125',1,'APROBADA'),
(6,6,2,'FD124',1,'APROBADA'),
(7,6,4,'FD125',1,'APROBADA'),
(8,7,2,'FD124',1,'APROBADA'),
(9,7,4,'FD125',1,'APROBADA');

INSERT INTO documento (id_entrega, url_documento, subido_por) VALUES
(1,'https://drive.google.com/file/d/fd124-citas-medicas',10),
(2,'https://drive.google.com/file/d/fd124-fraudes',11),
(3,'https://drive.google.com/file/d/fd124-cacao',12),
(4,'https://drive.google.com/file/d/fd124-rutas',13),
(5,'https://drive.google.com/file/d/fd125-rutas',3),
(6,'https://drive.google.com/file/d/fd124-seguridad-wifi',14),
(7,'https://drive.google.com/file/d/fd125-seguridad-wifi',6),
(8,'https://drive.google.com/file/d/fd124-canchas',15),
(9,'https://drive.google.com/file/d/fd125-canchas',7);

-- Director aprueba (rol DIRECTOR) y evaluador responde o queda pendiente.
INSERT INTO evaluacion (id_entrega, id_usuario_evaluador, rol_evaluador, concepto, observaciones, fecha_limite_respuesta, fecha_evaluacion) VALUES
(2,4,'DIRECTOR','APROBADO','Propuesta bien definida.',NULL,DATE_ADD(NOW(), INTERVAL -5 DAY)),
(2,5,'EVALUADOR',NULL,NULL,DATE_ADD(NOW(), INTERVAL 7 DAY),NULL),
(3,5,'DIRECTOR','APROBADO','Alcance adecuado.',NULL,DATE_ADD(NOW(), INTERVAL -120 DAY)),
(3,6,'EVALUADOR','APROBADO','Cumple con los requisitos.',DATE_ADD(NOW(), INTERVAL -113 DAY),DATE_ADD(NOW(), INTERVAL -115 DAY)),
(4,3,'DIRECTOR','APROBADO','Aprobado.',NULL,DATE_ADD(NOW(), INTERVAL -175 DAY)),
(4,7,'EVALUADOR','APROBADO','Aprobado.',DATE_ADD(NOW(), INTERVAL -168 DAY),DATE_ADD(NOW(), INTERVAL -170 DAY)),
(5,3,'DIRECTOR','APROBADO','Informe completo.',NULL,DATE_ADD(NOW(), INTERVAL -2 DAY)),
(5,7,'EVALUADOR',NULL,NULL,DATE_ADD(NOW(), INTERVAL 5 DAY),NULL),
(6,6,'DIRECTOR','APROBADO','Aprobado.',NULL,DATE_ADD(NOW(), INTERVAL -150 DAY)),
(6,3,'EVALUADOR','APROBADO','Aprobado.',DATE_ADD(NOW(), INTERVAL -143 DAY),DATE_ADD(NOW(), INTERVAL -145 DAY)),
(7,6,'DIRECTOR','APROBADO','Informe aprobado.',NULL,DATE_ADD(NOW(), INTERVAL -20 DAY)),
(7,3,'EVALUADOR','APROBADO','Cumple.',DATE_ADD(NOW(), INTERVAL -10 DAY),DATE_ADD(NOW(), INTERVAL -12 DAY)),
(8,7,'DIRECTOR','APROBADO','Aprobado.',NULL,DATE_ADD(NOW(), INTERVAL -200 DAY)),
(8,5,'EVALUADOR','APROBADO','Aprobado.',DATE_ADD(NOW(), INTERVAL -193 DAY),DATE_ADD(NOW(), INTERVAL -195 DAY)),
(9,7,'DIRECTOR','APROBADO','Informe aprobado.',NULL,DATE_ADD(NOW(), INTERVAL -30 DAY)),
(9,5,'EVALUADOR','APROBADO','Cumple.',DATE_ADD(NOW(), INTERVAL -20 DAY),DATE_ADD(NOW(), INTERVAL -22 DAY));

-- ---- Calendario academico ----
INSERT INTO calendario_academico (titulo, descripcion, id_fase, tipo_evento, fecha_inicio, fecha_fin) VALUES
('Apertura de inscripcion de ideas','Registro de ideas y pago de derechos de grado',1,'INSCRIPCION',DATE_ADD(CURDATE(), INTERVAL -30 DAY),DATE_ADD(CURDATE(), INTERVAL 15 DAY)),
('Radicacion de anteproyectos','Entrega del FD124 al director',2,'ENTREGA',DATE_ADD(CURDATE(), INTERVAL 15 DAY),DATE_ADD(CURDATE(), INTERVAL 45 DAY)),
('Evaluacion de anteproyectos','Revision del evaluador y cierre del comite',3,'EVALUACION',DATE_ADD(CURDATE(), INTERVAL 45 DAY),DATE_ADD(CURDATE(), INTERVAL 60 DAY)),
('Radicacion de informes finales','Registro del FD125 por el director',4,'ENTREGA',DATE_ADD(CURDATE(), INTERVAL 90 DAY),DATE_ADD(CURDATE(), INTERVAL 150 DAY)),
('Evaluacion de informes finales','Concepto del evaluador y revision del comite',5,'EVALUACION',DATE_ADD(CURDATE(), INTERVAL 150 DAY),DATE_ADD(CURDATE(), INTERVAL 165 DAY)),
('Cierre de trabajos de grado','Cierre definitivo en la plataforma',6,'CIERRE',DATE_ADD(CURDATE(), INTERVAL 165 DAY),DATE_ADD(CURDATE(), INTERVAL 180 DAY)),
('Sustentaciones (fuera del sistema)','Las sustentaciones y el tramite de biblioteca se gestionan por fuera del software',NULL,'OTRO',DATE_ADD(CURDATE(), INTERVAL 120 DAY),DATE_ADD(CURDATE(), INTERVAL 170 DAY)),
('Semana de socializacion de proyectos','Muestra institucional de trabajos de grado',NULL,'OTRO',DATE_ADD(CURDATE(), INTERVAL 100 DAY),DATE_ADD(CURDATE(), INTERVAL 104 DAY));

-- ---- Historico de cambios de estado ----
INSERT INTO historico_trabajo_grado (id_trabajo, campo_modificado, valor_anterior, valor_nuevo, modificado_por) VALUES
(2,'fase_actual','1','2',2),
(3,'fase_actual','2','3',4),
(4,'fase_actual','3','4',2),
(5,'fase_actual','4','5',3),
(6,'fase_actual','5','6',2),
(7,'estado','ACTIVO','CERRADO',2);

-- =====================================================================
--  CONSULTAS DE VERIFICACION (opcionales)
-- =====================================================================
-- SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='trabajos_grado_uts';   -- debe dar 18
-- SELECT u.correo, GROUP_CONCAT(r.nombre) roles FROM usuario u
--   JOIN usuario_rol ur ON ur.id_usuario=u.id_usuario JOIN rol r ON r.id_rol=ur.id_rol GROUP BY u.correo;
-- SELECT t.id_trabajo, f.nombre fase, t.estado FROM trabajo_grado t JOIN fase f ON f.id_fase=t.fase_actual;

-- =====================================================================
--  5 CONSULTAS DE REPORTE (se ejecutan en web/comite/reportes.jsp)
-- =====================================================================
-- 1) INNER JOIN de 4 tablas: trabajos activos con programa, linea y fase
-- SELECT t.id_trabajo, t.titulo, p.nombre programa, l.nombre linea, f.nombre fase
--   FROM trabajo_grado t
--   INNER JOIN programa_academico p ON p.id_programa = t.id_programa
--   INNER JOIN linea_investigacion l ON l.id_linea = t.id_linea
--   INNER JOIN fase f ON f.id_fase = t.fase_actual
--  WHERE t.estado = 'ACTIVO';
-- 2) INNER JOIN de 4 tablas: carga de cada docente (director/evaluador por trabajo)
-- SELECT CONCAT(u.nombres,' ',u.apellidos) docente, rd.tipo_rol, t.id_trabajo, t.titulo, f.orden fase
--   FROM rol_docente rd
--   INNER JOIN usuario u ON u.id_usuario = rd.id_usuario_docente
--   INNER JOIN trabajo_grado t ON t.id_trabajo = rd.id_trabajo
--   INNER JOIN fase f ON f.id_fase = t.fase_actual
--  WHERE rd.activo = 1 AND t.estado = 'ACTIVO';
-- 3) Relacion N:M: estudiantes y trabajos (tabla puente trabajo_grado_estudiante)
-- SELECT CONCAT(u.nombres,' ',u.apellidos) estudiante, t.id_trabajo, t.titulo
--   FROM trabajo_grado_estudiante e
--   INNER JOIN usuario u ON u.id_usuario = e.id_usuario_estudiante
--   INNER JOIN trabajo_grado t ON t.id_trabajo = e.id_trabajo;
-- 4) LEFT JOIN: ideas del banco con o sin trabajo asignado
-- SELECT i.id_idea, i.titulo, i.estado, t.id_trabajo
--   FROM banco_idea i LEFT JOIN trabajo_grado t ON t.id_idea = i.id_idea;
-- 5) GROUP BY + HAVING: trabajos por programa
-- SELECT p.nombre, COUNT(*) trabajos, SUM(t.estado='CERRADO') cerrados, AVG(t.fase_actual) fase_promedio
--   FROM trabajo_grado t INNER JOIN programa_academico p ON p.id_programa = t.id_programa
--  GROUP BY p.id_programa, p.nombre HAVING COUNT(*) >= 1;
