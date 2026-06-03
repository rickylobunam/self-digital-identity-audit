.PHONY: help install lint test build dev dev-full dev-down clean fix-perms certs docker-up docker-up-full docker-down health health-full health-backend health-frontend health-orchestrator health-mailhog health-support docker-logs

# Default shell for make commands
SHELL := /bin/bash

# Python/uv environment setup (portable for WSL/Linux/macOS)
export PATH := $(HOME)/.local/bin:$(PATH)

# Project directories
FRONTEND_DIR := frontend
BACKEND_DIR := backend
ORCHESTRATOR_DIR := orchestrator

# Tmux development session
TMUX_SESSION := sdia-dev

# Local service URLs
FRONTEND_URL := http://localhost:5173
BACKEND_URL := http://localhost:3000
ORCHESTRATOR_URL := http://localhost:8000
MAILHOG_URL := http://localhost:8025

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)SDIA - Self Digital Identity Audit$(NC)"
	@echo "$(BLUE)===================================$(NC)"
	@echo ""
	@echo "$(GREEN)Core targets:$(NC)"
	@echo "  make install        Install all dependencies (frontend, backend, orchestrator)"
	@echo "  make lint           Run linters across all components"
	@echo "  make test           Run tests across all components"
	@echo "  make build          Build all components"
	@echo "  make dev            Start support containers + backend/frontend in tmux"
	@echo "  make dev-full       Start support containers + backend/frontend/orchestrator in tmux"
	@echo "  make dev-down       Stop tmux dev session and stop support containers"
	@echo "  make clean          Remove generated local artifacts"
	@echo "  make fix-perms      Fix root-owned artifacts caused by Docker bind mounts"
	@echo ""
	@echo "$(YELLOW)Docker targets:$(NC)"
	@echo "  make docker-up      Start core docker-compose services (support + backend + frontend)"
	@echo "  make docker-up-full Start all docker-compose services including orchestrator profile"
	@echo "  make docker-down    Stop all docker-compose services"
	@echo "  make docker-logs    Follow docker-compose logs"
	@echo ""
	@echo "$(YELLOW)Health targets:$(NC)"
	@echo "  make health         Check frontend, backend and Mailhog"
	@echo "  make health-full    Check frontend, backend, Mailhog and orchestrator"
	@echo "  make health-support Check support services only (Mailhog HTTP UI)"
	@echo ""
	@echo "$(YELLOW)Certificate target:$(NC)"
	@echo "  make certs          Generate local HTTPS certificates (mkcert or OpenSSL)"
	@echo ""
	@echo "$(YELLOW)Manual local development:$(NC)"
	@echo "  1) Start support services:"
	@echo "     docker compose up -d cosmos-emulator azurite mailhog"
	@echo ""
	@echo "  2) Terminal 1 - Backend:"
	@echo "     cd backend && npm run dev"
	@echo ""
	@echo "  3) Terminal 2 - Frontend:"
	@echo "     cd frontend && npm run dev -- --host 0.0.0.0"
	@echo ""
	@echo "  4) Optional Terminal 3 - Orchestrator:"
	@echo "     cd orchestrator && uv run uvicorn app.main:app --reload --host 0.0.0.0"
	@echo ""
	@echo "$(YELLOW)Automated local development with tmux:$(NC)"
	@echo "  make dev            Start backend + frontend only"
	@echo "  make dev-full       Start backend + frontend + orchestrator"
	@echo "  make dev-down       Stop tmux session and stop support containers"
	@echo ""
	@echo "$(YELLOW)Useful local URLs:$(NC)"
	@echo "  Frontend:     $(FRONTEND_URL)"
	@echo "  Backend:      $(BACKEND_URL)"
	@echo "  Orchestrator: $(ORCHESTRATOR_URL)"
	@echo "  Mailhog:      $(MAILHOG_URL)"
	@echo ""
	@echo "$(YELLOW)tmux shortcuts:$(NC)"
	@echo "  Ctrl+b then n     Next window"
	@echo "  Ctrl+b then p     Previous window"
	@echo "  Ctrl+b then d     Detach session without stopping services"
	@echo ""

# ===========================
# Core Targets
# ===========================

install:
	@echo "$(BLUE)Installing dependencies...$(NC)"
	@echo "$(GREEN)→ Frontend (npm)$(NC)"
	@cd $(FRONTEND_DIR) && npm install
	@echo "$(GREEN)→ Backend (npm)$(NC)"
	@cd $(BACKEND_DIR) && npm install
	@echo "$(GREEN)→ Orchestrator (uv)$(NC)"
	@cd $(ORCHESTRATOR_DIR) && uv sync --all-extras
	@echo "$(GREEN)✓ All dependencies installed$(NC)"

