# Runbook

Короткий эксплуатационный runbook для локального и Raspberry Pi запуска.

## Базовые команды

```bash
npm install
npm run typecheck
npm run build
npm test
```

## Dev запуск

Backend:

```bash
npm run dev:backend
```

Frontend:

```bash
npm run dev:frontend
```

## Проверка сервиса

- `GET /health`
- `GET /api/messages`
- `GET /api/stream/messages`
- `POST /api/bridge/max/messages` при настроенном `MAX_BRIDGE_TOKEN`

Если настроен `ADMIN_API_TOKEN`:

- `GET /api/admin/ops/summary`
- `GET /api/admin/ops/queue/jobs`

## Backup базы

```bash
npm run backup:db -- ./backups/project-max-YYYYMMDD.sqlite
```

С перезаписью:

```bash
npm run backup:db -- ./backups/project-max-latest.sqlite --overwrite
```

## Restore базы

Останови backend перед восстановлением.

```bash
npm run restore:db -- ./backups/project-max-YYYYMMDD.sqlite --force
```

## Cleanup истории доставок

По умолчанию удаляет `completed/failed` jobs и attempts старше `7` дней:

```bash
npm run prune:queue
```

За последние `30` дней:

```bash
npm run prune:queue -- 30
```

## VAPID ключи

```bash
npm run generate:vapid
```

Подставь результат в `.env`:

- `WEB_PUSH_PUBLIC_KEY`
- `WEB_PUSH_PRIVATE_KEY`
- `WEB_PUSH_SUBJECT`

## Telegram smoke checks

Для живой проверки должны быть заданы:

- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`

После этого отправь mock сообщение:

```bash
POST /api/mock/messages
```

И проверь:

- статус сообщения в `/api/messages`
- или `/api/admin/ops/summary`

## Что делать при проблемах

1. Проверить `GET /health`
2. Проверить `npm run typecheck`
3. Проверить `npm test`
4. Проверить `.env`
5. Проверить admin endpoints с `x-admin-token`
6. Проверить bridge token и входной путь `/api/bridge/max/messages`
7. Проверить логи `journalctl -u project-max-backend`

## Важно

- перед `restore` лучше останавливать backend;
- для production web push нужен HTTPS;
- реальный MAX adapter ещё не подключён, поэтому основной входящий канал пока mock-only.
