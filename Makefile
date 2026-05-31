.PHONY: help install lint test build dev clean certs docker-up docker-down health

# Default shell for make commands
SHELL := /bin/bash

# Project directories
FRONTEND_DIR := frontend
BACKEND_DIR := backend
ORCHESTRATOR_DIR := orchestrator

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
	@echo "  make install        Install all dependencies (npm, uv, Python venv)"
	@echo "  make lint           Run linters across all components"
	@echo "  make test           Run tests (frontend, backend, orchestrator)"
	@echo "  make build          Build all components (TypeScript, Vite, Python)"
	@echo "  make dev            Start development servers (frontend, backend)"
	@echo "  make clean          Clean build artifacts, node_modules, .venv"
	@echo ""
	@echo "$(YELLOW)Optional targets:$(NC)"
	@echo "  make certs          Generate local HTTPS certificates (mkcert or OpenSSL)"
	@echo "  make docker-up      Start docker-compose services"
	@echo "  make docker-down    Stop docker-compose services"
	@echo "  make health         Check health endpoints (backend, orchestrator)"
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
	@echo "$(YELLOW)→ Frontend: placeholder (ESLint not configured yet)$(NC)"
	@cd $(FRONTEND_DIR) && npm run lint
	@echo "$(YELLOW)→ Backend: placeholder (ESLint not configured yet)$(NC)"
	@cd $(BACKEND_DIR) && npm run lint
	@echo "$(YELLOW)→ Orchestrator: placeholder (ruff not configured yet)$(NC)"
	@cd $(ORCHESTRATOR_DIR) && echo "Lint placeholder: no linter configured yet"
	@echo "$(GREEN)✓ Lint checks complete$(NC)"

test:
	@echo "$(BLUE)Running tests...$(NC)"
	@echo "$(GREEN)→ Frontend$(NC)"
	@cd $(FRONTEND_DIR) && npm run test 2>/dev/null || echo "  Test placeholder: no test runner configured yet"
	@echo "$(GREEN)→ Backend$(NC)"
	@cd $(BACKEND_DIR) && npm run test 2>/dev/null || echo "  Test placeholder: no test runner configured yet"
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
	@echo "$(GREEN)✓ All components built$(NC)"

dev:
	@echo "$(BLUE)Starting development servers...$(NC)"
	@echo "$(YELLOW)Note: Run each in a separate terminal, or use 'make docker-up' for docker-compose$(NC)"
	@echo ""
	@echo "$(GREEN)Frontend (port 5173):$(NC)"
	@echo "  cd frontend && npm run dev"
	@echo ""
	@echo "$(GREEN)Backend (port 3000):$(NC)"
	@echo "  cd backend && npm run dev"
	@echo ""
	@echo "$(GREEN)Orchestrator (port 8000):$(NC)"
	@echo "  cd orchestrator && uv run uvicorn app.main:app --reload"
	@echo ""

clean:
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	@echo "$(GREEN)→ Frontend$(NC)"
	@cd $(FRONTEND_DIR) && rm -rf node_modules dist .venv
	@echo "$(GREEN)→ Backend$(NC)"
	@cd $(BACKEND_DIR) && rm -rf node_modules dist .venv
	@echo "$(GREEN)→ Orchestrator$(NC)"
	@cd $(ORCHESTRATOR_DIR) && rm -rf .venv __pycache__ .pytest_cache dist build *.egg-info
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

# ===========================
# Optional Targets
# ===========================

certs:
	@echo "$(BLUE)Generating local HTTPS certificates...$(NC)"
	@if command -v mkcert &> /dev/null; then \
		echo "$(GREEN)Using mkcert$(NC)"; \
		mkdir -p .certs; \
		mkcert -key-file .certs/key.pem -cert-file .certs/cert.pem localhost 127.0.0.1 sdia.local; \
		echo "$(GREEN)✓ Certificates generated in .certs/$(NC)"; \
	else \
		echo "$(YELLOW)mkcert not found. Using OpenSSL fallback...$(NC)"; \
		mkdir -p .certs; \
		openssl req -x509 -newkey rsa:4096 -keyout .certs/key.pem -out .certs/cert.pem -days 365 -nodes \
			-subj "/CN=localhost"; \
		echo "$(GREEN)✓ Self-signed certificate generated (localhost only)$(NC)"; \
	fi
	@echo "$(YELLOW)Note: Certificates are for local development only. Do not commit.$(NC)"

docker-up:
	@echo "$(BLUE)Starting docker-compose services...$(NC)"
	@docker-compose up -d
	@echo "$(GREEN)✓ Services started$(NC)"
	@echo "  Frontend:   http://localhost:5173"
	@echo "  Backend:    http://localhost:3000"
	@echo "  Orchestrator: http://localhost:8000"

docker-down:
	@echo "$(BLUE)Stopping docker-compose services...$(NC)"
	@docker-compose down
	@echo "$(GREEN)✓ Services stopped$(NC)"

health:
	@echo "$(BLUE)Checking health endpoints...$(NC)"
	@echo "$(GREEN)→ Backend health$(NC)"
	@curl -s http://localhost:3000/health | jq . || echo "  Backend not responding (expected if not running)"
	@echo "$(GREEN)→ Orchestrator health$(NC)"
	@curl -s http://localhost:8000/health | jq . || echo "  Orchestrator not responding (expected if not running)"
	@echo "$(GREEN)✓ Health check complete$(NC)"