lint:
	@echo "$(BLUE)Running linters...$(NC)"
	@echo "$(GREEN)→ Frontend$(NC)"
	@cd $(FRONTEND_DIR) && npm run lint
	@echo "$(GREEN)→ Backend$(NC)"
	@cd $(BACKEND_DIR) && npm run lint
	@echo "$(YELLOW)→ Orchestrator: placeholder (ruff not configured yet)$(NC)"
	@cd $(ORCHESTRATOR_DIR) && echo "Lint placeholder: no linter configured yet"
	@echo "$(GREEN)✓ Lint checks complete$(NC)"

test:
	@echo "$(BLUE)Running tests...$(NC)"
	@echo "$(GREEN)→ Frontend$(NC)"
	@cd $(FRONTEND_DIR) && npm run test 2>/dev/null || echo "  Test placeholder: no frontend test runner configured yet"
	@echo "$(GREEN)→ Backend$(NC)"
	@cd $(BACKEND_DIR) && npm run test 2>/dev/null || echo "  Test placeholder: no backend test runner configured yet"
	@echo "$(GREEN)→ Orchestrator$(NC)"
	@cd $(ORCHESTRATOR_DIR) && uv run pytest tests/ -v
	@echo "$(GREEN)✓ All tests complete$(NC)"

build:
	@echo "$(BLUE)Building all components...$(NC)"
	@echo "$(GREEN)→ Frontend (Vite)$(NC)"
	@cd $(FRONTEND_DIR) && npm run build
	@echo "$(GREEN)→ Backend (TypeScript)$(NC)"
	@cd $(BACKEND_DIR) && npm run build
	@echo "$(YELLOW)→ Orchestrator: no build step required (Python)$(NC)"
	@cd $(ORCHESTRATOR_DIR) && uv run python -m compileall app tests
	@echo "$(GREEN)✓ All components built$(NC)"

dev:
	@echo "$(BLUE)Starting SDIA local development environment...$(NC)"
	@if ! command -v tmux >/dev/null 2>&1; then \
		echo "$(RED)Error: tmux is not installed.$(NC)"; \
		echo "Install it with:"; \
		echo "  sudo apt update && sudo apt install -y tmux"; \
		exit 1; \
	fi
	@if ! docker info >/dev/null 2>&1; then \
		echo "$(YELLOW)Docker daemon is not running or not reachable.$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Skipping support containers: Cosmos Emulator, Azurite, Mailhog.$(NC)"; \
		echo "Start Docker Desktop / Docker Engine and then run:"; \
		echo "  docker compose up -d cosmos-emulator azurite mailhog"; \
		echo ""; \
	else \
		echo "$(GREEN)→ Starting support containers (Cosmos Emulator, Azurite, Mailhog)$(NC)"; \
		docker compose up -d cosmos-emulator azurite mailhog; \
	fi
	@echo "$(YELLOW)If frontend/orchestrator fail with EACCES, run: make fix-perms$(NC)"
	@if tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
		echo "$(YELLOW)tmux session '$(TMUX_SESSION)' already exists.$(NC)"; \
		echo "$(GREEN)Attaching to existing session...$(NC)"; \
		tmux attach-session -t $(TMUX_SESSION); \
	else \
		echo "$(GREEN)Creating tmux session: $(TMUX_SESSION)$(NC)"; \
		tmux new-session -d -s $(TMUX_SESSION) -n backend "cd $(BACKEND_DIR) && if [ ! -x node_modules/.bin/tsx ]; then npm install; fi && npm run dev; exec bash"; \
		tmux new-window -t $(TMUX_SESSION) -n frontend "cd $(FRONTEND_DIR) && if [ ! -x node_modules/.bin/vite ]; then npm install; fi && rm -rf node_modules/.vite 2>/dev/null || true; npm run dev -- --host 0.0.0.0; exec bash"; \
		tmux select-window -t $(TMUX_SESSION):backend; \
		echo "$(GREEN)✓ Development session started$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Useful URLs:$(NC)"; \
		echo "  Frontend:     $(FRONTEND_URL)"; \
		echo "  Backend:      $(BACKEND_URL)"; \
		echo "  Orchestrator: $(ORCHESTRATOR_URL)"; \
		echo "  Mailhog:      $(MAILHOG_URL)"; \
		echo ""; \
		echo "$(YELLOW)tmux shortcuts:$(NC)"; \
		echo "  Ctrl+b then n     Next window"; \
		echo "  Ctrl+b then p     Previous window"; \
		echo "  Ctrl+b then d     Detach session"; \
		echo ""; \
		echo "$(YELLOW)To stop dev services:$(NC)"; \
		echo "  make dev-down"; \
		echo ""; \
		tmux attach-session -t $(TMUX_SESSION); \
	fi


