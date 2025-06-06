#!/bin/bash

# Format script called by the CI
# Usage:
#    format.sh format

#
#  Private Impl
#

# Default formatting style options for consistent code style
FORMAT_OPTIONS=(
  # Basic formatting
  "--indentation_spaces=2"        # Use 2 spaces for indentation
  "--wrap_spaces=2"              # Use 2 spaces for line wrapping

  # Alignment options
  "--assignment_statement_alignment=align"    # Align assignment statements
  "--case_items_alignment=align"             # Align case items
  "--class_member_variable_alignment=align"  # Align class member variables
  "--port_declarations_alignment=align"      # Align port declarations
  "--named_parameter_alignment=align"        # Align named parameters
  "--named_port_alignment=align"             # Align named ports
  "--module_net_variable_alignment=align"    # Align module net variables
  "--formal_parameters_indentation=indent"   # Indent formal parameters
)

format() {
  # Find and format all SystemVerilog files
  # -type f: only match files
  # -name "*.vh" -o -name "*.svh" -o -name "*.sv" -o -name "*.v": match all SystemVerilog extensions
  # -exec: execute the command for each file found
  find . -type f \( -name "*.vh" -o -name "*.svh" -o -name "*.sv" -o -name "*.v" \) \
    -exec verible-verilog-format "${FORMAT_OPTIONS[@]}" --inplace {} \;
}

# Main script logic
case "$1" in
  format)
    format
    ;;
  *)
    echo "Usage: $0 {format}"
    exit 1
    ;;
esac
