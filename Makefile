SCRIPTS := sys vpn run conn cron http dk dkc stress
BIN_DIR := $(HOME)/.local/bin
SRC_DIR := $(shell pwd)/bin
LIB_DIR := $(shell pwd)/lib

.PHONY: install uninstall test

install:
	@mkdir -p $(BIN_DIR)
	@chmod +x $(addprefix bin/,$(SCRIPTS))
	@chmod +x $(LIB_DIR)/*.sh
	@for script in $(SCRIPTS); do \
		ln -sf $(SRC_DIR)/$$script $(BIN_DIR)/$$script; \
		echo "  linked: $(BIN_DIR)/$$script -> $(SRC_DIR)/$$script"; \
	done
	@echo "Done."

uninstall:
	@for script in $(SCRIPTS); do \
		rm -f $(BIN_DIR)/$$script; \
		echo "  removed: $(BIN_DIR)/$$script"; \
	done
	@echo "Done."

# Runs the bats-core test suite in test/. Requires the `bats` binary on
# PATH (install via https://github.com/bats-core/bats-core, or your OS
# package manager: apt/dnf install bats, brew install bats-core).
test:
	@command -v bats >/dev/null 2>&1 || { \
		echo "bats not found. Install bats-core: https://github.com/bats-core/bats-core#installation"; \
		exit 1; \
	}
	@bats test/
