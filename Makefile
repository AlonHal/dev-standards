# dev-standards' own Makefile — NOT copied from templates/Makefile,
# which is written for a deployable app (Flutter/backend). This repo is
# docs + copyable templates, so `check`/`test`/`build` validate those
# instead of building anything.
# See DEVELOPMENT_ENVIRONMENT_STANDARDS.md §4, §10 Phase 1/2

GITLEAKS := $(shell command -v gitleaks 2>/dev/null || echo $(HOME)/.venvs/dev-tools/bin/gitleaks)

.PHONY: check test build all

check:
	@echo "== gitleaks secret scan =="
	@$(GITLEAKS) detect --no-git -v

test:
	@echo "== shell syntax check: templates/scripts/*.sh, scripts/*.sh =="
	@for f in templates/scripts/*.sh scripts/*.sh; do \
		echo "checking $$f"; \
		bash -n "$$f" || exit 1; \
	done
	@echo "all scripts syntactically valid"

build:
	@echo "nothing to build — docs + templates repo"

all: check test build