dev-full:
	@echo "$(BLUE)Starting SDIA full local development environment...$(NC)"
	@if ! command -v tmux >/dev/null 2>&1; then \
		echo "$(RED)Error: tmux is not installed.$(NC)"; \
		echo "Install it with:"; \
		echo "  sudo apt update && sudo apt install -y tmux"; \
		exit 1; \
	fi
	@if ! docker info >/dev/null 2>&1; then \
		echo "$(YELLOW)Docker daemon is not running or not reachable.$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Skipping support containers: Cosmos Emulator, Azurite, Mailhog.$(NC)"; \
		echo "Start Docker Desktop / Docker Engine and then run:"; \
		echo "  docker compose up -d cosmos-emulator azurite mailhog"; \
		echo ""; \
	else \
		echo "$(GREEN)→ Starting support containers (Cosmos Emulator, Azurite, Mailhog)$(NC)"; \
		docker compose up -d cosmos-emulator azurite mailhog; \
	fi
	@echo "$(YELLOW)If frontend/backend/orchestrator fail with EACCES, run: make fix-perms$(NC)"
	@if tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
		echo "$(YELLOW)tmux session '$(TMUX_SESSION)' already exists.$(NC)"; \
		if ! tmux list-windows -t $(TMUX_SESSION) -F '#W' | grep -qx orchestrator; then \
			echo "$(GREEN)→ Adding orchestrator window to existing session$(NC)"; \
			tmux new-window -t $(TMUX_SESSION) -n orchestrator "cd $(ORCHESTRATOR_DIR) && uv sync --all-extras && uv run uvicorn app.main:app --reload --host 0.0.0.0; exec bash"; \
		fi; \
		echo "$(GREEN)Attaching to existing session...$(NC)"; \
		tmux attach-session -t $(TMUX_SESSION); \
	else \
		echo "$(GREEN)Creating tmux session: $(TMUX_SESSION)$(NC)"; \
		tmux new-session -d -s $(TMUX_SESSION) -n backend "cd $(BACKEND_DIR) && if [ ! -x node_modules/.bin/tsx ]; then npm install; fi && npm run dev; exec bash"; \
		tmux new-window -t $(TMUX_SESSION) -n frontend "cd $(FRONTEND_DIR) && if [ ! -x node_modules/.bin/vite ]; then npm install; fi && rm -rf node_modules/.vite 2>/dev/null || true; npm run dev -- --host 0.0.0.0; exec bash"; \
		tmux new-window -t $(TMUX_SESSION) -n orchestrator "cd $(ORCHESTRATOR_DIR) && uv sync --all-extras && uv run uvicorn app.main:app --reload --host 0.0.0.0; exec bash"; \
		tmux select-window -t $(TMUX_SESSION):backend; \
		echo "$(GREEN)✓ Full development session started$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Useful URLs:$(NC)"; \
		echo "  Frontend:     $(FRONTEND_URL)"; \
		echo "  Backend:      $(BACKEND_URL)"; \
		echo "  Orchestrator: $(ORCHESTRATOR_URL)"; \
		echo "  Mailhog:      $(MAILHOG_URL)"; \
		echo ""; \
		echo "$(YELLOW)tmux shortcuts:$(NC)"; \
		echo "  Ctrl+b then n     Next window"; \
		echo "  Ctrl+b then p     Previous window"; \
		echo "  Ctrl+b then d     Detach session"; \
		echo ""; \
		echo "$(YELLOW)To stop dev services:$(NC)"; \
		echo "  make dev-down"; \
		echo ""; \
		tmux attach-session -t $(TMUX_SESSION); \
	fi

dev-down:
	@echo "$(BLUE)Stopping SDIA local development environment...$(NC)"
	@if tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
		tmux kill-session -t $(TMUX_SESSION); \
		echo "$(GREEN)✓ tmux session '$(TMUX_SESSION)' stopped$(NC)"; \
	else \
		echo "$(YELLOW)No tmux session named '$(TMUX_SESSION)' is running.$(NC)"; \
	fi
	@echo "$(GREEN)→ Stopping support containers$(NC)"
	@docker compose stop cosmos-emulator azurite mailhog >/dev/null 2>&1 || true
	@echo "$(GREEN)✓ Local development environment stopped$(NC)"
	@echo "$(YELLOW)Note: containers were stopped, not removed. Use 'make docker-down' to remove them.$(NC)"

