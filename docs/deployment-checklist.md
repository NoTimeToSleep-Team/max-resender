# Deployment Checklist

Короткий production checklist для Raspberry Pi.

## До выката

1. Установить `node 24`, `npm`, `nginx`.
2. Создать пользователя `projectmax`.
3. Подготовить `/opt/project-max`.
4. Скопировать проект в `/opt/project-max`.
5. Скопировать `.env.production.example` в `.env` и заполнить реальные значения.
6. Если нужен push, сгенерировать `VAPID` keys через:

```bash
npm run generate:vapid
```

## Сборка

```bash
npm install
npm run typecheck
npm run build
npm test
```

## systemd

1. Скопировать unit files из `deploy/systemd/` в `/etc/systemd/system/`.
2. Сделать скрипты из `deploy/scripts/` исполняемыми:

```bash
chmod +x /opt/project-max/deploy/scripts/*.sh
```

3. Активировать backend service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now project-max-backend.service
```

4. Активировать maintenance timers:

```bash
sudo systemctl enable --now project-max-backup.timer
sudo systemctl enable --now project-max-prune.timer
```

## nginx

1. Скопировать `deploy/nginx/project-max.conf` в sites-available.
2. Сделать symlink в sites-enabled.
3. Проверить конфиг:

```bash
sudo nginx -t
```

4. Перезагрузить nginx:

```bash
sudo systemctl reload nginx
```

## После выката

Проверить:

- `curl http://127.0.0.1:3000/health`
- `curl http://127.0.0.1:3000/api/messages`
- `curl http://127.0.0.1:3000/api/push/config`
- `deploy/scripts/check-project-max.sh`

Если настроен `ADMIN_API_TOKEN`:

```bash
ADMIN_API_TOKEN=... /opt/project-max/deploy/scripts/check-project-max.sh
```

## Обновление

1. Остановить backend при необходимости.
2. Обновить код.
3. Выполнить:

```bash
npm install
npm run typecheck
npm run build
npm test
```

4. Перезапустить backend:

```bash
sudo systemctl restart project-max-backend.service
```

## Backup и restore

Ручной backup:

```bash
npm run backup:db -- ./backups/manual.sqlite
```

Restore:

```bash
sudo systemctl stop project-max-backend.service
npm run restore:db -- ./backups/manual.sqlite --force
sudo systemctl start project-max-backend.service
```
