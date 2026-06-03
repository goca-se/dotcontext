# dotcontext build system
# Bundles src/ modules into a single executable

SOURCES = \
	src/header.sh \
	src/core/colors.sh \
	src/core/icons.sh \
	src/core/ui.sh \
	src/core/spinner.sh \
	src/core/utils.sh \
	src/setup/notifications.sh \
	src/setup/mcp.sh \
	src/setup/agents.sh \
	src/commands/init.sh \
	src/commands/update.sh \
	src/commands/doctor.sh \
	src/commands/help.sh \
	src/commands/completion.sh \
	src/main.sh

OUTPUT = dotcontext

.PHONY: build clean

build: $(OUTPUT)

$(OUTPUT): $(SOURCES)
	@echo "Building $(OUTPUT)..."
	@cat $(SOURCES) > $(OUTPUT)
	@chmod +x $(OUTPUT)
	@echo "Done: $(OUTPUT) ($$(wc -l < $(OUTPUT)) lines)"

clean:
	@rm -f $(OUTPUT)
