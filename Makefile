SCRIPTS := sys vpn run conn cron http
BIN_DIR := $(HOME)/.local/bin
SRC_DIR := $(shell pwd)/bin
LIB_DIR := $(shell pwd)/lib

.PHONY: install uninstall

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
