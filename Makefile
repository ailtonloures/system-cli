SCRIPTS := sys vpn run conn cron http dk dkc stress
BIN_DIR := $(HOME)/.local/bin
SRC_DIR := $(shell pwd)/bin
LIB_DIR := $(shell pwd)/lib

COMPLETIONS_DIR_BASH := $(HOME)/.local/share/bash-completion/completions
COMPLETIONS_DIR_ZSH  := $(HOME)/.local/share/zsh/site-functions

.PHONY: install uninstall install-completions test version

install:
	@mkdir -p $(BIN_DIR)
	@chmod +x $(addprefix bin/,$(SCRIPTS))
	@chmod +x $(LIB_DIR)/*.sh
	@for script in $(SCRIPTS); do \
		ln -sf $(SRC_DIR)/$$script $(BIN_DIR)/$$script; \
		echo "  linked: $(BIN_DIR)/$$script -> $(SRC_DIR)/$$script"; \
	done
	@echo "Done."
	@echo "$$PATH" | tr ':' '\n' | grep -qx "$(BIN_DIR)" \
		|| echo "  ⚠  $(BIN_DIR) is not in your PATH. Add it to your shell profile."

install-completions:
	@mkdir -p $(COMPLETIONS_DIR_BASH) $(COMPLETIONS_DIR_ZSH)
	@for f in completions/*.bash; do \
		name=$$(basename "$$f" .bash); \
		cp "$$f" "$(COMPLETIONS_DIR_BASH)/$$name"; \
		echo "  installed: $(COMPLETIONS_DIR_BASH)/$$name"; \
	done
	@for f in completions/*.zsh; do \
		name=$$(basename "$$f" .zsh); \
		cp "$$f" "$(COMPLETIONS_DIR_ZSH)/_$$name"; \
		echo "  installed: $(COMPLETIONS_DIR_ZSH)/_$$name"; \
	done
	@echo "Done. Restart your shell to activate completions."

test:
	@bats test/

version:
	@cat VERSION

uninstall:
	@for script in $(SCRIPTS); do \
		rm -f $(BIN_DIR)/$$script; \
		echo "  removed: $(BIN_DIR)/$$script"; \
	done
	@echo "Done."
