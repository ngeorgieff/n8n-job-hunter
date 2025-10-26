.PHONY: help build start stop restart logs clean test

help:
	@echo "Available commands:"
	@echo "  make build     - Build the Docker containers"
	@echo "  make start     - Start the n8n and Postgres services"
	@echo "  make stop      - Stop the services"
	@echo "  make restart   - Restart the services"
	@echo "  make logs      - Show logs from all services"
	@echo "  make clean     - Remove all containers and volumes"
	@echo "  make test      - Run workflow validation tests"

build:
	docker-compose build

start:
	docker-compose up -d
	@echo "n8n is starting up at http://localhost:5678"
	@echo "Default credentials: admin/admin (change in .env)"

stop:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

clean:
	docker-compose down -v
	@echo "All containers and volumes removed"

test:
	@echo "Running workflow validation tests..."
	@if [ -d "tests" ]; then \
		node tests/test_runner.js || npm test; \
	else \
		echo "No tests found in tests/ directory"; \
	fi
