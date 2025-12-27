#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "typer>=0.12.5",
#     "numpy>=1.24.0",
# ]
# ///
import math
import os
import random
from pathlib import Path
from typing import Any

import numpy as np
import typer

app = typer.Typer()


@app.command()
def generate(
    data_width: int = 8,
    n: int = 4,
    num_tests: int = 10,
    output_file: str = "include/preactivation_testcases.svh",
    seed: int | None = None,
):
    """
    Generate test cases for the preactivation module.

    data_width: Bit width of input vectors
    n: Vector dimensionality
    num_tests: Number of test cases to generate
    output_file: Output file path
    seed: Seed for RNG reproducibility
    """
    min_val: int = -(2 ** (data_width - 1))
    max_val: int = 2 ** (data_width - 1) - 1
    acc_width: int = data_width + data_width + math.ceil(math.log2(n))
    print(f"acc_width: {acc_width}")

    # Initialize random seed if provided
    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)

    print(f"Generating {num_tests} preactivation test cases with DATA_WIDTH={data_width}, ACC_WIDTH={acc_width}, N={n}")

    test_cases: list[dict[str, Any]] = []

    # Generate random test cases
    for i in range(num_tests):
        # Create test case with different strategies
        strategy = i % 6  # Six different strategies

        if strategy == 0:
            # Completely random values
            x = np.random.randint(min_val, max_val + 1, size=n)
            w = np.random.randint(min_val, max_val + 1, size=n)
        elif strategy == 1:
            # Small random values, less likely to overflow
            small_min = max(min_val // 4, -128)
            small_max = min(max_val // 4, 127)
            x = np.random.randint(small_min, small_max + 1, size=n)
            w = np.random.randint(small_min, small_max + 1, size=n)
        elif strategy == 2:
            # Positive/negative mix with low probability of overflow
            x = np.random.randint(0, max_val // 2 + 1, size=n)
            w = np.random.randint(min_val // 2, 1, size=n)
        elif strategy == 3:
            # Some values close to limits to test edge cases
            choices = np.array([min_val, max_val])
            x = np.array([np.random.choice(choices) for _ in range(n)])
            w = np.array([np.random.choice(choices) for _ in range(n)])
        elif strategy == 4:
            # Non-saturating: ensure dot(x, w) + b is within [-100, 100]
            x = np.random.randint(-8, 9, size=n)
            w = np.random.randint(-8, 9, size=n)
            dot_product = int(np.dot(x, w))
            # Pick b so that result stays in range
            min_b = max(min_val, -100 - dot_product)
            max_b = min(max_val, 100 - dot_product)
            b = np.random.randint(min_b, max_b + 1)
        else:
            # Some values close to limits to test edge cases
            choices = np.array([min_val, max_val])
            x = np.array([np.random.choice(choices) for _ in range(n)])
            w = np.array([np.random.choice(choices) for _ in range(n)])

        # Calculate expected dot product with saturation using numpy
        expected = int(np.dot(x, w))

        test_cases.append(
            {
                "x": x.tolist(),
                "w": w.tolist(),
                "expected": expected,
                "name": f"random_{i + 1}",
            }
        )

    # Write test cases to SystemVerilog file
    output_path = Path(output_file)
    output_path.parent.mkdir(exist_ok=True, parents=True)

    with open(output_path, "w") as f:
        f.write(f"// Auto-generated test cases by {os.path.basename(__file__)}\n")
        f.write(f"// DATA_WIDTH={data_width}, ACC_WIDTH={acc_width}, N={n}, NUM_TESTS={num_tests}\n")
        f.write("// THIS IS A HEADER FILE - DO NOT ATTEMPT TO COMPILE DIRECTLY\n\n")

        f.write("`ifndef PREACTIVATION_TESTCASES_SVH\n")
        f.write("`define PREACTIVATION_TESTCASES_SVH\n\n")

        f.write(f"localparam int NUM_PREACTIVATION_TEST = {len(test_cases)};\n\n")

        # Write test case arrays
        f.write("// Test vectors\n")
        f.write(f"logic signed [{data_width - 1}:0] preactivation_test_x[NUM_PREACTIVATION_TEST][{n}];\n")
        f.write(f"logic signed [{data_width - 1}:0] preactivation_test_w[NUM_PREACTIVATION_TEST][{n}];\n")
        f.write(f"logic signed [{data_width - 1}:0] preactivation_test_b[NUM_PREACTIVATION_TEST];\n")
        f.write(f"logic signed [{acc_width - 1}:0] preactivation_test_expected[NUM_PREACTIVATION_TEST];\n")

        f.write("// Initialize test cases\n")
        f.write("function void init_preactivation_test_cases();\n")

        for i, test in enumerate(test_cases):
            # Write vector A
            f.write(f"  // Test case {i}: {test['name']}\n")
            for j in range(n):
                # Fix for negative numbers in SystemVerilog
                val = test["x"][j]
                if val < 0:
                    # For negative numbers, use hex format with full bit pattern
                    # Calculate 2's complement representation
                    hex_val = format((1 << data_width) + val, f"0{(data_width + 3) // 4}x")
                    f.write(f"  preactivation_test_x[{i}][{j}] = {data_width}'h{hex_val};\n")
                else:
                    f.write(f"  preactivation_test_x[{i}][{j}] = {data_width}'d{val};\n")

            # Write vector B
            for j in range(n):
                # Fix for negative numbers in SystemVerilog
                val = test["w"][j]
                if val < 0:
                    # For negative numbers, use hex format with full bit pattern
                    hex_val = format((1 << data_width) + val, f"0{(data_width + 3) // 4}x")
                    f.write(f"  preactivation_test_w[{i}][{j}] = {data_width}'h{hex_val};\n")
                else:
                    f.write(f"  preactivation_test_w[{i}][{j}] = {data_width}'d{val};\n")

            # Add bias value generation and writing
            b = np.random.randint(min_val, max_val + 1)  # Generate random bias
            if b < 0:
                hex_val = format((1 << data_width) + b, f"0{(data_width + 3) // 4}x")
                f.write(f"  preactivation_test_b[{i}] = {data_width}'h{hex_val};\n")
            else:
                f.write(f"  preactivation_test_b[{i}] = {data_width}'d{b};\n")

            # Update expected output to include bias
            val = test["expected"] + b  # Add bias to expected value
            if val < 0:
                hex_val = format((1 << acc_width) + val, f"0{(acc_width + 3) // 4}x")
                f.write(f"  preactivation_test_expected[{i}] = {acc_width}'h{hex_val};\n")
            else:
                f.write(f"  preactivation_test_expected[{i}] = {acc_width}'d{val};\n")
        f.write("endfunction\n\n")
        f.write("`endif // PREACTIVATION_TESTCASES_SVH\n")
    print(f"Successfully generated {len(test_cases)} test cases to {output_file}")
    print("Add the following to your testbench to use these test cases:")
    print(f'  `include "{output_file}"')
    print("  // And call init_preactivation_test_cases() in your initial block")


if __name__ == "__main__":
    app()
