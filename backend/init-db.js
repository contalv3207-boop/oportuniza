const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function run() {
  const file = path.join(__dirname, 'schema.sql');
  if (!fs.existsSync(file)) {
    console.error('schema.sql not found in backend/');
    process.exit(1);
  }

  const sql = fs.readFileSync(file, 'utf8');

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    port: process.env.DB_PORT ? Number(process.env.DB_PORT) : 3306,
    multipleStatements: true
  });

  try {
    console.log('Running schema.sql...');
    await connection.query(sql);
    console.log('Database schema created/updated successfully.');
  } catch (err) {
    console.error('Error running schema:', err.message);
    process.exit(1);
  } finally {
    await connection.end();
  }
}

run();
