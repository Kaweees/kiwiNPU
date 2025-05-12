# Makefile for simulating, linting, and testing the program.
# Begin Variables Section

## Program Section: change these variables based on your program
# -----------------------------------------------------------------------------
# The name of the program to build.
TARGET := kiwiNPU

## Simulator Section: change these variables based on your simulator
# -----------------------------------------------------------------------------
# The simulator executable.
SIM := verilator
# The simulator flags.
SIM_FLAGS := -binary --timing --trace --trace-structs --assert --timescale 1ns --quiet
# The linter executable.
LINT := verilator
# The linter flags.
LINT_FLAGS := --lint-only --timing

# The shell executable.
SHELL := /bin/bash

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
OBJ_DIR := $(TOP_DIR)/obj_dir
# directory to place build artifacts
BUILD_DIR := $(TOP_DIR)/target/$(ARCH)/release/

# Define recursive wildcard function
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

# header files to preprocess
INCS := -I$(call rwildcard,$(INC_DIR)/,*.svh) -I$(call rwildcard,$(RTL_DIR)/,*.vh) -I$(PDKPATH)
# source files to compile
RTL_SRCS := $(call rwildcard,$(RTL_DIR)/,*.sv) $(call rwildcard,$(RTL_DIR)/,*.v)
# assembly files to compile
TB_SRCS := $(call rwildcard,$(TB_DIR)/,*.sv) $(call rwildcard,$(TB_DIR)/,*.v)
# object files to link
OBJS := $(OBJ_DIR)/V*

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
.PHONY: all lint test clean help

# Default target: build the program
all: lint test

# Lint target: lint the source files
lint:
	@printf "\n$(GREEN)$(BOLD) ----- Linting All Modules ----- $(RESET)\n"
	@for src in $(RTL_SRCS); do \
		top_module=$$(basename $$src .sv); \
		top_module=$$(basename $$top_module .v); \
		printf "Linting $$src . . . "; \
		if $(LINT) $(LINT_FLAGS) --top-module $$top_module $$src > /dev/null 2>&1; then \
			printf "$(GREEN)PASSED$(RESET)\n"; \
		else \
			printf "$(RED)FAILED$(RESET)\n"; \
			$(LINT) $(LINT_FLAGS) --top-module $$top_module $$src; \
		fi; \
	done

# Test target: run the testbench
test:
	@printf "\n$(GREEN)$(BOLD) ----- Running Test: $@ ----- $(RESET)\n"
	@printf "\n$(BOLD) Building with $(SIM)... $(RESET)\n"

	@# Build With Simulator
	@cd $(TB_DIR);\
		$(SIM) $(SIM_FLAGS) $(INCS) $(RTL_SRCS) $(TB_SRCS) > build.log

	@printf "\n$(BOLD) Running... $(RESET)\n"

	@# Run Binary and Check for Error in Result
	@if cd $(TB_DIR);\
		$(OBJS) > results.log \
		&& ! ( cat results.log | grep -qi error ) \
		then \
			printf "$(GREEN)PASSED $@$(RESET)\n"; \
		else \
			printf "$(RED)FAILED $@$(RESET)\n"; \
			cat results.log; \
		fi; \

# Clean target: remove build artifacts and non-essential files
clean:
	@echo "Cleaning $(TARGET)..."
	@rm -rf $(OBJ_DIR)
	@rm -f `find $(TB_DIR) -iname "*.vcd"`
	@rm -f `find $(TB_DIR) -iname "*.log"`
	@rm -f `find $(TB_DIR) -iname "a.out"`
	@rm -rf `find $(TB_DIR) -iname "obj_dir"`
