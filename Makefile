SHELL := /bin/sh

FLUTTER ?= flutter
DART ?= dart

.DEFAULT_GOAL := help

.PHONY: help pub-get format format-check analyze test verify boundary publish-check ci rename

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

pub-get: ## Resolve package dependencies
	$(FLUTTER) pub get

rename: ## Rename the package everywhere; requires NAME=my_company_sdk
	@test -n "$(NAME)" || (echo "NAME is required, e.g. make rename NAME=my_company_sdk"; exit 2)
	$(DART) run tool/rename_package.dart $(NAME)

format: ## Format all Dart files
	$(DART) format .

format-check: ## Verify formatting without changing files
	$(DART) format --output=none --set-exit-if-changed .

analyze: ## Run static analysis with infos treated as errors
	$(FLUTTER) analyze --fatal-infos

test: ## Run the package test suite
	$(FLUTTER) test

boundary: ## Fail if lib/src reaches into Flutter UI or dart:io
	@! grep -rn "package:flutter/material.dart\|package:flutter/widgets.dart\|package:flutter/services.dart\|dart:io" lib/ \
	  || (echo "BOUNDARY VIOLATION in lib/"; exit 1)
	@echo "boundary ok"

publish-check: ## Verify the package would publish cleanly
	$(FLUTTER) pub publish --dry-run

verify: format-check analyze boundary test ## Local pre-commit gate

ci: pub-get verify publish-check ## CI-equivalent local gate
