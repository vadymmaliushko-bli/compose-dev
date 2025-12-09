## Команда запуску підміни хостів:
```bash
docker compose --env-file .env.dev up -d
```

## Приклад `.env.dev`

```
# Приклад змінних — налаштуйте під ваші потреби
# HOSTS="127.0.0.1"
# IN_OTHER_SERVICE=значення
```

## Makefile для швидкого підняття

```
# make up   - запустити всі проєкти
# make down - зупинити всі проєкти
# make postgres - запустити тільки postgres
# make bot  - запустити тільки бот
# make restart - перезапустити всі
# make postgres ENV_FILE=.env.prod - запустити postgres з продакшн конфігом
```