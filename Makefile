SHELL := /bin/bash
VENV := .venv

.PHONY: help venv install dev dev-no-worker worker docker-up migrate logs stop restart test shell

help:
	@echo "Available targets:"
	@echo "  make venv            Create and activate virtualenv (no activation in make)."
	@echo "  make install         Install requirements into venv."
	@echo "  make dev             Start dev server (with worker)."
	@echo "  make dev-no-worker   Start dev server without worker."
	@echo "  make worker          Start a foreground RQ worker."
	@echo "  make docker-up       Start db+redis with docker-compose."
	@echo "  make migrate         Run flask db upgrade."
	@echo "  make logs            Tail logs."
	@echo "  make test            Run pytest."
	@echo "  make shell           Open flask shell."

venv:
	python3 -m venv $(VENV)
	@echo "Created venv at $(VENV). Activate with: source $(VENV)/bin/activate"

install: venv
	$(VENV)/bin/python -m pip install --upgrade pip
	$(VENV)/bin/python -m pip install -r requirements.txt

dev:
	chmod +x scripts/run_dev.sh
	./scripts/run_dev.sh

dev-no-worker:
	chmod +x scripts/run_dev.sh
	./scripts/run_dev.sh --no-worker

worker:
	$(VENV)/bin/rq worker microblog-tasks

docker-up:
	docker compose up --build -d db redis

migrate:
	export FLASK_APP=microblog.py && $(VENV)/bin/flask db upgrade

logs:
	@echo "Tailing logs (press Ctrl-C to stop)"
	tail -n +1 -f logs/*.log || true

stop:
	@echo "Stopping docker services (if running)"
	docker compose down || true

restart:
	make stop
	make docker-up

test:
	$(VENV)/bin/pytest -q

shell:
	export FLASK_APP=microblog.py && $(VENV)/bin/flask shell
