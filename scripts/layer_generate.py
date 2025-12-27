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
    out_n: int = 4,
    num_tests: int = 10,
    output_file: str = "include/layer_testcases.svh",
    seed: int | None = None,
):
    """
    Generate test cases for the layer module.

    data_width: Bit width of input vectors and weights
    n: Input vector dimensionality
    out_n: Output vector dimensionality
    num_tests: Number of test cases to generate
    output_file: Output file path
    seed: Seed for RNG reproducibility
    """
    min_val: int = -(2 ** (data_width - 1))
    max_val: int = 2 ** (data_width - 1) - 1
    acc_width: int = data_width + data_width + math.ceil(math.log2(n))

    # Initialize random seed if provided
    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)

    print(
        f"Generating {num_tests} layer test cases with DATA_WIDTH={data_width}, ACC_WIDTH={acc_width}, N={n}, OUT_N={out_n}"
    )

    test_cases: list[dict[str, Any]] = []

    # Generate random test cases
    for i in range(num_tests):
        # Create test case with different strategies
        strategy = i % 5  # Five different strategies

        if strategy == 0:
            # Completely random values
            x = np.random.randint(min_val, max_val + 1, size=n)
            w = np.random.randint(min_val, max_val + 1, size=(n, out_n))  # Now a 2D array
            b = np.random.randint(min_val, max_val + 1, size=out_n)  # Now an array
        elif strategy == 1:
            # Small random values, less likely to overflow
            small_min = max(min_val // 4, -32)
            small_max = min(max_val // 4, 31)
            x = np.random.randint(small_min, small_max + 1, size=n)
            w = np.random.randint(small_min, small_max + 1, size=(n, out_n))
            b = np.random.randint(small_min, small_max + 1, size=out_n)
        elif strategy == 2:
            # Positive/negative mix with low probability of overflow
            x = np.random.randint(0, max_val // 2 + 1, size=n)
            w = np.random.randint(min_val // 2, 1, size=(n, out_n))
            b = np.random.randint(min_val // 2, max_val // 2 + 1, size=out_n)
        elif strategy == 3:
            # Bias-driven tests where bias determines output
            x = np.zeros(n, dtype=int)
            w = np.zeros((n, out_n), dtype=int)
            # Random large positive or negative bias for each output
            b = np.array([np.random.choice([min_val, max_val]) for _ in range(out_n)])
        else:
            # Some values close to limits to test edge cases
            choices = np.array([min_val, max_val])
            x = np.array([np.random.choice(choices) for _ in range(n)])
            w = np.array([[np.random.choice(choices) for _ in range(out_n)] for _ in range(n)])
            b = np.array([np.random.choice(choices) for _ in range(out_n)])

        # Calculate outputs for each perceptron
        expected_outputs = []
        for k in range(out_n):
            # Calculate dot product for this output
            dot_product = int(np.dot(x, w[:, k]))
            b_acc_width = b[k] | ((-1) << data_width) if b[k] < 0 else b[k]
            acc_with_bias = dot_product + b_acc_width

            # Saturation (quantization)
            max_out_val = (1 << (data_width - 1)) - 1
            min_out_val = -(1 << (data_width - 1))

            pre = max(min(acc_with_bias, max_out_val), min_out_val)
            expected = max(0, pre)
            expected_outputs.append(expected)

        test_cases.append(
            {
                "x": x.tolist(),
                "w": w.tolist(),
                "b": b.tolist(),
                "pre": pre,
                "expected": expected_outputs,
                "name": f"random_{i + 1}",
            }
        )

    # Write test cases to SystemVerilog file
    output_path = Path(output_file)
    output_path.parent.mkdir(exist_ok=True, parents=True)

    with open(output_path, "w") as f:
        f.write(f"// Auto-generated test cases by {os.path.basename(__file__)}\n")
        f.write(f"// DATA_WIDTH={data_width}, ACC_WIDTH={acc_width}, N={n}, OUT_N={out_n}, NUM_TESTS={num_tests}\n")
        f.write("// THIS IS A HEADER FILE - DO NOT ATTEMPT TO COMPILE DIRECTLY\n\n")

        f.write("`ifndef LAYER_TESTCASES_SVH\n")
        f.write("`define LAYER_TESTCASES_SVH\n\n")

        f.write(f"localparam int NUM_LAYER_TEST = {len(test_cases)};\n\n")

        # Write test case arrays
        f.write("// Test vectors\n")
        f.write(f"logic signed [{data_width - 1}:0] layer_test_x[NUM_LAYER_TEST][{n}];\n")
        f.write(f"logic signed [{data_width - 1}:0] layer_test_w[NUM_LAYER_TEST][{n}][{out_n}];\n")
        f.write(f"logic signed [{data_width - 1}:0] layer_test_b[NUM_LAYER_TEST][{out_n}];\n")
        f.write(f"logic signed [{data_width - 1}:0] layer_test_expected[NUM_LAYER_TEST][{out_n}];\n")

        f.write("// Initialize test cases\n")
        f.write("function void init_layer_test_cases();\n")

        for i, test in enumerate(test_cases):
            f.write(f"  // Test case {i}: {test['name']}\n")

            # Write input vector X
            for j in range(n):
                val = test["x"][j]
                bin_val = format((1 << data_width) + val if val < 0 else val, f"0{data_width}b")
                f.write(f"  layer_test_x[{i}][{j}] = {data_width}'b{bin_val};\n")

            # Write weight matrix W
            for j in range(n):
                for k in range(out_n):
                    val = test["w"][j][k]
                    bin_val = format((1 << data_width) + val if val < 0 else val, f"0{data_width}b")
                    f.write(f"  layer_test_w[{i}][{j}][{k}] = {data_width}'b{bin_val};\n")

            # Write bias vector B
            for k in range(out_n):
                val = test["b"][k]
                bin_val = format((1 << data_width) + val if val < 0 else val, f"0{data_width}b")
                f.write(f"  layer_test_b[{i}][{k}] = {data_width}'b{bin_val};\n")

            # Write expected outputs
            for k in range(out_n):
                val = test["expected"][k]
                bin_val = format((1 << data_width) + val if val < 0 else val, f"0{data_width}b")
                f.write(f"  layer_test_expected[{i}][{k}] = {data_width}'b{bin_val};\n")

            # Add a comment showing the computation details
            f.write(f"  // Test case {i} computation details:\n")
            for k in range(out_n):
                dot_product = int(np.dot(test["x"], [w[k] for w in test["w"]]))
                f.write(
                    f"  // Output {k}: dot_product={dot_product}, pre_activation={test['pre']}, post_activation={test['expected'][k]}\n"
                )

        f.write("endfunction\n\n")
        f.write("`endif // LAYER_TESTCASES_SVH\n")

    print(f"Successfully generated {len(test_cases)} test cases to {output_file}")
    print("Add the following to your testbench to use these test cases:")
    print(f'  `include "{output_file}"')
    print("  // And call init_layer_test_cases() in your initial block")


if __name__ == "__main__":
    app()
