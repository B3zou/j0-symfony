# ─────────────────────────────────────────────────────────────────────────────
# GG League · J0 — toutes les commandes de la journée.        →  make help
# ─────────────────────────────────────────────────────────────────────────────
.DEFAULT_GOAL := help
SHELL := /bin/bash

# Fichier optionnel (non versionné) pour surcharger les ports : voir README
-include .env
export

COMPOSE   := docker compose
EXEC_API  := $(COMPOSE) exec api
EXEC_TEST := $(COMPOSE) exec -T api-test
HURL      := $(COMPOSE) run --rm --no-deps hurl
# ERRORS=long affiche la réponse HTTP complète de chaque test en échec (make test ERRORS=long)
ERRORS    ?= short
HURL_FLAGS := --test --jobs 1 --color --error-format $(ERRORS) --variable host=http://api-test
API_URL   := http://localhost:$(or $(API_PORT),8000)
UPSTREAM  ?= upstream

GREEN  := \033[32m
YELLOW := \033[33m
RED    := \033[31m
BOLD   := \033[1m
RESET  := \033[0m

.PHONY: help doctor install up down restart build ps logs sh \
        sf composer cc db-update db-reset \
        test test-env test-db report

## —— 🚀 Démarrage ————————————————————————————————————————————————————————————
help: ## Affiche cette aide
	@printf "$(BOLD)GG League · J0$(RESET) — commandes disponibles\n"
	@grep -E '(^[a-zA-Z0-9_-]+:.*?## .*$$)|(^## )' $(MAKEFILE_LIST) \
		| sed -E 's/^## (.*)/\n\1/' \
		| awk 'BEGIN {FS = ":.*?## "}; /^[a-zA-Z0-9_-]+:/ {printf "  $(GREEN)%-12s$(RESET) %s\n", $$1, $$2; next} {print}'
	@printf "\nExemples : make install · make test · make test f=02 · make sf c=\"debug:router\"\n"

doctor: ## Vérifie votre poste (Docker, ports, git, fins de ligne)
	@ok()   { printf "  $(GREEN)✔$(RESET) %s\n" "$$1"; }; \
	 warn() { printf "  $(YELLOW)!$(RESET) %s\n" "$$1"; }; \
	 ko()   { printf "  $(RED)✘$(RESET) %s\n" "$$1"; FAIL=1; }; \
	 FAIL=0; \
	 printf "$(BOLD)Diagnostic du poste$(RESET)\n"; \
	 command -v docker >/dev/null && ok "Docker : $$(docker --version | cut -d, -f1)" || ko "Docker n'est pas installé"; \
	 docker info >/dev/null 2>&1 && ok "Le démon Docker répond" || ko "Le démon Docker ne répond pas (Docker Desktop est-il lancé ?)"; \
	 docker compose version >/dev/null 2>&1 && ok "$$(docker compose version)" || ko "Docker Compose v2 introuvable (« docker compose », sans tiret)"; \
	 MEM=$$(docker info --format '{{.MemTotal}}' 2>/dev/null || echo 0); \
	 [ "$$MEM" -ge 3000000000 ] 2>/dev/null && ok "Mémoire allouée à Docker : $$((MEM / 1024 / 1024)) Mo" || warn "Mémoire Docker faible ($$((MEM / 1024 / 1024)) Mo) : 4 Go recommandés"; \
	 RUNNING=$$($(COMPOSE) ps -q api 2>/dev/null); \
	 for P in $(or $(API_PORT),8000) $(or $(DB_PORT),5433); do \
	   if [ -z "$$RUNNING" ] && (exec 3<>/dev/tcp/127.0.0.1/$$P) 2>/dev/null; then ko "Port $$P déjà utilisé (changez-le dans un fichier .env, voir README)"; \
	   else ok "Port $$P disponible"; fi; \
	 done; \
	 command -v git >/dev/null && ok "Git : $$(git --version)" || ko "Git n'est pas installé"; \
	 [ -n "$$(git config user.name)" ] && [ -n "$$(git config user.email)" ] && ok "Git identifié : $$(git config user.name) <$$(git config user.email)>" || warn "Configurez git : git config --global user.name / user.email"; \
	 git remote get-url $(UPSTREAM) >/dev/null 2>&1 && ok "Remote « $(UPSTREAM) » (dépôt de l'enseignant) configuré" || warn "Remote « $(UPSTREAM) » absent (facultatif) : git remote add $(UPSTREAM) <url du dépôt de l'enseignant>"; \
	 if grep -q $$'\r' Makefile api/frankenphp/docker-entrypoint.sh 2>/dev/null; then ko "Fins de ligne Windows (CRLF) détectées : git config --global core.autocrlf input, puis reclonez"; else ok "Fins de ligne Unix (LF)"; fi; \
	 echo; [ $$FAIL -eq 0 ] && printf "$(GREEN)Tout est prêt.$(RESET) Lancez : make install\n" || { printf "$(RED)Corrigez les points en rouge avant de continuer.$(RESET)\n"; exit 1; }

install: ## Première installation (construit l'image : 2 à 5 min la 1re fois)
	@mkdir -p reports
	@if [ -n "$(API_IMAGE)" ]; then $(COMPOSE) pull api; else $(COMPOSE) build; fi
	$(COMPOSE) up -d --wait
	@$(MAKE) --no-print-directory db-reset
	@printf "\n$(GREEN)✔ Installation terminée$(RESET)\n"
	@printf "  Swagger UI (votre API)   $(API_URL)/api\n"
	@printf "  Profiler Symfony         $(API_URL)/_profiler\n"
	@printf "  PostgreSQL               localhost:$(or $(DB_PORT),5433) (app / app)\n"
	@printf "  Vérifier : make test (le fichier 00-games doit être vert)\n"

up: ## Démarre l'environnement
	$(COMPOSE) up -d --wait

down: ## Arrête l'environnement (les données sont conservées)
	$(COMPOSE) --profile test --profile tools down --remove-orphans

restart: ## Redémarre l'environnement
	@$(MAKE) --no-print-directory down
	@$(MAKE) --no-print-directory up

build: ## Reconstruit l'image (après une modification du Dockerfile)
	$(COMPOSE) build

ps: ## État des conteneurs
	$(COMPOSE) --profile test ps

logs: ## Journaux en direct : make logs [s=api|database]
	$(COMPOSE) logs -f --tail=100 $(s)

sh: ## Shell dans le conteneur de l'API
	$(EXEC_API) bash

## —— 🐘 Symfony ——————————————————————————————————————————————————————————————
sf: ## Console Symfony : make sf c="make:entity Team"
	$(EXEC_API) php bin/console $(c)

composer: ## Composer : make composer c="require symfony/uid"
	$(EXEC_API) composer $(c)

cc: ## Vide le cache Symfony
	$(EXEC_API) php bin/console cache:clear

db-update: ## Met à jour les tables d'après vos entités (sans perdre les données)
	$(EXEC_API) php bin/console doctrine:schema:update --force --dump-sql

db-reset: ## Recrée la base de dev et recharge les données de démo si elles existent (⚠ efface tout)
	$(EXEC_API) php bin/console doctrine:schema:drop --force --full-database -q
	$(EXEC_API) php bin/console doctrine:schema:create -q
	@if [ -d api/src/DataFixtures ]; then \
		$(EXEC_API) php bin/console doctrine:fixtures:load -n -q && printf "$(GREEN)✔ Données de démo chargées (identifiants 1, 2, 3...)$(RESET)\n"; \
	else printf "  (pas encore de données de démo : elles arrivent à l'étape 5 du TP)\n"; fi

## —— ✅ Tests ————————————————————————————————————————————————————————————————
test: test-env test-db ## Lance les tests Hurl : make test · make test f=02 · make test ERRORS=long
	$(HURL) $(HURL_FLAGS) $(if $(REPORT),--report-junit /reports/j0.xml) --glob '$(or $(f),)*.hurl'

report: ## Rapport JUnit dans reports/ (pour l'enseignant)
	@mkdir -p reports && rm -f reports/*.xml
	-@$(MAKE) --no-print-directory test REPORT=1
	@printf "\nRapport écrit dans reports/j0.xml\n"

test-env:
	@$(COMPOSE) --profile test up -d --wait api-test >/dev/null

test-db:
	@$(EXEC_TEST) php bin/console doctrine:database:create --if-not-exists -q
	@$(EXEC_TEST) php bin/console doctrine:schema:drop --force --full-database -q
	@$(EXEC_TEST) php bin/console doctrine:schema:create -q
