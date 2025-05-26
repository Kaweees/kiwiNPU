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
    output_file: str = "include/quantizer_testcases.svh",
    seed: Optional[int] = None,
):
    """
    Generate test cases for the quantizer module.

    data_width: Bit width of input vectors
    n: Vector dimensionality
    num_tests: Number of test cases to generate
    output_file: Output file path
    seed: Seed for RNG reproducibility
    """
    acc_width: int = data_width + data_width + math.ceil(math.log2(n))
    acc_min_val: int = -(2 ** (acc_width - 1))
    acc_max_val: int = 2 ** (acc_width - 1) - 1
    quant_min_val: int = -(2 ** (data_width - 1))
    quant_max_val: int = 2 ** (data_width - 1) - 1
    print(f"acc_width: {acc_width}")

    # Initialize random seed if provided
    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)

    print(
        f"Generating {num_tests} quantizer test cases with DATA_WIDTH={data_width}, ACC_WIDTH={acc_width}, N={n}"
    )

    test_cases: List[Dict[str, Any]] = []

    # Generate random test cases
    for i in range(num_tests):
        input = np.random.randint(acc_min_val, acc_max_val + 1)
        if input > quant_max_val:
            output = quant_max_val
        elif input < quant_min_val:
            output = quant_min_val
        else:
            output = input

        test_cases.append(
            {
                "input": input,
                "output": output,
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

        f.write(f"`ifndef QUANTIZER_TESTCASES_SVH\n")
        f.write(f"`define QUANTIZER_TESTCASES_SVH\n\n")

        f.write(f"localparam int NUM_QUANTIZER_TEST = {len(test_cases)};\n\n")

        # Write test case arrays
        f.write(f"// Test vectors\n")
        f.write(
            f"logic signed [{acc_width-1}:0] quantizer_test_input[NUM_QUANTIZER_TEST];\n"
        )
        f.write(
            f"logic signed [{data_width-1}:0] quantizer_test_expected[NUM_QUANTIZER_TEST];\n"
        )

        f.write(f"// Initialize test cases\n")
        f.write(f"function void init_quantizer_test_cases();\n")

        for i, test in enumerate(test_cases):
            input = test["input"]
            output = test["output"]
            f.write(f"  // Test case {i}\n")
            # Mask to correct width and print as unsigned, but use 'signed' in SV
            input_masked = input & ((1 << acc_width) - 1)
            # Sign-extend output to acc_width, then mask to data_width for expected
            if output < 0:
                output_sext = ((1 << data_width) + output) if output < 0 else output
                output_masked = output_sext & ((1 << data_width) - 1)
            else:
                output_masked = output & ((1 << data_width) - 1)
            f.write(
                f"  quantizer_test_input[{i}] = {acc_width}'b{input_masked:0{acc_width}b};\n"
            )
            f.write(
                f"  quantizer_test_expected[{i}] = {data_width}'b{output_masked:0{data_width}b};\n"
            )
            # Add a comment showing the computation details
            f.write(f"  // input={input}, output={output}\n")

        f.write(f"endfunction\n\n")
        f.write(f"`endif // QUANTIZER_TESTCASES_SVH\n")
    print(f"Successfully generated {len(test_cases)} test cases to {output_file}")
    print(f"Add the following to your testbench to use these test cases:")
    print(f'  `include "{output_file}"')
    print(f"  // And call init_quantizer_test_cases() in your initial block")


if __name__ == "__main__":
    app()
