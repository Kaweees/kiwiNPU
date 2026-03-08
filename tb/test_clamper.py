"""This module contains the cocotb Python test runner used to test ``Clamper``."""

import math
import os
from pathlib import Path

import cocotb
import torch
from cocotb.triggers import Timer
from cocotb_tools.runner import get_runner
from utils import get_signed_value

# Parameters
NUM_TESTS = 10  # Number of test cases
N = 4  # Vector dimensionality (used to derive ACC_WIDTH)
DATA_WIDTH = 8  # Bit width of output
ACC_WIDTH = DATA_WIDTH * 2 + math.ceil(math.log2(N))
MIN_VAL = -(1 << (DATA_WIDTH - 1))
MAX_VAL = (1 << (DATA_WIDTH - 1)) - 1
ACC_MIN_VAL = -(1 << (ACC_WIDTH - 1))
ACC_MAX_VAL = (1 << (ACC_WIDTH - 1)) - 1


def model_clamper(val: int) -> int:
    """Python model of the Clamper module: saturate val to signed DATA_WIDTH range."""
    return max(MIN_VAL, min(MAX_VAL, val))


@cocotb.test()
async def clamper_test(dut) -> None:
    """Test Clamper module with random values."""

    torch.manual_seed(42)

    dut._log.info(f"Test parameters: {NUM_TESTS=}, {DATA_WIDTH=}, {ACC_WIDTH=}")

    # Initialize input to 0
    dut["in"].value = 0
    await Timer(1, unit="ns")

    # Generate random accumulator-width values
    in_vals = torch.randint(ACC_MIN_VAL, ACC_MAX_VAL + 1, (NUM_TESTS,), dtype=torch.int64)

    for i in range(NUM_TESTS):
        val = int(in_vals[i].item())
        expected = model_clamper(val)

        # Drive as unsigned two's complement
        if val < 0:
            dut["in"].value = val + (1 << ACC_WIDTH)
        else:
            dut["in"].value = val

        await Timer(1, unit="ns")

        got = get_signed_value(dut["out"].value.to_unsigned(), DATA_WIDTH)

        assert got == expected, f"Test Case {i} failed: in={val}, expected={expected}, got={got}"
        dut._log.info(f"Test Case {i} passed: Clamper({val}) = {got}")

    dut._log.info(f"All {NUM_TESTS} tests passed")


def test_clamper() -> None:
    """Test for the Clamper module."""
    proj_path = Path(__file__).resolve().parent.parent

    sources = [f"{proj_path}/rtl/Clamper.sv"]
    includes = [proj_path / "include"]

    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    # Use a unique build directory per test to avoid conflicts
    build_dir = f"{proj_path}/sim_build/Clamper"

    build_kwargs = {
        "sources": sources,
        "hdl_toplevel": "Clamper",
        "build_dir": build_dir,
        "includes": includes,
        "waves": True,
    }

    if sim == "verilator":
        build_kwargs["build_args"] = ["--timescale", "1ns/1ps"]

    runner.build(**build_kwargs)

    runner.test(
        hdl_toplevel="Clamper",
        test_module="test_clamper",
        test_dir=f"{proj_path}/tb",
        build_dir=build_dir,
        waves=True,
    )


if __name__ == "__main__":
    test_clamper()
