# === GLOBAL CONFIG ===
ENV_FILE ?= .env.dev

# === GENERAL COMMANDS ===

# Запустити всі проєкти
up:
	docker compose --env-file $(ENV_FILE) up -d

# Зупинити всі
down:
	docker compose down

# Перезапустити всі
restart:
	$(MAKE) down
	$(MAKE) up

# === INDIVIDUAL PROJECTS ===

# Приклад: make postgres
postgres:
	docker compose --env-file $(ENV_FILE) up -d dev-db

# Приклад: make bot
bot:
	docker compose --env-file $(ENV_FILE) up -d dev-bot
