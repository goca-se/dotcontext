# dotcontext build system
# Bundles src/ modules into a single executable

SOURCES = \
	src/header.sh \
	src/core/colors.sh \
	src/core/icons.sh \
	src/core/ui.sh \
	src/core/spinner.sh \
	src/core/utils.sh \
	src/lib/ui/menu_paginated.sh \
	src/lib/ui/multi_select.sh \
	src/lib/ui/detail_pane.sh \
	src/lib/ui/confirm.sh \
	src/lib/ui/spinner_alt.sh \
	src/lib/ui/tabs.sh \
	src/lib/marketplace/manifest.sh \
	src/lib/marketplace/lockfile.sh \
	src/lib/marketplace/scope.sh \
	src/lib/marketplace/bundle.sh \
	src/lib/marketplace/migrate.sh \
	src/lib/install/command.sh \
	src/lib/install/skill.sh \
	src/lib/install/script.sh \
	src/lib/install/mcp.sh \
	src/lib/install/hook.sh \
	src/lib/install/cli.sh \
	src/lib/install/dispatch.sh \
	src/setup/notifications.sh \
	src/setup/mcp.sh \
	src/commands/init.sh \
	src/commands/update.sh \
	src/commands/help.sh \
	src/commands/browse.sh \
	src/main.sh

OUTPUT = dotcontext

MANIFEST = marketplace/manifest.json

.PHONY: build clean validate-manifest check-ui check

build: $(OUTPUT)

$(OUTPUT): $(SOURCES)
	@echo "Building $(OUTPUT)..."
	@cat $(SOURCES) > $(OUTPUT)
	@chmod +x $(OUTPUT)
	@echo "Done: $(OUTPUT) ($$(wc -l < $(OUTPUT)) lines)"

validate-manifest:
	@bash scripts/validate-manifest.sh

check-ui:
	@bash tests/ui/syntax_check.sh

check: validate-manifest check-ui

clean:
	@rm -f $(OUTPUT)
