#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "typer>=0.12.5",
#     "numpy>=1.24.0",
#     "jinja2>=3.1.2",
# ]
# ///
import math
import typer
import random
import os
import numpy as np
from pathlib import Path
from typing import Optional, Any, List, Dict
from jinja2 import Template

app = typer.Typer()


def generate_test_cases(
    module_name: str,
    data_width: int,
    n: int,
    out_n: int,
    num_tests: int,
    seed: Optional[int] = None,
) -> List[Dict[str, Any]]:
    """Generate test cases for a module."""
    min_val: int = -(2 ** (data_width - 1))
    max_val: int = 2 ** (data_width - 1) - 1
    acc_width: int = data_width + data_width + math.ceil(math.log2(n))

    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)

    test_cases: List[Dict[str, Any]] = []

    for i in range(num_tests):
        strategy = i % 5

        if strategy == 0:
            # Random values
            x = np.random.randint(min_val, max_val + 1, size=n)
            w = np.random.randint(min_val, max_val + 1, size=(n, out_n))
            b = np.random.randint(min_val, max_val + 1, size=out_n)
        elif strategy == 1:
            # Small values
            small_min = max(min_val // 4, -32)
            small_max = min(max_val // 4, 31)
            x = np.random.randint(small_min, small_max + 1, size=n)
            w = np.random.randint(small_min, small_max + 1, size=(n, out_n))
            b = np.random.randint(small_min, small_max + 1, size=out_n)
        elif strategy == 2:
            # Positive/negative mix
            x = np.random.randint(0, max_val // 2 + 1, size=n)
            w = np.random.randint(min_val // 2, 1, size=(n, out_n))
            b = np.random.randint(min_val // 2, max_val // 2 + 1, size=out_n)
        elif strategy == 3:
            # Bias-driven tests
            x = np.zeros(n, dtype=int)
            w = np.zeros((n, out_n), dtype=int)
            b = np.array([np.random.choice([min_val, max_val]) for _ in range(out_n)])
        else:
            # Edge cases
            choices = np.array([min_val, max_val])
            x = np.array([np.random.choice(choices) for _ in range(n)])
            w = np.array(
                [[np.random.choice(choices) for _ in range(out_n)] for _ in range(n)]
            )
            b = np.array([np.random.choice(choices) for _ in range(out_n)])

        # Calculate expected outputs
        expected_outputs = []
        for k in range(out_n):
            dot_product = int(np.dot(x, w[:, k]))
            b_acc_width = b[k] | ((-1) << data_width) if b[k] < 0 else b[k]
            acc_with_bias = dot_product + b_acc_width

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
                "name": f"random_{i+1}",
            }
        )

    return test_cases


def write_test_cases_svh(
    test_cases: List[Dict[str, Any]],
    module_name: str,
    data_width: int,
    n: int,
    out_n: int,
    output_file: str,
):
    """Write test cases to SystemVerilog header file."""

    # Add custom filter for binary formatting
    def format_binary(value, width):
        return format((1 << width) + value if value < 0 else value, f"0{width}b")

    # Create template with the filter
    template = Template(
        """// Auto-generated test cases for {{ module_name }}
// DATA_WIDTH={{ data_width }}, ACC_WIDTH={{ acc_width }}, N={{ n }}, OUT_N={{ out_n }}, NUM_TESTS={{ num_tests }}
// THIS IS A HEADER FILE - DO NOT ATTEMPT TO COMPILE DIRECTLY

`ifndef {{ module_name.upper() }}_TESTCASES_SVH
`define {{ module_name.upper() }}_TESTCASES_SVH

localparam int NUM_{{ module_name.upper() }}_TEST = {{ num_tests }};

// Test vectors
logic signed [{{ data_width-1 }}:0] {{ module_name }}_test_x[NUM_{{ module_name.upper() }}_TEST][{{ n }}];
logic signed [{{ data_width-1 }}:0] {{ module_name }}_test_w[NUM_{{ module_name.upper() }}_TEST][{{ n }}][{{ out_n }}];
logic signed [{{ data_width-1 }}:0] {{ module_name }}_test_b[NUM_{{ module_name.upper() }}_TEST][{{ out_n }}];
logic signed [{{ data_width-1 }}:0] {{ module_name }}_test_expected[NUM_{{ module_name.upper() }}_TEST][{{ out_n }}];

// Initialize test cases
function void init_{{ module_name }}_test_cases();
{% for i, test in enumerate(test_cases) %}
  // Test case {{ i }}: {{ test.name }}
  {% for j in range(n) %}
  {{ module_name }}_test_x[{{ i }}][{{ j }}] = {{ data_width }}'b{{ test.x[j]|format_binary(data_width) }};
  {% endfor %}
  {% for j in range(n) %}
    {% for k in range(out_n) %}
  {{ module_name }}_test_w[{{ i }}][{{ j }}][{{ k }}] = {{ data_width }}'b{{ test.w[j][k]|format_binary(data_width) }};
    {% endfor %}
  {% endfor %}
  {% for k in range(out_n) %}
  {{ module_name }}_test_b[{{ i }}][{{ k }}] = {{ data_width }}'b{{ test.b[k]|format_binary(data_width) }};
  {% endfor %}
  {% for k in range(out_n) %}
  {{ module_name }}_test_expected[{{ i }}][{{ k }}] = {{ data_width }}'b{{ test.expected[k]|format_binary(data_width) }};
  {% endfor %}
  // Test case {{ i }} computation details:
  {% for k in range(out_n) %}
  // Output {{ k }}: dot_product={{ test.dot_products[k] }}, pre_activation={{ test.pre }}, post_activation={{ test.expected[k] }}
  {% endfor %}
{% endfor %}
endfunction

`endif // {{ module_name.upper() }}_TESTCASES_SVH
"""
    )

    # Register the filter with the template
    template.globals["format_binary"] = format_binary

    output_path = Path(output_file)
    output_path.parent.mkdir(exist_ok=True, parents=True)

    with open(output_path, "w") as f:
        f.write(
            template.render(
                module_name=module_name,
                data_width=data_width,
                acc_width=data_width * 2 + math.ceil(math.log2(n)),
                n=n,
                out_n=out_n,
                num_tests=len(test_cases),
                test_cases=test_cases,
            )
        )


def write_testbench_sv(
    module_name: str, data_width: int, n: int, out_n: int, output_file: str
):
    """Write testbench SystemVerilog file."""
    template = Template(
        """`timescale 1ns / 1ps
`include "../include/width.svh"
`include "../include/{{ module_name }}_testcases.svh"

// Function to get layer size must be defined before the module
function automatic int get_layer_size(int idx);
  // Convert 8-bit values to 32-bit integers
  int sizes[`NUM_LAYERS];
  sizes[0] = 32'd{{ n }};  // First layer size
  sizes[1] = 32'd{{ out_n }};  // Second layer size
  sizes[2] = 32'd{{ n }};  // Third layer size
  return sizes[idx];
endfunction

module tb_{{ module_name }} ();
  // Declare test bench parameters
  localparam CLK_PERIOD = 10;  // Clock period in ns (100MHz clock)
  localparam PIPELINE_STAGES = 2;  // Number of pipeline stages in the Perceptron
  localparam OUT_N = get_layer_size(1);  // Get LAYER_SIZES[1]

  // Declare test bench input/output signals
  logic sCLK, sRST_N;
  logic signed [             `DATA_WIDTH - 1 : 0] sX_arr                [   `N];
  logic signed [             `DATA_WIDTH - 1 : 0] sW_arr                [   `N] [OUT_N];
  logic signed [             `DATA_WIDTH - 1 : 0] sB_arr                [OUT_N];
  logic signed [             `DATA_WIDTH - 1 : 0] sY_arr                [OUT_N];
  logic signed [        `N * `DATA_WIDTH - 1 : 0] sX;  // Packed vectors
  logic signed [OUT_N * `N * `DATA_WIDTH - 1 : 0] sW;  // Packed vectors
  logic signed [OUT_N * `DATA_WIDTH - 1 : 0] sB, sY;  // Packed vectors
  logic signed [OUT_N * `DATA_WIDTH - 1 : 0] sY_expected;  // Packed vectors

  // Pack the input vectors into bit vectors
  always_comb begin
    for (int i = 0; i < `N; i++) begin
      sX[i*`DATA_WIDTH+:`DATA_WIDTH] = sX_arr[i];
    end
  end

  // Pack the weights into bit vector
  always_comb begin
    for (int i = 0; i < OUT_N; i++) begin
      for (int j = 0; j < `N; j++) begin
        sW[(i*`N+j)*`DATA_WIDTH+:`DATA_WIDTH] = sW_arr[j][i];
      end
    end
  end

  // Pack the biases into bit vector
  always_comb begin
    for (int i = 0; i < OUT_N; i++) begin
      sB[i*`DATA_WIDTH+:`DATA_WIDTH] = sB_arr[i];
    end
  end

  // Instantiate the module
  {{ module_name }} #(
    .IN_N      (`N),
    .OUT_N     (OUT_N),
    .DATA_WIDTH(`DATA_WIDTH),
    .ACC_WIDTH (`ACC_WIDTH)
  ) DUT (
    .clk    (sCLK),
    .rst_n  (sRST_N),
    .in_vec (sX),
    .weights(sW),
    .biases (sB),
    .out_vec(sY)
  );

  // Clock generation
  initial begin
    sCLK = 1'b1;  // Start simulation with positive edge
    // Toggle the clock every 5 ns
    forever #(CLK_PERIOD / 2) sCLK = ~sCLK;
  end

  initial begin
    // Initialize signals
    sCLK   = 1'b0;
    sRST_N = 1'b0;
    init_{{ module_name }}_test_cases();

    // Reset for a few clock cycles
    @(posedge sCLK);
    sRST_N = 1'b1;  // Release reset

    // Run through all test cases
    for (int i = 0; i < NUM_{{ module_name.upper() }}_TEST; i++) begin
      // Load test vectors
      for (int j = 0; j < `N; j++) begin
        sX_arr[j] = {{ module_name }}_test_x[i][j];
        for (int k = 0; k < OUT_N; k++) begin
          sW_arr[j][k] = {{ module_name }}_test_w[i][j][k];
        end
      end
      for (int j = 0; j < OUT_N; j++) begin
        sB_arr[j]                               = {{ module_name }}_test_b[i][j];
        sY_expected[j*`DATA_WIDTH+:`DATA_WIDTH] = {{ module_name }}_test_expected[i][j];
      end

      // Wait for clock edge and check results
      for (int stage = 0; stage < PIPELINE_STAGES; stage++) begin
        @(posedge sCLK);
      end

      // Check each output separately
      for (int j = 0; j < OUT_N; j++) begin
        if (sY[j*`DATA_WIDTH+:`DATA_WIDTH] !== sY_expected[j*`DATA_WIDTH+:`DATA_WIDTH]) begin
          $error("Test case %03d output %d failed: Expected %0d'b%b (%03d), Got %0d'b%b (%03d)", i,
                 j, `DATA_WIDTH, sY_expected[j*`DATA_WIDTH+:`DATA_WIDTH],
                 sY_expected[j*`DATA_WIDTH+:`DATA_WIDTH], `DATA_WIDTH,
                 sY[j*`DATA_WIDTH+:`DATA_WIDTH], sY[j*`DATA_WIDTH+:`DATA_WIDTH]);
        end else begin
          $display("Test case %03d output %d passed: Got %0d'b%b", i, j, `DATA_WIDTH,
                   sY[j*`DATA_WIDTH+:`DATA_WIDTH]);
        end
      end
    end

    $display("All tests completed!");
    $finish();  // Terminate simulation
  end

  // Waveform dump
  initial begin
    $dumpfile("tb_{{ module_name }}.vcd");
    $dumpvars(0, tb_{{ module_name }});
  end
endmodule
"""
    )

    output_path = Path(output_file)
    output_path.parent.mkdir(exist_ok=True, parents=True)

    with open(output_path, "w") as f:
        f.write(
            template.render(
                module_name=module_name, data_width=data_width, n=n, out_n=out_n
            )
        )


@app.command()
def generate(
    data_width: int = typer.Option(8, help="Bit width of input vectors and weights"),
    n: int = typer.Option(4, help="Input vector dimensionality"),
    out_n: int = typer.Option(4, help="Output vector dimensionality"),
    num_tests: int = typer.Option(10, help="Number of test cases to generate"),
    output_dir: str = typer.Option("include", help="Output directory for test cases"),
    tb_dir: str = typer.Option("tb", help="Output directory for testbench"),
    seed: Optional[int] = typer.Option(None, help="Seed for RNG reproducibility"),
):
    """
    Generate testbench and test cases for the KiwiNPU module.
    """
    module_name = "kiwinpu"  # Set default module name

    # Generate test cases
    test_cases = generate_test_cases(
        module_name=module_name,
        data_width=data_width,
        n=n,
        out_n=out_n,
        num_tests=num_tests,
        seed=seed,
    )

    # Write test cases to SVH file
    test_cases_file = os.path.join(output_dir, f"{module_name}_testcases.svh")
    write_test_cases_svh(
        test_cases=test_cases,
        module_name=module_name,
        data_width=data_width,
        n=n,
        out_n=out_n,
        output_file=test_cases_file,
    )

    # Write testbench to SV file
    testbench_file = os.path.join(tb_dir, f"tb_{module_name}.sv")
    write_testbench_sv(
        module_name=module_name,
        data_width=data_width,
        n=n,
        out_n=out_n,
        output_file=testbench_file,
    )

    print(f"Successfully generated testbench and test cases for {module_name}")
    print(f"Test cases file: {test_cases_file}")
    print(f"Testbench file: {testbench_file}")
    print("\nAdd the following to your testbench to use these test cases:")
    print(f'  `include "{test_cases_file}"')
    print(f"  // And call init_{module_name}_test_cases() in your initial block")


if __name__ == "__main__":
    app()
