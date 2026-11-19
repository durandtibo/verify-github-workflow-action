SHELL = /bin/bash

include .make/all.mk

.PHONY : zizmor
zizmor: install-zizmor ## Run zizmor with autofixes on the GitHub workflows
	@echo "🔍 Running zizmor with autofixes on GitHub workflows..."
	-zizmor --fix=all .github/workflows
	@echo "✅ Zizmor autofix complete (review any remaining findings above)"
	@echo ""

.PHONY : check-readme-sync
check-readme-sync: ## Check that README.md and action.yaml describe the same inputs
	@./dev/check_readme_sync.sh

.PHONY : all
all: format lint ## Format and lint everything

.PHONY : test
test: check-readme-sync ## Run the local checks (the action itself is only tested by CI)

.PHONY : clean
clean: ## Nothing to clean: the action has no build artifacts
	@echo "Nothing to clean"