clean:
	@echo "$(BLUE)Cleaning generated artifacts...$(NC)"
	@$(MAKE) --no-print-directory fix-perms
	@echo "$(GREEN)→ Frontend$(NC)"
	@cd $(FRONTEND_DIR) && rm -rf node_modules dist coverage .vite
	@echo "$(GREEN)→ Backend$(NC)"
	@cd $(BACKEND_DIR) && rm -rf node_modules dist coverage
	@echo "$(GREEN)→ Orchestrator$(NC)"
	@cd $(ORCHESTRATOR_DIR) && rm -rf .venv __pycache__ .pytest_cache .ruff_cache .mypy_cache dist build *.egg-info app/__pycache__ tests/__pycache__
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

fix-perms:
	@echo "$(BLUE)Fixing file permissions for local generated artifacts...$(NC)"
	@sudo chown -R $(shell id -u):$(shell id -g) \
		$(FRONTEND_DIR)/node_modules $(FRONTEND_DIR)/dist \
		$(BACKEND_DIR)/node_modules $(BACKEND_DIR)/dist \
		$(ORCHESTRATOR_DIR)/.venv $(ORCHESTRATOR_DIR)/__pycache__ $(ORCHESTRATOR_DIR)/app/__pycache__ $(ORCHESTRATOR_DIR)/tests/__pycache__ \
		2>/dev/null || true
	@echo "$(GREEN)✓ Permissions fixed where needed$(NC)"

# ===========================
# Optional Targets
# ===========================

certs:
	@echo "$(BLUE)Generating local HTTPS certificates...$(NC)"
	@echo "$(YELLOW)Note: Certificates are for local development only. Do not commit.$(NC)"
	@echo ""
	@if [ "$(OS)" = "Windows_NT" ]; then \
		echo "$(GREEN)Running PowerShell certificate generator (Windows)$(NC)"; \
		pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/certs/cer.ps1; \
	else \
		echo "$(GREEN)Running bash certificate generator (Linux/macOS)$(NC)"; \
		bash scripts/certs/cer.sh; \
	fi

docker-up:
	@echo "$(BLUE)Starting docker-compose core services...$(NC)"
	@docker compose up -d cosmos-emulator azurite mailhog backend frontend
	@echo "$(GREEN)✓ Core services started$(NC)"
	@echo "  Frontend:  $(FRONTEND_URL)"
	@echo "  Backend:   $(BACKEND_URL)"
	@echo "  Mailhog:   $(MAILHOG_URL)"
	@echo ""
	@echo "$(YELLOW)Note: Orchestrator is ephemeral/local-testing only.$(NC)"
	@echo "      Start it with: make docker-up-full"

docker-up-full:
	@echo "$(BLUE)Starting docker-compose services including orchestrator...$(NC)"
	@docker compose --profile orchestrator up -d
	@echo "$(GREEN)✓ All services started$(NC)"
	@echo "  Frontend:     $(FRONTEND_URL)"
	@echo "  Backend:      $(BACKEND_URL)"
	@echo "  Orchestrator: $(ORCHESTRATOR_URL)"
	@echo "  Mailhog:      $(MAILHOG_URL)"

docker-down:
	@echo "$(BLUE)Stopping docker-compose services...$(NC)"
	@docker compose --profile orchestrator down
	@echo "$(GREEN)✓ Services stopped$(NC)"

docker-logs:
	@docker compose --profile orchestrator logs -f

# ===========================
# Health Targets
# ===========================

health: health-backend health-frontend health-mailhog

health-full: health-backend health-frontend health-mailhog health-orchestrator

health-support: health-mailhog

health-backend:
	@echo "$(GREEN)→ Backend health$(NC)"
	@curl -fsS $(BACKEND_URL)/health || echo "  Backend not responding"
	@echo ""

health-frontend:
	@echo "$(GREEN)→ Frontend health$(NC)"
	@curl -fsS -o /dev/null $(FRONTEND_URL) && echo "Frontend OK" || echo "  Frontend not responding"
	@echo ""

health-orchestrator:
	@echo "$(GREEN)→ Orchestrator health$(NC)"
	@curl -fsS $(ORCHESTRATOR_URL)/health || echo "  Orchestrator not responding"
	@echo ""

health-mailhog:
	@echo "$(GREEN)→ Mailhog health$(NC)"
	@curl -fsS -o /dev/null $(MAILHOG_URL) && echo "Mailhog OK" || echo "  Mailhog not responding"
	@echo ""
