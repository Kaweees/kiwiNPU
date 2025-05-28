# Makefile for simulating, linting, and testing the program.
# Begin Variables Section

## Program Section: change these variables based on your program
# -----------------------------------------------------------------------------
# The name of the program to build.
TARGET := kiwiNPU

## Simulator Section: change these variables based on your simulator
# -----------------------------------------------------------------------------
# The simulator executable.
ifndef GL
SIM := verilator
else
SIM := iverilog
endif
# The simulator flags.
ifndef GL
SIM_FLAGS := -binary --timing --trace --trace-structs --assert --timescale 1ns --quiet
else
SIM_FLAGS := -g2012 -DFUNCTIONAL -DUSE_POWER_PINS
endif
# The linter executable.
LINT := verilator
# The linter flags.
LINT_FLAGS := --lint-only --timing

# The shell executable.
SHELL := /bin/bash

## PDK Section: change these variables based on your PDK
# -----------------------------------------------------------------------------
OPENLANE := `which openlane`
OPENLANE_CONF ?= config.*

# ## PDK Section: change these variables based on your
# # -----------------------------------------------------------------------------
# PDKPATH := $(shell pwd)/pdks

## Output Section: change these variables based on your output
# -----------------------------------------------------------------------------
# top directory of project
TOP_DIR := $(shell pwd)
# directory to locate register transfer level (RTL) files
RTL_DIR := $(TOP_DIR)/rtl
# directory to locate testbench (TB) files
TB_DIR := $(TOP_DIR)/tb
# directory to locate header files
INC_DIR := $(TOP_DIR)/include
# directory to locate object files
OBJ_DIR := $(TB_DIR)/obj_dir
# directory to place build artifacts
BUILD_DIR := $(TOP_DIR)/target/$(ARCH)/release/

# Define recursive wildcard function
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

# header files to preprocess
ifndef GL
INCS := -I$(call rwildcard,$(INC_DIR)/,*.svh) -I$(call rwildcard,$(INC_DIR)/,*.vh) -I$(PDKPATH) -I$(RTL_DIR)
else
INCS := -I$(realpath gl) -I$(PDKPATH)
endif
# source files to compile
RTL_SRCS := $(call rwildcard,$(RTL_DIR)/,*.sv) $(call rwildcard,$(RTL_DIR)/,*.v)
# testbench files to compile
TB_SRCS := $(call rwildcard,$(TB_DIR)/,*.sv) $(call rwildcard,$(TB_DIR)/,*.v)
# Extract just the names of the testbench modules (assuming they start with tb_)
TB_MODULES := $(notdir $(basename $(filter $(TB_DIR)/tb_%,$(TB_SRCS))))
# object files to link
ifndef GL
OBJS := $(OBJ_DIR)/V*
else
OBJS := $(TB_DIR)/obj_dir/V*
endif

# $(RTL_SRCS:.sv=.o) $(TB_SRCS:.v=.o)

## Colors Section: change these variables based on your desired colors
# -----------------------------------------------------------------------------
BOLD = `tput bold`
GREEN = `tput setaf 2`
ORANG = `tput setaf 214`
RED = `tput setaf 1`
RESET = `tput sgr0`

# Text formatting for tests
TEST_GREEN := $(shell tput setaf 2)
TEST_ORANGE := $(shell tput setaf 214)
TEST_RED := $(shell tput setaf 1)
TEST_RESET := $(shell tput sgr0)

## Command Section: change these variables based on your commands
# -----------------------------------------------------------------------------
# Targets
.PHONY: all install lint test gl openlane clean help

# Default target: build the program
all: clean install lint test

# Install target: generate testbenches
install:
	uv run scripts/dotproduct_generate.py
	uv run scripts/perceptron_generate.py
	uv run scripts/quantizer_generate.py

# Lint target: lint the source files
lint:
	@printf "\n$(GREEN)$(BOLD) ----- Linting All Modules with $(LINT) ----- $(RESET)\n"
	@for src in $(RTL_SRCS); do \
		top_module=$$(basename $$src .sv); \
		top_module=$$(basename $$top_module .v); \
		printf "Linting $$src . . . "; \
		if $(LINT) $(LINT_FLAGS) $(INCS) --top-module $$top_module $$src &> /dev/null; then \
			printf "$(GREEN)PASSED$(RESET)\n"; \
		else \
			printf "$(RED)FAILED$(RESET)\n"; \
			$(LINT) $(LINT_FLAGS) $(INCS) --top-module $$top_module $$src; \
		fi; \
	done

# Test target: run the testbenches
test:
	@printf "\n$(GREEN)$(BOLD) ----- Running All Testbenches with $(SIM) ----- $(RESET)\n";
	@mkdir -p $(OBJ_DIR)
	@for tb in $(TB_SRCS); do \
		top_module=$$(basename $$tb .sv); \
		top_module=$$(basename $$top_module .v); \
		printf "Testing $$tb . . . "; \
		cd $(TB_DIR) && \
			$(SIM) $(SIM_FLAGS) --top-module $$top_module $(INCS) $(RTL_SRCS) $$tb > $(TB_DIR)/build_$$top_module.log 2>&1; \
		cd $(TB_DIR) && \
		if [ -f $(OBJ_DIR)/V$$top_module ]; then \
			{ $(OBJ_DIR)/V$$top_module > results_$$top_module.log; } 2>/dev/null || true; \
			if ! ( cat $(TB_DIR)/results_$$top_module.log | grep -qi error ); then \
				printf "$(GREEN)PASSED $(RESET)\n"; \
			else \
				printf "$(RED)FAILED $(RESET)\n"; \
				cat $(TB_DIR)/results_$$top_module.log; \
			fi; \
		else \
			printf "$(RED)FAILED$(RESET)\n"; \
			cat $(TB_DIR)/build_$$top_module.log; \
		fi; \
	done

# Print available tests
list-tests:
	@printf "\n$(GREEN)$(BOLD) ----- Available Tests ----- $(RESET)\n"
	@for test in $(TB_MODULES); do \
		printf "  $$test\n"; \
	done

# GL target: run gate level verification (GL) tests
gl:
	@mkdir -p gl
	@cp runs/recent/final/pnl/* gl/
	@cat scripts/gatelevel.vh gl/*.v > gl/temp
	@mv -f gl/temp gl/*.v
	@rm -f gl/temp
	@GL=1 make test

# Openlane target: run openlane
openlane:
	@`which openlane` --flow Classic $(OPENLANE_CONF)
	@cd runs && rm -f recent && ln -sf `ls | tail -n 1` recent

# Openroad target: run openroad
openroad:
	@scripts/openroad_launch.sh | openroad

# Clean target: remove build artifacts and non-essential files
clean:
	@echo "Cleaning $(TARGET)..."
	@rm -rf $(OBJ_DIR)
	@rm -f `find $(TB_DIR) -iname "*.vcd"`
	@rm -f `find $(TB_DIR) -iname "*.log"`
	@rm -f `find $(TB_DIR) -iname "a.out"`
	@rm -rf `find $(TB_DIR) -iname "obj_dir"`
	@rm -rf runs
