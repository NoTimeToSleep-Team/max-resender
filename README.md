# max-resender
Resender For MAX Messenger
Пересыльщик сообщений Мессенджера MAX
Eng:
`project-max` — self-hosted relay for delivering messages from MAX to Telegram and a web app on React/PWA.

## What is already implemented

- backend on `Fastify`;
- storing messages and durable queue in `SQLite`;
- idempotent ingest via `POST /api/mock/messages`;
- realtime-stream to web via `SSE` (`/api/stream/messages`);
- React + Vite frontend with dark adaptive message feed;
- PWA shell: `manifest`, `service worker`, installable frontend;
- storing `web push` subscriptions in the database;
- Telegram worker with `retry`, `backoff`, and startup recovery;
- structured logging, `healthcheck`, root `npm test`.

## What's left

- real MAX adapter instead of mock ingest;
- real web push sending via `VAPID` private key;
- production deployment on Raspberry Pi;
- final operational bindings and backup/restore runbook.

## Stack

- Backend: `Node.js 24`, `TypeScript`, `Fastify`
- Frontend: `React 19`, `Vite`
- Storage and queue: `SQLite`
- Realtime: `SSE`
- Push shell: `PWA + service worker`
- Process supervision target: `systemd`
- Reverse proxy target: `nginx`

## Structure

- `src/backend` — API, ingest, durable queue, Telegram worker
- `src/frontend` — React/Vite client, PWA shell, push onboarding
- `src/shared` — общие схемы и типы
- `tests` — automated smoke/unit tests
- `deploy` — заготовки `systemd` и `nginx`
- `docs` — архитектура, аудит и handoff-заметки

## Local run

1. Install dependencies:

```bash
npm install
```

2. If necessary, create a `.env` based on the `.env.example`.

3. Run the backend:

```bash
npm run dev:backend
```

4. In a separate terminal, run the frontend:

```bash
npm run dev:frontend
```

5. Open `http://127.0.0.1:5173`.

## Basic commands

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

## Environment variables

See `.env.example`.

Key variables:

- `BACKEND_HOST`, `BACKEND_PORT`
- `MAX_BRIDGE_TOKEN`
- `DATABASE_PATH`
- `DELIVERY_BASE_BACKOFF_MS`, `DELIVERY_MAX_BACKOFF_MS`, `DELIVERY_LOCK_TIMEOUT_MS`, `DELIVERY_MAX_ATTEMPTS`
- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `TELEGRAM_API_BASE_URL`
- `TELEGRAM_WORKER_POLL_MS`, `TELEGRAM_BATCH_SIZE`
- `WEB_PUSH_PUBLIC_KEY`, `WEB_PUSH_PRIVATE_KEY`, `WEB_PUSH_SUBJECT`
- `LOG_LEVEL`

Important:

- without `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`, the Telegram worker remains disabled;
- without a complete set of `WEB_PUSH_PUBLIC_KEY` + `WEB_PUSH_PRIVATE_KEY` + `WEB_PUSH_SUBJECT`, the push worker remains disabled;
- without `WEB_PUSH_PUBLIC_KEY`, the frontend will honestly show that the backend push config is not yet ready;
- for real web push, you will still need HTTPS and a private VAPID key on the server side.

## HTTP API

### Service routes

- `GET /` — краткий runtime summary
- `GET /health` — healthcheck

### Messages

- `GET /api/messages?limit=50` — последние сообщения из БД
- `GET /api/stream/messages` — `SSE` stream (`stream.ready`, `message.created`, `message.updated`)
- `POST /api/mock/messages` — local mock ingest

### MAX bridge

- `POST /api/bridge/max/messages` — secure bridge ingest via `x-bridge-token`

See also `docs/max-bridge-contract.md`.

Example of mock ingest:

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

## Current queue behavior

- durable jobs are created for `web`, `telegram`, and `push` when a new message is received;
- the queue is idempotent and does not create duplicate jobs;
- the Telegram worker automatically polls pending jobs;
- on error, `retry with backoff` is enabled;
- stale locks are restored on backend startup.

## Limitations of the current version

- MAX source is currently mock-only;
- `node:sqlite` in the current Node 24 still gives an `ExperimentalWarning`;
- the frontend currently shows a single aggregated status from the `messages` table, rather than a separate status matrix for all channels;
- service worker and manifest are already present, but real push notification delivery is not yet enabled without a private VAPID key and a push sender.

## Deployment templates

- `deploy/systemd/project-max-backend.service`
- `deploy/nginx/project-max.conf`
- `docs/rpi-access.md`

These are templates for Raspberry Pi, not a confirmed live deployment.

## Project documents

- `docs/architecture.md`
- `docs/max-bridge-contract.md`
- `docs/technical-audit.md`
- `docs/deployment-checklist.md`
- `docs/runbook.md`
- `PLAN.md`
- `docs/rpi-access.md`


Rus:
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
