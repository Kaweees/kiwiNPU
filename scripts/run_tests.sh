#!/bin/bash

# Run tests
# Usage:
#    run_tests.sh

#
#  Private Impl
#

run_tests() {
  make clean install lint
  make test -j"$(nproc)"
}

# Main script logic
set -e # Exit on error
run_tests
