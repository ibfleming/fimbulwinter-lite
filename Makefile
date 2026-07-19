# Fimbulwinter Lite - developer task runner
#
# Run `make` (or `make help`) to list targets.
# Pass script flags through ARGS, e.g.:  make deploy-full ARGS='--yes --no-restart'
#
# Note: server-install.sh and server-autoupdate.sh are server-side scripts
# executed by the Pelican egg on the game server; they are intentionally not
# exposed as targets here.

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

TOML ?= thunderstore.toml
ARGS ?=
OUT  ?=

.PHONY: help version updates profile build deploy-configs deploy-full deploy-reinstall install-mods release-check clean

help: ## Show this help message
	@echo "Fimbulwinter Lite - available targets:"
	@echo
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo
	@echo "Variables (append VAR=value to any target):"
	@echo "  ARGS='...'   extra flags passed through to the script"
	@echo "               deploy-*:     --yes  --no-restart"
	@echo "               install-mods: --server-dir DIR --source thunderstore|local --repo-dir . --full"
	@echo "  TOML=path    toml used by 'updates' (default: thunderstore.toml)"
	@echo "  OUT=path     output path for 'profile' (default: dist/)"
	@echo
	@echo "Examples:"
	@echo "  make profile"
	@echo "  make updates"
	@echo "  make deploy-configs ARGS='--yes'"
	@echo "  make deploy-full ARGS='--yes --no-restart'"
	@echo "  make release-check"

version: ## Print the current package version from thunderstore.toml
	@grep -Po 'versionNumber = "\K[^"]+' $(TOML)

updates: ## Check Thunderstore for outdated mods (scripts/update-mods.sh)
	bash scripts/update-mods.sh $(TOML)

profile: ## Build the distributable .r2z profile into dist/ (scripts/export-profile.sh)
	bash scripts/export-profile.sh $(OUT)

build: ## Build the Thunderstore package zip with tcli (output in build/)
	tcli build --config-path $(TOML)

deploy-configs: ## Push config/ to the live server and restart (scripts/deploy.sh configs)
	bash scripts/deploy.sh configs $(ARGS)

deploy-full: ## Stage local toml-resolved mods + configs to the server (scripts/deploy.sh full)
	bash scripts/deploy.sh full $(ARGS)

deploy-reinstall: ## Panel reinstall pulling the latest PUBLISHED pack (scripts/deploy.sh reinstall)
	bash scripts/deploy.sh reinstall $(ARGS)

install-mods: ## Run the shared mod resolver/installer (needs ARGS, e.g. ARGS='--server-dir /tmp/x --source local --repo-dir .')
	@if [ -z "$(ARGS)" ]; then \
		echo "install-mods requires ARGS, e.g.:"; \
		echo "  make install-mods ARGS='--server-dir /tmp/stage --source local --repo-dir .'"; \
		exit 1; \
	fi
	bash scripts/install-mods.sh $(ARGS)

release-check: ## Verify version, CHANGELOG, tag, and working tree are release-ready
	@set -e; \
	v=$$(grep -Po 'versionNumber = "\K[^"]+' $(TOML)); \
	echo "toml version:  $$v"; \
	if grep -q "^## \[$$v\]" CHANGELOG.md; then \
		echo "CHANGELOG:     [$$v] section present"; \
	else \
		echo "CHANGELOG:     MISSING [$$v] section"; exit 1; \
	fi; \
	git fetch --tags --quiet 2>/dev/null || true; \
	if git rev-parse "v$$v" >/dev/null 2>&1; then \
		echo "tag v$$v:    ALREADY EXISTS - bump the version before tagging"; exit 1; \
	else \
		echo "tag v$$v:    available"; \
	fi; \
	if [ -n "$$(git status --porcelain)" ]; then \
		echo "working tree:  DIRTY - commit before tagging"; \
	else \
		echo "working tree:  clean"; \
	fi; \
	echo "release-check: OK (tag with: git tag v$$v && git push origin v$$v)"

clean: ## Remove tcli build output (build/)
	rm -rf build/
	@echo "removed build/ (dist/ kept - remove manually if desired)"
