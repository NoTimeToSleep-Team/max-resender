# Архитектура `project-max`

Дата фиксации: `2026-04-21`

## Цели архитектуры

- бесплатно и воспроизводимо запускаться дома на Raspberry Pi 5;
- принимать сообщения из MAX через заменяемый адаптер;
- надёжно хранить сообщения и статусы доставки;
- доставлять сообщения в Telegram и веб-клиент;
- переживать временную недоступность отдельных каналов;
- давать web push через PWA без платных провайдеров.

## Сравнение архитектурных вариантов

| Вариант | Кратко | Плюсы | Минусы | Решение |
| --- | --- | --- | --- | --- |
| A. Один узел на Raspberry Pi 5 | MAX adapter, core backend, SQLite, Telegram delivery, SSE и React/PWA живут на одном основном хосте | Минимум точек отказа, проще сопровождать, проще backup, меньше сетевых зависимостей | Если один маршрут не видит и MAX, и Telegram, нужна запасная схема | Основной |
| B. Разделённая схема: Pi Zero 2 W как MAX bridge, Pi 5 как core | Pi Zero получает MAX и отправляет нормализованные события в core на Pi 5 | Лучше переносит сетевое разделение и разные каналы доступа | Больше компонентов, выше сложность диагностики и обновлений | Резервный |
| C. Микросервисы в Docker Compose | Отдельные контейнеры для adapter, backend, web, DB и workers | Изоляция процессов и привычный контейнерный деплой | Для домашнего Pi это лишний ops-слой и больше ресурсов | Не выбран |

## Выбранная стратегия

Основной вариант: один core-узел на Raspberry Pi 5.

Резервный вариант: выделить Raspberry Pi Zero 2 W в отдельный MAX bridge только если на практике подтвердится, что MAX и Telegram требуют разных сетевых маршрутов.

## Технологический выбор

- Backend: Node.js + TypeScript.
- HTTP/API слой: Fastify.
- Frontend: React + Vite.
- Хранение и durable queue: SQLite.
- Realtime для сайта: SSE.
- Push для сайта: Web Push + service worker + manifest + PWA.
- Логирование: structured logging в JSON.
- Конфигурация: `.env` + валидация окружения на старте.
- Deployment: systemd для основного процесса и reverse proxy с HTTPS.

## Почему выбран именно этот стек

- Node.js и TypeScript позволяют держать backend, workers и shared-типы в одном языке.
- Fastify достаточно лёгкий для Raspberry Pi и хорошо подходит для API, healthcheck и SSE.
- React + Vite дают быстрый старт для адаптивного интерфейса и PWA.
- SQLite покрывает хранение сообщений, подписок и очереди без отдельного сервера БД.
- SSE проще и надёжнее WebSocket для однонаправленной realtime-ленты.
- systemd проще Docker Compose для одного основного сервиса на домашнем Pi.

## Базовый поток данных

1. MAX adapter получает новое сообщение и нормализует его в единый формат.
2. Core backend проверяет idempotency и сохраняет сообщение в SQLite.
3. Core backend ставит задачи доставки в durable queue.
4. Delivery workers отправляют сообщение в Telegram и web push.
5. Backend публикует событие в SSE-поток для React-клиента.
6. Frontend показывает сообщение, автора, время, источник и статус доставки.

## Границы модулей

- `max-adapter` отвечает только за получение и нормализацию сообщений из MAX.
- `core` отвечает за хранение, deduplication, очередь, retry, статусы и API.
- `telegram-delivery` отвечает за форматирование и доставку в Telegram.
- `web-app` отвечает за UI, PWA, push onboarding и отображение статусов.
- `shared` хранит общие типы, схемы и формат событий.

## Минимальная схема хранения

- таблица сообщений;
- таблица delivery jobs;
- таблица delivery attempts;
- таблица web push subscriptions;
- таблица checkpoints и служебного состояния.

## Надёжность

- deduplication по source, chat и внешнему message ID;
- retry with backoff для Telegram и bridge-вызовов;
- durable queue в SQLite, чтобы переживать перезапуски;
- healthcheck endpoint;
- structured logging;
- graceful degradation, если один из каналов доставки временно недоступен.

## Ограничения платформы

- Web push на iPhone работает только для установленных PWA и зависит от версии iOS и WebKit.
- Для production web push нужен HTTPS и реальный домен или эквивалентная доверенная схема доставки сертификата.
- Интеграция с MAX должна оставаться сменяемой, пока не подтверждён конкретный официальный API или поддерживаемый bridge-механизм.

## Ближайшая реализация

1. Поднять backend foundation с SQLite, healthcheck и env validation.
2. Поднять React/PWA shell и подписку на SSE.
3. Добавить durable message pipeline и mock MAX adapter.
4. После этого подключать Telegram и реальный MAX bridge.
