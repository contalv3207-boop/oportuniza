const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

async function requireUser(req, res, next) {
  const userId = req.headers['x-user-id'] || req.query.userId;
  if (!userId) {
    return res.status(400).json({ error: 'User ID is required in header x-user-id or query userId' });
  }

  const [rows] = await pool.query('SELECT id, name, email FROM users WHERE id = ?', [userId]);
  if (!rows.length) {
    return res.status(404).json({ error: 'User not found' });
  }

  req.user = rows[0];
  next();
}

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/api/register', async (req, res) => {
  const { name, email, password } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email and password are required.' });
  }

  const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
  if (existing.length) {
    return res.status(409).json({ error: 'Este e-mail já está cadastrado.' });
  }

  const [result] = await pool.query(
    'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
    [name, email, password]
  );

  res.json({ id: result.insertId, name, email });
});

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email e senha são obrigatórios.' });
  }

  const [rows] = await pool.query('SELECT id, name, email, password FROM users WHERE email = ?', [email]);
  const user = rows[0];
  if (!user || user.password !== password) {
    return res.status(401).json({ error: 'E-mail ou senha incorretos.' });
  }

  res.json({ id: user.id, name: user.name, email: user.email });
});

app.get('/api/profile', requireUser, async (req, res) => {
  const [rows] = await pool.query('SELECT profession, experience, city, bio, skills, photo FROM profiles WHERE user_id = ?', [req.user.id]);
  const profile = rows[0] || null;
  res.json({ user: req.user, profile });
});

app.post('/api/profile', requireUser, async (req, res) => {
  const { profession, experience, city, bio, skills, photo } = req.body;
  const [existing] = await pool.query('SELECT id FROM profiles WHERE user_id = ?', [req.user.id]);

  if (existing.length) {
    await pool.query(
      'UPDATE profiles SET profession = ?, experience = ?, city = ?, bio = ?, skills = ?, photo = ? WHERE user_id = ?',
      [profession, experience, city, bio, skills, photo, req.user.id]
    );
  } else {
    await pool.query(
      'INSERT INTO profiles (user_id, profession, experience, city, bio, skills, photo) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [req.user.id, profession, experience, city, bio, skills, photo]
    );
  }

  res.json({ success: true });
});

app.get('/api/favorites', requireUser, async (req, res) => {
  const [rows] = await pool.query('SELECT id, type, item_id AS itemId, title FROM favorites WHERE user_id = ?', [req.user.id]);
  res.json(rows);
});

app.post('/api/favorites', requireUser, async (req, res) => {
  const { type, itemId, title } = req.body;
  if (!type || !itemId || !title) {
    return res.status(400).json({ error: 'type, itemId e title são obrigatórios.' });
  }

  await pool.query(
    'INSERT INTO favorites (user_id, type, item_id, title) VALUES (?, ?, ?, ?)',
    [req.user.id, type, itemId, title]
  );

  res.json({ success: true });
});

app.delete('/api/favorites/:type/:itemId', requireUser, async (req, res) => {
  const { type, itemId } = req.params;
  await pool.query('DELETE FROM favorites WHERE user_id = ? AND type = ? AND item_id = ?', [req.user.id, type, itemId]);
  res.json({ success: true });
});

app.get('/api/applications', requireUser, async (req, res) => {
  const [rows] = await pool.query('SELECT id, job_id AS jobId, title, company, date FROM applications WHERE user_id = ?', [req.user.id]);
  res.json(rows);
});

app.post('/api/applications', requireUser, async (req, res) => {
  const { jobId, title, company } = req.body;
  if (!jobId || !title || !company) {
    return res.status(400).json({ error: 'jobId, title e company são obrigatórios.' });
  }

  await pool.query(
    'INSERT INTO applications (user_id, job_id, title, company, date) VALUES (?, ?, ?, ?, ?)',
    [req.user.id, jobId, title, company, new Date().toISOString().slice(0, 10)]
  );

  res.json({ success: true });
});

app.delete('/api/applications/:id', requireUser, async (req, res) => {
  await pool.query('DELETE FROM applications WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
  res.json({ success: true });
});

app.get('/api/messages', requireUser, async (req, res) => {
  const [rows] = await pool.query('SELECT id, sender, context, title, body, time, `read` FROM messages WHERE user_id = ?', [req.user.id]);
  res.json(rows);
});

app.post('/api/messages', requireUser, async (req, res) => {
  const { sender, context, title, body, time, read } = req.body;
  if (!sender || !context || !body) {
    return res.status(400).json({ error: 'sender, context e body são obrigatórios.' });
  }

  await pool.query(
    'INSERT INTO messages (user_id, sender, context, title, body, time, `read`) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [req.user.id, sender, context, title || '', body, time || new Date().toLocaleString('pt-BR'), read ? 1 : 0]
  );

  res.json({ success: true });
});

app.patch('/api/messages/:id/read', requireUser, async (req, res) => {
  await pool.query('UPDATE messages SET `read` = 1 WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
  res.json({ success: true });
});

const port = process.env.PORT || 4000;
app.listen(port, () => {
  console.log(`Backend rodando em http://localhost:${port}`);
});
