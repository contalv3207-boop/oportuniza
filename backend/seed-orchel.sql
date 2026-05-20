USE orchel;

-- Inserir usuário de teste
INSERT INTO users (name, email, password) VALUES
('Teste', 'teste@example.com', '1234');
SET @uid = LAST_INSERT_ID();

-- Perfil de exemplo
INSERT INTO profiles (user_id, profession, experience, city, bio, skills, photo) VALUES
(@uid, 'Desenvolvedor Full Stack', '3', 'São Paulo', 'Perfil de teste criado pelo seed.', 'JavaScript, Node.js, SQL', '');

-- Favoritos de exemplo
INSERT INTO favorites (user_id, type, item_id, title) VALUES
(@uid, 'job', 1001, 'Desenvolvedor Frontend'),
(@uid, 'course', 2001, 'React do Zero');

-- Candidaturas de exemplo
INSERT INTO applications (user_id, job_id, title, company, date) VALUES
(@uid, 1001, 'Desenvolvedor Frontend', 'Empresa X', CURDATE());

-- Mensagens de exemplo
INSERT INTO messages (user_id, sender, context, title, body, time, `read`) VALUES
(@uid, 'bot', 'general', 'Bem-vindo', 'Obrigado por testar o schema orchel. Boa sorte!', NOW(), 0),
(@uid, 'user', 'general', 'Dúvida', 'Como me inscrevo na vaga?', NOW(), 1);

-- Verificações rápidas
SELECT 'Users' AS item, COUNT(*) AS cnt FROM users;
SELECT 'Profiles' AS item, COUNT(*) AS cnt FROM profiles;
SELECT 'Favorites' AS item, COUNT(*) AS cnt FROM favorites;
SELECT 'Applications' AS item, COUNT(*) AS cnt FROM applications;
SELECT 'Messages' AS item, COUNT(*) AS cnt FROM messages;
