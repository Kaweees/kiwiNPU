"""This module contains the cocotb Python test runner used to test ``Perceptron``."""

import math
import os
from pathlib import Path

import cocotb
import torch
from cocotb.clock import Clock

torch.set_grad_enabled(False)
from cocotb.triggers import RisingEdge
from cocotb_tools.runner import get_runner
from utils import get_signed_value, pack_values

# Parameters
NUM_TESTS = 10  # Number of test cases
N = 4  # Vector dimensionality (number of elements in dot product)
DATA_WIDTH = 8  # Bit width of input and output
ACC_WIDTH = DATA_WIDTH * 2 + math.ceil(math.log2(N))
MIN_VAL = -(1 << (DATA_WIDTH - 1))
MAX_VAL = (1 << (DATA_WIDTH - 1)) - 1


def model_perceptron(x_vec: torch.Tensor, w_vec: torch.Tensor, b: int) -> int:
    """Python model of the Perceptron module: relu(clamp(dot(x, w) + b))."""
    pre = int(torch.dot(x_vec, w_vec).item()) + b
    clamped = max(MIN_VAL, min(MAX_VAL, pre))
    return max(0, clamped)


@cocotb.test()
async def perceptron_test(dut) -> None:
    """Test Perceptron module with random values."""

    # Clock setup
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    torch.manual_seed(42)

    dut._log.info(f"Test parameters: {NUM_TESTS=}, {N=}, {DATA_WIDTH=}, {ACC_WIDTH=}")

    # Reset
    dut.rst_n.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1

    # Generate all test inputs at once
    in_x = torch.randint(MIN_VAL, MAX_VAL + 1, (NUM_TESTS, N), dtype=torch.int32)
    in_w = torch.randint(MIN_VAL, MAX_VAL + 1, (NUM_TESTS, N), dtype=torch.int32)
    in_b = torch.randint(MIN_VAL, MAX_VAL + 1, (NUM_TESTS,), dtype=torch.int32)

    for i in range(NUM_TESTS):
        x_list = in_x[i].tolist()
        w_list = in_w[i].tolist()
        b_val = int(in_b[i].item())
        expected = model_perceptron(in_x[i], in_w[i], b_val)

        dut.x.value = pack_values(x_list, DATA_WIDTH)
        dut.w.value = pack_values(w_list, DATA_WIDTH)
        dut.b.value = b_val

        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)

        got = get_signed_value(dut.y.value.to_unsigned(), DATA_WIDTH)

        assert got == expected, (
            f"Test Case {i} failed: x={x_list}, w={w_list}, b={b_val}, expected={expected}, got={got}"
        )
        dut._log.info(f"Test Case {i} passed: Perceptron({x_list}, {w_list}, {b_val}) = {got}")

    dut._log.info(f"All {NUM_TESTS} tests passed")


def test_perceptron() -> None:
    """Test for the Perceptron module."""
    proj_path = Path(__file__).resolve().parent.parent

    sources = [
        f"{proj_path}/rtl/Perceptron.sv",
        f"{proj_path}/rtl/PreActivation.sv",
        f"{proj_path}/rtl/Clamper.sv",
        f"{proj_path}/rtl/ReLU.sv",
    ]
    includes = [proj_path / "include"]

    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    # Use a unique build directory per test to avoid conflicts
    build_dir = f"{proj_path}/sim_build/Perceptron"

    build_kwargs = {
        "sources": sources,
        "hdl_toplevel": "Perceptron",
        "build_dir": build_dir,
        "includes": includes,
        "waves": True,
    }

    if sim == "verilator":
        build_kwargs["build_args"] = ["--timescale", "1ns/1ps"]

    runner.build(**build_kwargs)

    runner.test(
        hdl_toplevel="Perceptron",
        test_module="test_perceptron",
        test_dir=f"{proj_path}/tb",
        build_dir=build_dir,
        waves=True,
    )


if __name__ == "__main__":
    test_perceptron()
