# Backend MySQL para Oportuniza

Este backend usa Node.js, Express e MySQL para armazenar usuários, perfil, favoritos, candidaturas e mensagens.

## Passos para usar

1. Instale dependências:

   npm install

2. Configure o arquivo `.env` com os dados do MySQL. Use `.env.example` como modelo.

3. Crie a base de dados e tabelas no MySQL.

Opções:

- Executar o SQL manualmente usando o arquivo `backend/schema.sql`.
- Ou usar o script Node fornecido para inicializar o banco automaticamente:

```bash
cd backend
npm install
npm run init-db
```

O `init-db` executará `backend/schema.sql` usando as credenciais do `.env`.

4. Execute o backend:

   npm run dev

5. Use os endpoints em seu front-end.

## Endpoints principais

- `POST /api/register`
- `POST /api/login`
- `GET /api/profile` (use header `x-user-id` ou query `?userId=`)
- `POST /api/profile`
- `GET /api/favorites`
- `POST /api/favorites`
- `DELETE /api/favorites/:type/:itemId`
- `GET /api/applications`
- `POST /api/applications`
- `DELETE /api/applications/:id`
- `GET /api/messages`
- `POST /api/messages`
- `PATCH /api/messages/:id/read`

## Integração com front-end

No `script.js`, você deve substituir o uso de `localStorage` por chamadas `fetch` ao backend.
Por exemplo:

```js
const response = await fetch('http://localhost:4000/api/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password })
});
```

> Para produção, adicione autenticação adequada com tokens JWT e evite enviar a senha em texto claro.
