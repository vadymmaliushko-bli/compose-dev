# === GLOBAL CONFIG ===
ENV_FILE ?= .env.dev

# === GENERAL COMMANDS ===

# Запустити всі проєкти
up:
	docker compose --env-file $(ENV_FILE) up -d

# Зупинити всі проєкти
down:
	docker compose down

# Перезапустити всі проєкти
restart:
	$(MAKE) down
	$(MAKE) up

# Показати статус контейнерів
ps:
	docker compose ps

# Показати логи всіх сервісів
logs:
	docker compose logs -f

# Зупинити всі проєкти (без видалення)
stop:
	docker compose stop

# Запустити зупинені проєкти
start:
	docker compose start

# Перебудовувати і запустити
build:
	docker compose --env-file $(ENV_FILE) up -d --build

# === INDIVIDUAL SERVICES ===

#  PostgreSQL
postgres:
	docker compose --env-file $(ENV_FILE) up -d dev-db

#  Redis
redis:
	docker compose --env-file $(ENV_FILE) up -d redis

# Запустити бот
bot:
	docker compose --env-file $(ENV_FILE) up -d dev-bot

# Рестарт бот
bot-res: 	
	docker compose restart dev-bot	

# Логи PostgreSQL
logs-postgres:
	docker compose logs -f dev-db

# Логи Redis
logs-redis:
	docker compose logs -f redis

# Логи бот
logs-bot:
	docker compose logs -f dev-bot

# === CLEANUP COMMANDS ===
# Очистити всі контейнери, мережі та volumes
clean:
	docker compose down -v --remove-orphans

# Очистити   зупинені контейнери
clean-containers:
	docker compose rm -f

# Показати використання ресурсів
stats:
	docker stats
