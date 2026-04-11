# DJ-Engine Releases — Makefile
#
# Unified command interface for building engine binaries and packaging games.
#
# Usage:
#   make build-engine DJ_ENGINE_DIR=/path/to/DJ-Engine
#   make package-djproj PROJECT_DIR=/path/to/game
#   make package-djpak PROJECT_DIR=/path/to/game
#   make verify PACKAGE=game.djpak
#   make all DJ_ENGINE_DIR=/path/to/DJ-Engine PROJECT_DIR=/path/to/game

.PHONY: all build-engine package-djproj package-djpak verify verify-djpak verify-djproj clean help

# --- Configuration ---

DJ_ENGINE_DIR ?=
PROJECT_DIR   ?=
PACKAGE       ?=
OUTPUT_DIR    ?= releases
ENGINE_VERSION ?= 0.1.0
GAME_VERSION   ?= 0.1.0
GAME_NAME      ?= $(shell basename "$(PROJECT_DIR)" 2>/dev/null || echo "game")

# --- Targets ---

help: ## Show this help
	@echo "DJ-Engine Releases"
	@echo ""
	@echo "Usage:"
	@echo "  make build-engine DJ_ENGINE_DIR=<path>    Build engine binaries (.exe + Linux)"
	@echo "  make package-djproj PROJECT_DIR=<path>    Package project as .djproj (editable)"
	@echo "  make package-djpak PROJECT_DIR=<path>     Package project as .djpak (playable)"
	@echo "  make verify PACKAGE=<file.djpak>          Verify a .djpak integrity"
	@echo "  make generate-project PROJECT_DIR=<path>  Generate project.json from game assets"
	@echo "  make clean                                 Remove staged release artifacts"
	@echo ""
	@echo "Options:"
	@echo "  DJ_ENGINE_DIR    Path to DJ-Engine source repo"
	@echo "  PROJECT_DIR      Path to game project directory"
	@echo "  PACKAGE          Path to .djpak file for verification"
	@echo "  OUTPUT_DIR       Output directory (default: releases/)"
	@echo "  ENGINE_VERSION   Engine version tag (default: 0.1.0)"
	@echo "  GAME_VERSION     Game version tag (default: 0.1.0)"

all: build-engine package-djpak package-djproj ## Build everything

build-engine: ## Build DJ-Engine binaries
	@if [ -z "$(DJ_ENGINE_DIR)" ]; then \
		echo "Error: DJ_ENGINE_DIR is required"; \
		echo "Usage: make build-engine DJ_ENGINE_DIR=/path/to/DJ-Engine"; \
		exit 1; \
	fi
	@mkdir -p $(OUTPUT_DIR)
	@bash scripts/build-engine.sh "$(DJ_ENGINE_DIR)" \
		--output-dir "$(OUTPUT_DIR)" \
		--version "$(ENGINE_VERSION)"

package-djproj: ## Package a project as .djproj (editable)
	@if [ -z "$(PROJECT_DIR)" ]; then \
		echo "Error: PROJECT_DIR is required"; \
		echo "Usage: make package-djproj PROJECT_DIR=/path/to/game"; \
		exit 1; \
	fi
	@mkdir -p $(OUTPUT_DIR)
	@bash scripts/package-djproj.sh "$(PROJECT_DIR)" \
		"$(OUTPUT_DIR)/$(GAME_NAME)-$(GAME_VERSION).djproj"

package-djpak: ## Package a project as .djpak (playable)
	@if [ -z "$(PROJECT_DIR)" ]; then \
		echo "Error: PROJECT_DIR is required"; \
		echo "Usage: make package-djpak PROJECT_DIR=/path/to/game"; \
		exit 1; \
	fi
	@mkdir -p $(OUTPUT_DIR)
	@bash scripts/package-djpak.sh "$(PROJECT_DIR)" \
		"$(OUTPUT_DIR)/$(GAME_NAME)-$(GAME_VERSION).djpak" \
		--engine-version "$(ENGINE_VERSION)"

verify: verify-djpak ## Verify a .djpak package (alias for verify-djpak)

verify-djpak: ## Verify a .djpak package
	@if [ -z "$(PACKAGE)" ]; then \
		echo "Error: PACKAGE is required"; \
		echo "Usage: make verify-djpak PACKAGE=game.djpak"; \
		exit 1; \
	fi
	@bash scripts/verify-djpak.sh "$(PACKAGE)"

verify-djproj: ## Verify a .djproj package
	@if [ -z "$(PACKAGE)" ]; then \
		echo "Error: PACKAGE is required"; \
		echo "Usage: make verify-djproj PACKAGE=game.djproj"; \
		exit 1; \
	fi
	@bash scripts/verify-djproj.sh "$(PACKAGE)"

generate-project: ## Generate project.json from game assets
	@if [ -z "$(PROJECT_DIR)" ]; then \
		echo "Error: PROJECT_DIR is required"; \
		echo "Usage: make generate-project PROJECT_DIR=/path/to/game"; \
		exit 1; \
	fi
	@python3 scripts/generate-project-json.py "$(PROJECT_DIR)" \
		--name "$(GAME_NAME)" \
		--version "$(GAME_VERSION)"

clean: ## Remove staged release artifacts
	@echo "Cleaning release artifacts..."
	@rm -rf $(OUTPUT_DIR)/*.exe $(OUTPUT_DIR)/*.djproj $(OUTPUT_DIR)/*.djpak
	@rm -rf $(OUTPUT_DIR)/dj_engine $(OUTPUT_DIR)/dj_engine-*
	@rm -rf .package-tmp/
	@echo "Done."
