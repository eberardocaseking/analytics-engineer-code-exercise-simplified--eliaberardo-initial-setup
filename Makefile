###########################################################
################# Repository Operations ##################
###########################################################
.PHONY: help setup clean start-local-db stop-local-db restart-local-db reset-local-db dbt-shell

DBT_PROJECT_NAME=spacex_satellites

###########################################################
################# LOCAL DEVELOPMENT SETUP #################
###########################################################

setup: ## Complete setup: environment, database, and dbt (run this first!)
	@echo "Running complete setup..."
	@chmod +x setup.sh
	@./setup.sh

clean: ## Clean up everything: stop containers, remove volumes, and clean dbt artifacts
	@echo "⚠️  WARNING: This will delete ALL your work including:"
	@echo "   - All Docker containers and volumes"
	@echo "   - The entire dbt project directory (spacex_satellites/)"
	@echo "   - All your dbt models, tests, and configurations"
	@echo "   - Environment configuration (.env file)"
	@echo ""
	@read -p "   Are you sure you want to continue? (y/n): " -n 1 -r; \
	echo ""; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "   Cleanup cancelled."; \
		exit 0; \
	fi
	@echo "🧹 Cleaning up everything..."
	@cd docker && $(DOCKER_COMPOSE) --env-file dev.env down -v 2>/dev/null || true
	@docker volume rm docker_postgres_data docker_dbt_packages docker_dbt_target 2>/dev/null || true
	@rm -rf spacex_satellites
	@rm -f .env
	@echo "✅ Cleanup complete! Run 'make setup' to start fresh."

#################### Local Postgres DB ####################
# Detect docker compose command (V2 preferred, fallback to V1)
DOCKER_COMPOSE := $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")

start-local-db: ## Start local postgres DB and insert spaceX test data
	@echo "Starting local Postgres DB with SpaceX data for development..."
	cd docker && $(DOCKER_COMPOSE) --env-file dev.env up -d

stop-local-db: ## Stop local Postgres DB
	@echo "Stopping local Postgres DB..."
	cd docker && $(DOCKER_COMPOSE) --env-file dev.env down

restart-local-db: stop-local-db start-local-db ## Restart local Postgres DB
	@echo "Restarted local Postgres DB..."

reset-local-db: ## Stop, remove volumes, and restart local Postgres DB (reloads data, drops all tables)
	@echo "Resetting local Postgres DB (this will drop all data including dbt models)..."
	@echo "Removing old volumes to fix any compatibility issues..."
	cd docker && $(DOCKER_COMPOSE) --env-file dev.env down -v
	@docker volume rm docker_postgres_data 2>/dev/null || true
	@echo "Starting fresh database..."
	cd docker && $(DOCKER_COMPOSE) --env-file dev.env up -d
	@echo "✅ Database reset complete. All data reloaded from sample-db.sql"

############### Database Operations ##############
db-shell: ## Enter PostgreSQL shell
	@if ! docker ps | grep -q postgres_db; then \
		echo "❌ PostgreSQL container is not running. Please run 'make setup' first."; \
		exit 1; \
	fi
	@echo "Entering PostgreSQL shell..."
	@echo "You can run SQL queries directly, e.g., SELECT * FROM public.starlink LIMIT 10;"
	@echo ""
	docker exec -it postgres_db psql -U local_dev -d postgres

############### DBT Operations ##############
dbt-shell: ## Enter interactive dbt shell in Docker container
	@if [ ! -d "$(DBT_PROJECT_NAME)" ]; then \
		echo "❌ dbt project directory '$(DBT_PROJECT_NAME)' not found. Please run 'make setup' first."; \
		exit 1; \
	fi
	@if ! docker ps | grep -q dbt_dev; then \
		echo "❌ dbt container is not running. Please run 'make setup' first."; \
		exit 1; \
	fi
	@echo "Entering dbt shell in Docker container..."
	@echo "You can run: dbt debug, dbt run, dbt test, dbt docs generate, etc."
	@echo ""
	docker exec -it -w /workspace/$(DBT_PROJECT_NAME) \
		-e POSTGRES_DEV_DBNAME=postgres \
		-e POSTGRES_DEV_USER=local_dev \
		-e POSTGRES_DEV_PASS=local_dev \
		dbt_dev /bin/bash

#### HELP ###
help: ## Show this help message
	@echo "Available targets:"
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
