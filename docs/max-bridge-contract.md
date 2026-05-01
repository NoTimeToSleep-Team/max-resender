# MAX Bridge Contract

Этот документ описывает внешний ingress-контракт для bridge-процесса, который будет получать сообщения из MAX и пересылать их в core backend.

## Endpoint

```http
POST /api/bridge/max/messages
```

## Auth

Передаётся header:

```http
x-bridge-token: <MAX_BRIDGE_TOKEN>
```

Без корректного токена backend вернёт `401`.

## Payload

Поддерживается тот же нормализуемый вход, что и у mock ingest:

```json
{
  "source": "max-bridge",
  "sourceChatId": "group-123",
  "sourceMessageId": "message-456",
  "author": {
    "id": "user-7",
    "name": "Alice",
    "username": "alice"
  },
  "text": "hello from max bridge",
  "attachments": [],
  "sentAt": "2026-04-23T10:00:00.000Z",
  "rawPayload": {
    "provider": "max"
  }
}
```

## Ответ

Новый message key:

- `201 Created`

Повторная подача того же message key:

- `200 OK`
- `idempotentReplay: true`

## Идемпотентность

Ключ сообщения определяется по:

- `source`
- `sourceChatId`
- `sourceMessageId`

Повторная отправка того же ключа не создаёт дублей ни в `messages`, ни в `delivery_jobs`.

## Локальные bridge scripts

Одиночная отправка JSON:

```bash
MAX_BRIDGE_TOKEN=... npm run bridge:send -- --file ./message.json
```

Или через stdin:

```bash
cat ./message.json | MAX_BRIDGE_TOKEN=... npm run bridge:send
```

Replay JSONL:

```bash
MAX_BRIDGE_TOKEN=... npm run bridge:replay -- --file ./messages.jsonl --delay-ms 250
```

Если backend слушает не `http://127.0.0.1:3000`, можно переопределить:

```bash
BRIDGE_BASE_URL=http://192.168.1.50:3000
```

## Что должен делать реальный MAX bridge

1. Получить сообщение из MAX.
2. Сконвертировать его в этот payload.
3. Передать payload в `/api/bridge/max/messages`.
4. На `200/201` считать событие доставленным в core.
5. На network/server error повторять отправку у себя с retry.

## Что не должен делать bridge

- не ходить напрямую в SQLite;
- не создавать delivery jobs сам;
- не решать Telegram/push/web delivery;
- не переопределять idempotency логику core backend.
