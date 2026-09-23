SHELL := /bin/sh

FLUTTER ?= flutter
DART ?= dart
# Build one device ABI by default; override for an x86_64 emulator.
EXAMPLE_ANDROID_TARGET_PLATFORMS ?= android-arm64

.DEFAULT_GOAL := help

.PHONY: help pub-get format format-check analyze test example-pub-get example-generate example-analyze example-test example-verify example-build packaged-example doc pana verify boundary publish-check ci rename clean

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Remove build artifacts and temporary files
	$(FLUTTER) clean
	@rm -rf build doc/api .dart_tool
	@if [ -d "example" ]; then cd example && $(FLUTTER) clean && rm -rf build .dart_tool android/.gradle; fi


pub-get: ## Resolve package dependencies

	$(FLUTTER) pub get

rename: ## Rename the package everywhere; requires NAME=my_company_sdk
	@test -n "$(NAME)" || (echo "NAME is required, e.g. make rename NAME=my_company_sdk"; exit 2)
	$(DART) run tool/rename_package.dart $(NAME)

format: ## Format all Dart files
	$(DART) format .

format-check: example-generate ## Verify formatting without changing files
	$(DART) format --output=none --set-exit-if-changed .

example-pub-get: ## Resolve example host dependencies
	cd example && $(FLUTTER) pub get

example-generate: example-pub-get ## Generate Riverpod providers for the example host
	cd example && $(DART) run build_runner build && $(DART) format lib

example-analyze: example-generate ## Analyze the example host
	cd example && $(FLUTTER) analyze --fatal-infos

example-test: example-generate ## Test the example host
	cd example && $(FLUTTER) test -j 8

example-verify: example-analyze example-test ## Run the example host gates

example-build: example-generate ## Build the optimized debug Android example
	cd example && $(FLUTTER) build apk --debug --no-pub --target-platform "$(EXAMPLE_ANDROID_TARGET_PLATFORMS)"

packaged-example: ## Verify the example consumes an SDK staged from git archive HEAD; requires PLATFORM=android|ios
	@test -n "$(PLATFORM)" || (echo "PLATFORM is required, e.g. make packaged-example PLATFORM=android"; exit 2)
	@case "$(PLATFORM)" in android|ios) ;; *) echo "PLATFORM must be android or ios"; exit 2 ;; esac
	./tool/verify_packaged_example.sh --platform "$(PLATFORM)"

analyze: ## Run static analysis with infos treated as errors
	$(FLUTTER) analyze --fatal-infos

test: ## Run the package test suite
	$(FLUTTER) test -j 8

doc: ## Generate API documentation and fail on unresolved links
	$(DART) doc --validate-links

pana: ## Run Pana with no missing package-quality points
	$(DART) pub global activate pana
	$(DART) pub global run pana . --exit-code-threshold 0

boundary: ## Fail if lib/src reaches into Flutter UI or dart:io
	@! grep -rn "package:flutter/material.dart\|package:flutter/widgets.dart\|package:flutter/services.dart\|dart:io" lib/ \
	  || (echo "BOUNDARY VIOLATION in lib/"; exit 1)
	@echo "boundary ok"

publish-check: ## Verify the package would publish cleanly
	$(FLUTTER) pub publish --dry-run

verify: format-check analyze boundary test example-verify ## Local pre-commit gate

ci: pub-get verify doc pana publish-check ## CI-equivalent local gate
