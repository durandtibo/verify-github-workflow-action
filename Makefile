SHELL=/bin/bash

# Makefile for verify-uv-build-action
#
# Available targets:
#   help    - Display this help message
#   format  - Run all formatting and linting checks

.PHONY : help
help :
	@echo "verify-uv-build-action - Available Make Targets"
	@echo ""
	@echo "  make help             - Display this help message"
	@echo "  make format           - Run all formatting and linting checks"
	@echo "  make format-markdown  - Run markdownlint and prettier on Markdown files"
	@echo "  make format-yaml      - Run yamllint on YAML files"
	@echo "  make zizmor           - Run zizmor with autofixes on GitHub workflows"
	@echo ""
	@echo "Formatting tools used:"
	@echo "  - markdownlint: Validates Markdown files"
	@echo "  - prettier: Formats various file types"
	@echo "  - yamllint: Validates YAML files"
	@echo "  - zizmor: Audits GitHub Actions workflows"
	@echo ""

.PHONY : format
format : format-markdown format-yaml
	@echo "🎉 All format checks passed!"

.PHONY : format-markdown
format-markdown :
	@command -v markdownlint >/dev/null 2>&1 || { \
		echo "📦 markdownlint not found, installing markdownlint-cli..."; \
		npm install -g markdownlint-cli; \
	}
	@command -v prettier >/dev/null 2>&1 || { \
		echo "📦 prettier not found, installing prettier..."; \
		npm install -g prettier; \
	}
	@echo "🔍 Running markdownlint on Markdown files..."
	markdownlint **/*.md
	@echo "✅ Markdownlint passed"
	@echo ""
	@echo "✨ Running prettier to format files..."
	prettier --write .
	@echo "✅ Prettier formatting complete"
	@echo ""

.PHONY : format-yaml
format-yaml :
	@command -v yamllint >/dev/null 2>&1 || { \
		echo "📦 yamllint not found, installing yamllint..."; \
		pip3 install --user yamllint; \
	}
	@echo "🔍 Running yamllint on YAML files..."
	yamllint -f colored .
	@echo "✅ Yamllint passed"
	@echo ""

.PHONY : zizmor
zizmor :
	@command -v zizmor >/dev/null 2>&1 || { \
		echo "📦 zizmor not found, installing zizmor..."; \
		pip3 install --user zizmor; \
	}
	@echo "🔍 Running zizmor with autofixes on GitHub workflows..."
	-zizmor --fix=all .github/workflows
	@echo "✅ Zizmor autofix complete (review any remaining findings above)"
	@echo ""

.DEFAULT_GOAL := help
