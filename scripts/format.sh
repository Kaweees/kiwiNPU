#!/bin/bash

# Format script called by the CI
# Usage:
#    format.sh format

#
#  Private Impl
#

# Default formatting style options
FORMAT_OPTIONS=(
  "--indentation_spaces=2"
  "--wrap_spaces=2"
  "--assignment_statement_alignment=align"
  "--case_items_alignment=align"
  "--class_member_variable_alignment=align"
  "--port_declarations_alignment=align"
  "--named_parameter_alignment=align"
  "--named_port_alignment=align"
  "--module_net_variable_alignment=align"
  "--formal_parameters_indentation=indent"
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
