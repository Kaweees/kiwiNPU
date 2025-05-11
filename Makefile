# Makefile for compiling, linking, and building the program.
# Begin Variables Section

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
# directory to locate source files
SRC_DIR := $(TOP_DIR)/src
# directory to locate testbench files
TB_DIR := $(SRC_DIR)/tb
# directory to locate header files
INC_DIR := $(TOP_DIR)/include
# directory to locate object files
OBJ_DIR := $(TOP_DIR)/obj
# directory to place build artifacts
BUILD_DIR := $(TOP_DIR)/target/$(ARCH)/release/

# Define recursive wildcard function
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

# header files to preprocess
INCS := -I$(call rwildcard,$(INC_DIR)/,*.svh) -I$(call rwildcard,$(SRC_DIR)/,*.vh) -I$(PDKPATH)
# source files to compile
RTL_SRCS := $(call rwildcard,$(SRC_DIR)/,*.sv) $(call rwildcard,$(SRC_DIR)/,*.v)
# assembly files to compile
TB_SRCS := $(call rwildcard,$(TB_DIR)/,*.sv) $(call rwildcard,$(TB_DIR)/,*.v)
# object files to link
OBJS := $(patsubst $(SRC_DIR)/%.sv, $(OBJ_DIR)/%.o, $(filter %.sv,$(RTL_SRCS))) \
             $(patsubst $(SRC_DIR)/%.v, $(OBJ_DIR)/%.o, $(filter %.v,$(RTL_SRCS)))
