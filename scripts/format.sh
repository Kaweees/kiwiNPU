#!/bin/bash

# Format script called by the CI
# Usage:
#    format.sh format

#
#  Private Impl
#

# Default formatting style options
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
  # Find all SystemVerilog files
  files=$(find . -name "*.vh" -o -name "*.svh" -o -name "*.sv" -o -name "*.v")

  if [ -z "$files" ]; then
    echo "No SystemVerilog files found"
    return 0
  fi

  # Format each file and capture any errors
  error=0
  # Format each file
  for file in $files; do
    if ! verible-verilog-format "${FORMAT_OPTIONS[@]}" --inplace "$file"; then
      echo "Error formatting $file"
      error=1
    fi
  done

  if [ $error -eq 0 ]; then
    echo "Successfully formatted all files"
    return 0
  else
    echo "Errors occurred during formatting"
    return 1
  fi
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
