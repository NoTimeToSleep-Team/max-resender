# project-max

`project-max` — self-hosted relay для доставки сообщений из MAX в Telegram и веб-приложение на React/PWA.

## Что уже реализовано

- backend на `Fastify`;
- хранение сообщений и durable queue в `SQLite`;
- idempotent ingest через `POST /api/mock/messages`;
- realtime-поток в веб через `SSE` (`/api/stream/messages`);
- React + Vite frontend с тёмной адаптивной лентой сообщений;
- PWA shell: `manifest`, `service worker`, installable frontend;
- хранение `web push` subscriptions в БД;
- Telegram worker с `retry`, `backoff` и startup recovery;
- structured logging, `healthcheck`, root `npm test`.

## Что ещё остаётся

- реальный MAX adapter вместо mock ingest;
- реальная отправка web push через `VAPID` private key;
- production deployment на Raspberry Pi;
- финальная эксплуатационная обвязка и backup/restore runbook.

## Стек

- Backend: `Node.js 24`, `TypeScript`, `Fastify`
- Frontend: `React 19`, `Vite`
- Storage and queue: `SQLite`
- Realtime: `SSE`
- Push shell: `PWA + service worker`
- Process supervision target: `systemd`
- Reverse proxy target: `nginx`

## Структура

- `src/backend` — API, ingest, durable queue, Telegram worker
- `src/frontend` — React/Vite client, PWA shell, push onboarding
- `src/shared` — общие схемы и типы
- `tests` — automated smoke/unit tests
- `deploy` — заготовки `systemd` и `nginx`
- `docs` — архитектура, аудит и handoff-заметки

## Локальный запуск

1. Установить зависимости:

```bash
npm install
```

2. При необходимости создать `.env` на основе `.env.example`.

3. Запустить backend:

```bash
npm run dev:backend
```

4. В отдельном терминале запустить frontend:

```bash
npm run dev:frontend
```

5. Открыть `http://127.0.0.1:5173`.

## Основные команды

```bash
npm run typecheck
npm run build
npm test
npm run generate:vapid
npm run backup:db -- ./backups/project-max.sqlite
npm run restore:db -- ./backups/project-max.sqlite --force
npm run bridge:send -- --file ./message.json
npm run verify:prod-env -- --file ./.env.production.example --allow-placeholders
```

## Переменные окружения

Смотри `.env.example`.

Ключевые переменные:

- `BACKEND_HOST`, `BACKEND_PORT`
- `MAX_BRIDGE_TOKEN`
- `DATABASE_PATH`
- `DELIVERY_BASE_BACKOFF_MS`, `DELIVERY_MAX_BACKOFF_MS`, `DELIVERY_LOCK_TIMEOUT_MS`, `DELIVERY_MAX_ATTEMPTS`
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `TELEGRAM_API_BASE_URL`
- `TELEGRAM_WORKER_POLL_MS`, `TELEGRAM_BATCH_SIZE`
- `WEB_PUSH_PUBLIC_KEY`, `WEB_PUSH_PRIVATE_KEY`, `WEB_PUSH_SUBJECT`
- `LOG_LEVEL`

Важно:

- без `TELEGRAM_BOT_TOKEN` и `TELEGRAM_CHAT_ID` Telegram worker остаётся выключенным;
- без полного набора `WEB_PUSH_PUBLIC_KEY` + `WEB_PUSH_PRIVATE_KEY` + `WEB_PUSH_SUBJECT` push worker остаётся выключенным;
- без `WEB_PUSH_PUBLIC_KEY` frontend честно покажет, что backend push config ещё не готов;
- для реального web push всё равно потребуется HTTPS и private VAPID key на стороне сервера.

## HTTP API

### Service routes

- `GET /` — краткий runtime summary
- `GET /health` — healthcheck

### Messages

- `GET /api/messages?limit=50` — последние сообщения из БД
- `GET /api/stream/messages` — `SSE` stream (`stream.ready`, `message.created`, `message.updated`)
- `POST /api/mock/messages` — локальный mock ingest

### MAX bridge

- `POST /api/bridge/max/messages` — защищённый bridge ingest через `x-bridge-token`

Смотри также `docs/max-bridge-contract.md`.

Пример mock ingest:

```json
{
  "source": "max-mock",
  "sourceChatId": "local-dev",
  "sourceMessageId": "demo-1",
  "author": { "username": "@alice" },
  "text": "Hello from mock ingest",
  "attachments": [],
  "sentAt": "2026-04-22T20:00:00.000Z",
  "rawPayload": { "channel": "mock" }
}
```

### Push

- `GET /api/push/config`
- `GET /api/push/subscriptions`
- `POST /api/push/subscriptions`

## Текущее поведение очереди

- при новом сообщении создаются durable jobs для `web`, `telegram`, `push`;
- queue идемпотентна и не плодит дубликаты;
- Telegram worker автоматически опрашивает pending jobs;
- при ошибке включается `retry with backoff`;
- stale locks восстанавливаются на старте backend.

## Ограничения текущей версии

- источник MAX пока mock-only;
- `node:sqlite` в текущем Node 24 всё ещё даёт `ExperimentalWarning`;
- frontend пока показывает один агрегированный статус из таблицы `messages`, а не отдельную матрицу статусов по всем каналам;
- service worker и manifest уже есть, но реальная доставка push-уведомлений ещё не подключена без private VAPID key и отправителя push.

## Deployment заготовки

- `deploy/systemd/project-max-backend.service`
- `deploy/nginx/project-max.conf`
- `docs/rpi-access.md`

Это шаблоны для Raspberry Pi, а не подтверждённый live deployment.

## Документы проекта

- `docs/architecture.md`
- `docs/max-bridge-contract.md`
- `docs/technical-audit.md`
- `docs/deployment-checklist.md`
- `docs/runbook.md`
- `PLAN.md`
- `docs/rpi-access.md`
