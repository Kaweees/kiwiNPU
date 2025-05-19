# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "typer>=0.12.5",
# ]
# ///
import typer
import random
import math
from pathlib import Path

app = typer.Typer()


@app.command()
def generate(
    width: int = 8,
    n: int = 4,
    num_tests: int = 10,
    min_val: int = None,
    max_val: int = None,
    output_file: str = "tb/dotproduct_testcases.svh",
    seed: int = None,
):
    """
    Generate test cases for the dot product module.

    width: Bit width of each element
    n: Number of elements in each vector
    num_tests: Number of test cases to generate
    min_val/max_val: Range for random values (defaults to min/max for signed values of width)
    output_file: Where to save the generated test cases
    seed: Random seed for reproducibility
    """
    # Set default min/max values based on width if not provided
    if min_val is None:
        min_val = -(2 ** (width - 1))
    if max_val is None:
        max_val = 2 ** (width - 1) - 1

    # Initialize random seed if provided
    if seed is not None:
        random.seed(seed)

    print(f"Generating {num_tests} dot product test cases with WIDTH={width}, N={n}")
    print(f"Value range: [{min_val}, {max_val}]")

    test_cases = []

    # Add standard test cases (at least 5 fixed tests)
    test_cases.append({"a": [0] * n, "b": [0] * n, "expected": 0, "name": "zeros"})

    test_cases.append({"a": [1] * n, "b": [1] * n, "expected": n, "name": "ones"})

    # Max positive values
    test_cases.append(
        {
            "a": [max_val] * n,
            "b": [1] * n,
            "expected": saturate(max_val * n, width),
            "name": "max_positive",
        }
    )

    # Min negative values
    test_cases.append(
        {
            "a": [min_val] * n,
            "b": [1] * n,
            "expected": saturate(min_val * n, width),
            "name": "min_negative",
        }
    )

    # Alternating positive and negative
    a_alt = [max_val if i % 2 == 0 else min_val for i in range(n)]
    b_alt = [1] * n
    test_cases.append(
        {
            "a": a_alt.copy(),
            "b": b_alt,
            "expected": saturate(sum(a_alt[i] * b_alt[i] for i in range(n)), width),
            "name": "alternating",
        }
    )

    # Generate diverse random test cases for the remaining slots
    for i in range(num_tests - len(test_cases)):
        # Create test case with different strategies
        strategy = i % 4  # Four different strategies

        if strategy == 0:
            # Completely random values
            a = [random.randint(min_val, max_val) for _ in range(n)]
            b = [random.randint(min_val, max_val) for _ in range(n)]
        elif strategy == 1:
            # Small random values, less likely to overflow
            small_min = max(min_val // 4, -128)
            small_max = min(max_val // 4, 127)
            a = [random.randint(small_min, small_max) for _ in range(n)]
            b = [random.randint(small_min, small_max) for _ in range(n)]
        elif strategy == 2:
            # Positive/negative mix with low probability of overflow
            a = [random.randint(0, max_val // 2) for _ in range(n)]
            b = [random.randint(min_val // 2, 0) for _ in range(n)]
        else:
            # Some values close to limits to test edge cases
            a = [
                random.choice([min_val, max_val, random.randint(min_val, max_val)])
                for _ in range(n)
            ]
            b = [
                random.choice([min_val, max_val, random.randint(min_val, max_val)])
                for _ in range(n)
            ]

        # Calculate expected dot product with saturation
        expected = sum(a[j] * b[j] for j in range(n))
        expected = saturate(expected, width)

        test_cases.append(
            {"a": a, "b": b, "expected": expected, "name": f"random_{i+1}"}
        )

    # Write test cases to SystemVerilog file
    output_path = Path(output_file)
    output_path.parent.mkdir(exist_ok=True, parents=True)

    with open(output_path, "w") as f:
        f.write(f"// Auto-generated dot product test cases\n")
        f.write(f"// WIDTH={width}, N={n}, NUM_TESTS={num_tests}\n")
        f.write(f"// THIS IS A HEADER FILE - DO NOT ATTEMPT TO COMPILE DIRECTLY\n\n")

        f.write(f"localparam int NUM_TESTS = {len(test_cases)};\n\n")

        # Write test case arrays
        f.write(f"// Test vectors\n")
        f.write(f"logic signed [{width-1}:0] test_a[NUM_TESTS][{n}];\n")
        f.write(f"logic signed [{width-1}:0] test_b[NUM_TESTS][{n}];\n")
        f.write(f"logic signed [{width-1}:0] test_expected[NUM_TESTS];\n")
        f.write(f"string test_names[NUM_TESTS];\n\n")

        f.write(f"// Initialize test cases\n")
        f.write(f"function void init_test_cases();\n")

        for i, test in enumerate(test_cases):
            # Write vector A
            f.write(f"  // Test case {i}: {test['name']}\n")
            for j in range(n):
                # Fix for negative numbers in SystemVerilog
                val = test["a"][j]
                if val < 0:
                    # For negative numbers, use hex format with full bit pattern
                    # Calculate 2's complement representation
                    hex_val = format((1 << width) + val, f"0{(width+3)//4}x")
                    f.write(f"  test_a[{i}][{j}] = {width}'h{hex_val};\n")
                else:
                    f.write(f"  test_a[{i}][{j}] = {width}'d{val};\n")

            # Write vector B
            for j in range(n):
                # Fix for negative numbers in SystemVerilog
                val = test["b"][j]
                if val < 0:
                    # For negative numbers, use hex format with full bit pattern
                    hex_val = format((1 << width) + val, f"0{(width+3)//4}x")
                    f.write(f"  test_b[{i}][{j}] = {width}'h{hex_val};\n")
                else:
                    f.write(f"  test_b[{i}][{j}] = {width}'d{val};\n")

            # Write expected output
            val = test["expected"]
            if val < 0:
                # For negative numbers, use hex format with full bit pattern
                hex_val = format((1 << width) + val, f"0{(width+3)//4}x")
                f.write(f"  test_expected[{i}] = {width}'h{hex_val};\n")
            else:
                f.write(f"  test_expected[{i}] = {width}'d{val};\n")

            f.write(f"  test_names[{i}] = \"{test['name']}\";\n\n")

        f.write(f"endfunction\n")

    print(f"Successfully generated {len(test_cases)} test cases to {output_file}")
    print(f"Add the following to your testbench to use these test cases:")
    print(f'  `include "{output_file}"')
    print(f"  // And call init_test_cases() in your initial block")


def saturate(value, width):
    """Saturate a value to the given bit width for signed integers"""
    max_pos = 2 ** (width - 1) - 1
    min_neg = -(2 ** (width - 1))

    if value > max_pos:
        return max_pos
    elif value < min_neg:
        return min_neg
    else:
        return value


if __name__ == "__main__":
    app()
