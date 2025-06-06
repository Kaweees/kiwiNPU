# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "typer>=0.12.5",
#     "numpy>=1.24.0",
# ]
# ///
import math
import typer
import random
import os
import numpy as np
from pathlib import Path
from typing import Optional, Any, List, Dict

app = typer.Typer()


@app.command()
def generate(
    data_width: int = 8,
    n: int = 4,
    num_tests: int = 10,
    output_file: str = "include/perceptron_testcases.svh",
    seed: Optional[int] = None,
):
    """
    Generate test cases for the perceptron module.

    data_width: Bit width of input vectors and weights
    n: Vector dimensionality
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
        f"Generating {num_tests} perceptron test cases with DATA_WIDTH={data_width}, ACC_WIDTH={acc_width}, N={n}"
    )

    test_cases: List[Dict[str, Any]] = []

    # Generate random test cases
    for i in range(num_tests):
        # Create test case with different strategies
        strategy = i % 5  # Five different strategies

        if strategy == 0:
            # Completely random values
            x = np.random.randint(min_val, max_val + 1, size=n)
            w = np.random.randint(min_val, max_val + 1, size=n)
            b = np.random.randint(min_val, max_val + 1)
        elif strategy == 1:
            # Small random values, less likely to overflow
            small_min = max(min_val // 4, -32)
            small_max = min(max_val // 4, 31)
            x = np.random.randint(small_min, small_max + 1, size=n)
            w = np.random.randint(small_min, small_max + 1, size=n)
            b = np.random.randint(small_min, small_max + 1)
        elif strategy == 2:
            # Positive/negative mix with low probability of overflow
            x = np.random.randint(0, max_val // 2 + 1, size=n)
            w = np.random.randint(min_val // 2, 1, size=n)
            b = np.random.randint(min_val // 2, max_val // 2 + 1)
        elif strategy == 3:
            # Bias-driven tests where bias determines output
            x = np.zeros(n, dtype=int)
            w = np.zeros(n, dtype=int)
            # Random large positive or negative bias
            b = np.random.choice([min_val, max_val])
        else:
            # Some values close to limits to test edge cases
            choices = np.array([min_val, max_val])
            x = np.array([np.random.choice(choices) for _ in range(n)])
            w = np.array([np.random.choice(choices) for _ in range(n)])
            b = np.random.choice(choices)

        # Calculate dot product
        dot_product = int(np.dot(x, w))
        b_acc_width = b | ((-1) << data_width) if b < 0 else b
        acc_with_bias = dot_product + b_acc_width

        # Saturation (quantization)
        max_out_val = (1 << (data_width - 1)) - 1
        min_out_val = -(1 << (data_width - 1))

        pre = max(min(acc_with_bias, max_out_val), min_out_val)
        expected = max(0, pre)

        test_cases.append(
            {
                "x": x.tolist(),
                "w": w.tolist(),
                "b": b,
                "pre": pre,  # Pre-activation value
                "expected": expected,  # Post-activation (ReLU)
                "name": f"random_{i+1}",
            }
        )

    # Write test cases to SystemVerilog file
    output_path = Path(output_file)
    output_path.parent.mkdir(exist_ok=True, parents=True)

    with open(output_path, "w") as f:
        f.write(f"// Auto-generated test cases by {os.path.basename(__file__)}\n")
        f.write(
            f"// DATA_WIDTH={data_width}, ACC_WIDTH={acc_width}, N={n}, NUM_TESTS={num_tests}\n"
        )
        f.write(f"// THIS IS A HEADER FILE - DO NOT ATTEMPT TO COMPILE DIRECTLY\n\n")

        f.write(f"`ifndef PERCEPTRON_TESTCASES_SVH\n")
        f.write(f"`define PERCEPTRON_TESTCASES_SVH\n\n")

        f.write(f"localparam int NUM_PERCEPTRON_TEST = {len(test_cases)};\n\n")

        # Write test case arrays
        f.write(f"// Test vectors\n")
        f.write(
            f"logic signed [{data_width-1}:0] perceptron_test_x[NUM_PERCEPTRON_TEST][{n}];\n"
        )
        f.write(
            f"logic signed [{data_width-1}:0] perceptron_test_w[NUM_PERCEPTRON_TEST][{n}];\n"
        )
        f.write(
            f"logic signed [{data_width-1}:0] perceptron_test_b[NUM_PERCEPTRON_TEST];\n"
        )
        f.write(
            f"logic signed [{data_width-1}:0] perceptron_test_expected[NUM_PERCEPTRON_TEST];\n"
        )

        f.write(f"// Initialize test cases\n")
        f.write(f"function void init_perceptron_test_cases();\n")

        for i, test in enumerate(test_cases):
            f.write(f"  // Test case {i}: {test['name']}\n")

            # Write input vector X
            for j in range(n):
                val = test["x"][j]
                bin_val = format(
                    (1 << data_width) + val if val < 0 else val, f"0{data_width}b"
                )
                f.write(f"  perceptron_test_x[{i}][{j}] = {data_width}'b{bin_val};\n")

            # Write weight vector W
            for j in range(n):
                val = test["w"][j]
                bin_val = format(
                    (1 << data_width) + val if val < 0 else val, f"0{data_width}b"
                )
                f.write(f"  perceptron_test_w[{i}][{j}] = {data_width}'b{bin_val};\n")

            # Write bias B
            val = test["b"]
            bin_val = format(
                (1 << data_width) + val if val < 0 else val, f"0{data_width}b"
            )
            f.write(f"  perceptron_test_b[{i}] = {data_width}'b{bin_val};\n")

            # Write expected output
            val = test["expected"]
            bin_val = format(
                (1 << data_width) + val if val < 0 else val, f"0{data_width}b"
            )
            f.write(f"  perceptron_test_expected[{i}] = {data_width}'b{bin_val};\n")

            # Add a comment showing the computation details
            f.write(
                f"  // dot_product={int(np.dot(test['x'], test['w']))}, pre_activation={test['pre']}, post_activation={test['expected']}\n"
            )

        f.write(f"endfunction\n\n")
        f.write(f"`endif // PERCEPTRON_TESTCASES_SVH\n")

    print(f"Successfully generated {len(test_cases)} test cases to {output_file}")
    print(f"Add the following to your testbench to use these test cases:")
    print(f'  `include "{output_file}"')
    print(f"  // And call init_perceptron_test_cases() in your initial block")


if __name__ == "__main__":
    app()
