import os
import random
from pathlib import Path

import cocotb
import torch
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray, Range
from cocotb_tools.runner import get_runner

NUM_TESTS = 50  # Number of test cases
IN_N = 4  # Number of inputs
OUT_N = 4  # Number of outputs
DATA_WIDTH = 8  # Bit width of input
MIN_VAL = -(1 << (DATA_WIDTH - 1))
MAX_VAL = (1 << (DATA_WIDTH - 1)) - 1


def pack_values(values, width):
    """Pack a list of integers into a single LogicArray."""
    total_bits = len(values) * width

    # Construct the packed integer
    # values[0] is at LSB, values[-1] is at MSB
    result = 0
    for val in reversed(values):
        # Mask to width to ensure we pack correctly
        val = val & ((1 << width) - 1)
        result = (result << width) | val

    return LogicArray(result, Range(total_bits - 1, "downto", 0))


def get_signed_value(val, width):
    """Convert unsigned bit representation to signed integer."""
    if val >= (1 << (width - 1)):
        return val - (1 << width)
    return val


def model_layer(x_vec, w_mat, b_vec):
    """
    PyTorch model of the Layer.
    x_vec: list of N integers
    w_mat: list of OUT_N lists of N integers (w[output_idx][input_idx])
    b_vec: list of OUT_N integers
    """

    # Convert to PyTorch tensors
    x = torch.tensor(x_vec, dtype=torch.int32)
    # w_mat[i][j] is weight from input j to output i
    # Shape: (OUT_N, IN_N)
    w = torch.tensor(w_mat, dtype=torch.int32)
    b = torch.tensor(b_vec, dtype=torch.int32)

    # Linear transformation: output = x @ w.T + b
    # x: (IN_N,), w: (OUT_N, IN_N), so x @ w.T gives (OUT_N,)
    output = torch.matmul(x, w.T) + b

    # Quantizer: clamp to signed data_width-bit range
    quant = torch.clamp(output, MIN_VAL, MAX_VAL)

    # ReLU
    relu = torch.relu(quant)

    # Convert back to Python list
    return relu.tolist()


@cocotb.test()
async def test_layer_random(dut):
    """Test Layer with random values."""

    torch.manual_seed(0)

    # Clock setup
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    # Parameters for generation

    for t in range(NUM_TESTS):
        strategy = t % 5

        # Generate inputs based on strategy
        if strategy == 0:
            # Completely random values
            x_data = [random.randint(MIN_VAL, MAX_VAL) for _ in range(IN_N)]
            w_data = [[random.randint(MIN_VAL, MAX_VAL) for _ in range(IN_N)] for _ in range(OUT_N)]
            b_data = [random.randint(MIN_VAL, MAX_VAL) for _ in range(OUT_N)]

        elif strategy == 1:
            # Small random values, less likely to overflow
            small_min = max(MIN_VAL // 4, -32)
            small_max = min(MAX_VAL // 4, 31)
            x_data = [random.randint(small_min, small_max) for _ in range(IN_N)]
            w_data = [[random.randint(small_min, small_max) for _ in range(IN_N)] for _ in range(OUT_N)]
            b_data = [random.randint(small_min, small_max) for _ in range(OUT_N)]

        elif strategy == 2:
            # Positive/negative mix with low probability of overflow
            x_data = [random.randint(0, MAX_VAL // 2) for _ in range(IN_N)]
            w_data = [[random.randint(MIN_VAL // 2, 1) for _ in range(IN_N)] for _ in range(OUT_N)]
            b_data = [random.randint(MIN_VAL // 2, MAX_VAL // 2) for _ in range(OUT_N)]

        elif strategy == 3:
            # Bias-driven tests where bias determines output
            x_data = [0] * IN_N
            w_data = [[0] * IN_N for _ in range(OUT_N)]
            # Random large positive or negative bias
            b_data = [random.choice([MIN_VAL, MAX_VAL]) for _ in range(OUT_N)]

        else:
            # Edge cases
            choices = [MIN_VAL, MAX_VAL]
            x_data = [random.choice(choices) for _ in range(IN_N)]
            w_data = [[random.choice(choices) for _ in range(IN_N)] for _ in range(OUT_N)]
            b_data = [random.choice(choices) for _ in range(OUT_N)]

        # Calculate expected output
        expected_y = model_layer(x_data, w_data, b_data)

        # Drive inputs
        # Pack x
        dut.in_vec.value = pack_values(x_data, DATA_WIDTH)

        # Pack w
        # SV expects flattened array where loop i (output) is outer, j (input) is inner.
        # So sequence is w[0][0], w[0][1], ... (Wait, let's re-verify SV packing)
        # SV: sW[(i*N+j)*DW +: DW] = sW_arr[j][i]
        # sW_arr[j][i] is weight for input j to output i.
        # In my python w_data[i][j], this is weight for output i from input j.
        # So w_data[i][j] matches sW_arr[j][i].
        # The SV packing loop:
        # for i in OUT_N:
        #   for j in IN_N:
        #     index = i*N + j
        #     val = sW_arr[j][i] (which is w_data[i][j])
        # So the sequence in packed integer (LSB to MSB) is:
        # w_data[0][0], w_data[0][1], ..., w_data[0][N-1], w_data[1][0], ...
        # My pack_values takes a list and puts 1st element at LSB.
        # So I need to flatten w_data as:
        flat_w = []
        for i in range(OUT_N):
            for j in range(IN_N):
                flat_w.append(w_data[i][j])

        dut.weights.value = pack_values(flat_w, DATA_WIDTH)

        # Pack b
        dut.biases.value = pack_values(b_data, DATA_WIDTH)

        # Wait for result (need 2 cycles due to registered output)
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)

        # Read output after the clock edge
        got_vec = dut.out_vec.value.to_unsigned()
        # Unpack output
        got_y = []
        for i in range(OUT_N):
            # Extract DATA_WIDTH bits
            val_bits = (got_vec >> (i * DATA_WIDTH)) & ((1 << DATA_WIDTH) - 1)
            val = get_signed_value(val_bits, DATA_WIDTH)
            got_y.append(val)

        # Check
        if got_y != expected_y:
            dut._log.error(f"Test {t} failed!")
            dut._log.error(f"X: {x_data}")
            dut._log.error(f"W: {w_data}")
            dut._log.error(f"B: {b_data}")
            dut._log.error(f"Expected: {expected_y}")
            dut._log.error(f"Got:      {got_y}")
            assert False, f"Mismatch in test {t}"
        else:
            dut._log.info(f"Test {t} passed")


def test_layer():
    """Test for the Layer module.

    Creates sources list, gets a cocotb Python Runner,
    builds HDL, runs cocotb testcases.
    """
    proj_path = Path(__file__).resolve().parent.parent

    sources = [
        proj_path / "rtl" / "Layer.sv",
        proj_path / "rtl" / "Perceptron.sv",
        proj_path / "rtl" / "PreActivation.sv",
        proj_path / "rtl" / "Quantizer.sv",
        proj_path / "rtl" / "ReLU.sv",
    ]
    includes = [proj_path / "include"]

    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    # Use a unique build directory per test to avoid conflicts
    build_dir = proj_path / "sim_build" / "Layer"

    runner.build(
        sources=sources,
        hdl_toplevel="Layer",
        build_dir=build_dir,
        includes=includes,
        waves=True,
    )

    runner.test(
        hdl_toplevel="Layer",
        test_module="tb.test_layer",
        build_dir=build_dir,
        waves=True,
    )


if __name__ == "__main__":
    test_layer()
