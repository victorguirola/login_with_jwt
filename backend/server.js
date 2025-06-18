// backend/server.js
require('dotenv').config(); // Carga las variables de entorno desde .env

const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise'); // Para MySQL
const bcrypt = require('bcryptjs'); // Para hashear contraseñas
const jwt = require('jsonwebtoken'); // Para JWT

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'super_secreto_por_defecto_no_usar_en_produccion';

// --- Configuración de la Base de Datos MySQL ---
const dbConfig = {
  host: process.env.MYSQL_HOST || 'localhost',
  user: process.env.MYSQL_USER || 'devuser',
  password: process.env.MYSQL_PASSWORD || 'devpass',
  database: process.env.MYSQL_DATABASE || 'my_auth_db',
  host: process.env.MYSQL_HOST,
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD,
  database: process.env.MYSQL_DATABASE,
  port: process.env.MYSQL_PORT ? parseInt(process.env.MYSQL_PORT) : 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

let pool;

async function connectToDatabase() {
  try {
    pool = await mysql.createPool(dbConfig);
    await pool.execute('SELECT 1 + 1 AS solution');
    console.log('Conexión a MySQL establecida con éxito.');
  } catch (err) {
    console.error('Error al conectar a MySQL:', err.message);
    process.exit(1); // Sale de la aplicación si no puede conectar a la DB
  }
}

// --- Middleware ---
app.use(cors());
app.use(express.json()); // Permite a Express leer cuerpos JSON
app.use(express.urlencoded({ extended: true }));

app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// --- Middleware de Autenticación JWT ---
const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1]; // Extrae el token "Bearer TOKEN"

    jwt.verify(token, JWT_SECRET, (err, user) => {
      if (err) {
        // Token inválido o expirado
        return res.status(403).json({ message: 'Token inválido o expirado.' });
      }
      req.user = user; // Almacena el payload del token en req.user
      next(); // Pasa al siguiente middleware/endpoint
    });
  } else {
    res.status(401).json({ message: 'Autenticación requerida. Token no proporcionado.' });
  }
};

// --- ENDPOINTS ---

// GET / - Ruta raíz de la API
app.get('/', (req, res) => {
  res.send('API de Autenticación con Express.js y MySQL.');
});

// POST /api/register - Registro de usuario
app.post('/api/register', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Nombre de usuario y contraseña son obligatorios.' });
  }

  try {
    // Verificar si el usuario ya existe
    const [existingUsers] = await pool.execute('SELECT id FROM users WHERE username = ?', [username]);
    if (existingUsers.length > 0) {
      return res.status(409).json({ message: 'El nombre de usuario ya existe.' });
    }

    // Hashear la contraseña
    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    // Guardar usuario en la DB
    const [result] = await pool.execute(
      'INSERT INTO users (username, password_hash) VALUES (?, ?)',
      [username, password_hash]
    );

    res.status(201).json({ message: 'Usuario registrado con éxito.', userId: result.insertId });
  } catch (error) {
    console.error('Error al registrar usuario:', error);
    res.status(500).json({ message: 'Error interno del servidor al registrar usuario.' });
  }
});

// POST /api/login - Inicio de sesión de usuario
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: 'Nombre de usuario y contraseña son obligatorios.' });
  }

  try {
    // Buscar usuario
    const [users] = await pool.execute('SELECT * FROM users WHERE username = ?', [username]);
    const user = users[0];

    if (!user) {
      return res.status(401).json({ message: 'Credenciales inválidas.' });
    }

    // Comparar contraseña hasheada
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ message: 'Credenciales inválidas.' });
    }

    // Generar JWT
    const token = jwt.sign(
      { userId: user.id, username: user.username },
      JWT_SECRET,
      { expiresIn: '1h' } // Token expira en 1 hora
    );

    res.status(200).json({ message: 'Inicio de sesión exitoso.', token });
  } catch (error) {
    console.error('Error al iniciar sesión:', error);
    res.status(500).json({ message: 'Error interno del servidor al iniciar sesión.' });
  }
});

// GET /api/protected - Ruta protegida por JWT
app.get('/api/protected', authenticateJWT, (req, res) => {
  // Si llegamos aquí, el token es válido
  res.status(200).json({
    message: `¡Bienvenido ${req.user.username}! Has accedido a una ruta protegida.`,
    userId: req.user.userId
  });
});

// --- Manejo de rutas no encontradas (404) ---
app.use((req, res) => {
  res.status(404).send('Ruta no encontrada.');
});

// --- INICIAR SERVIDOR ---
async function startServer() {
  await connectToDatabase();
  app.listen(PORT, () => {
    console.log(`Servidor Express ejecutándose en http://localhost:${PORT}`);
    console.log('Endpoints: /api/register, /api/login, /api/protected');
  });
}

startServer();