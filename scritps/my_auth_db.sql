-- Conéctate a tu servidor MySQL (ej. usando MySQL Workbench o línea de comandos)
-- Crea la base de datos si no existe
CREATE DATABASE IF NOT EXISTS my_auth_db;

-- Usa la base de datos
USE my_auth_db;

-- Crea la tabla users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Opcional: Puedes insertar un usuario de prueba (la contraseña 'password123' hasheada)
-- La contraseña 'password123' hasheada con bcrypt podría ser algo como:
-- $2a$10$EXAMPLEHASH.C2lWJ/V.y2w7z.Q/9o2k9wQk.s1X1mXoY.x.x
-- Genera una con bcrypt.hashSync('password123', 10) en un script Node.js si quieres.
-- No insertaremos aquí para que el proceso de registro lo cree.