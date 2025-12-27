from __future__ import annotations

import os
from pathlib import Path

import cocotb
import torch
from cocotb.triggers import Timer
from cocotb_tools.runner import get_runner

N = 10  # Number of test cases
DATA_WIDTH = 8  # Bit width of input and output
MIN_VAL = -(1 << (DATA_WIDTH - 1))
MAX_VAL = (1 << (DATA_WIDTH - 1)) - 1


@cocotb.test()
async def relu_test(dut) -> None:
    """Test ReLU module with random values."""

    torch.manual_seed(0)

    dut._log.info(f"Test parameters: N={N}, DATA_WIDTH={DATA_WIDTH}")

    # Generate random signed values in the valid range
    in_vals = torch.randint(MIN_VAL, MAX_VAL + 1, (N,), dtype=torch.int32)
    out_vals = torch.relu(in_vals)

    # Initialize input to 0 first
    dut["in"].value = 0
    await Timer(1, unit="ns")  # Wait for initial value to propagate

    for i in range(N):
        dut["in"].value = int(in_vals[i].item())
        # Wait for combinational logic to settle
        await Timer(1, unit="ns")
        assert dut["out"].value == int(out_vals[i].item()), (
            f"Test Case {i} failed: expected={out_vals[i]}, got={dut['out'].value}"
        )
    dut._log.info(f"All {N} tests passed")


def test_relu() -> None:
    """Test for the ReLU module."""
    proj_path = Path(__file__).resolve().parent.parent

    sources = [f"{proj_path}/rtl/ReLU.sv"]
    includes = [f"{proj_path}/include"]

    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    # Use a unique build directory per test to avoid conflicts
    build_dir = f"{proj_path}/sim_build/ReLU"

    runner.build(
        sources=sources,
        hdl_toplevel="ReLU",
        build_dir=build_dir,
        includes=includes,
        waves=True,
    )

    runner.test(
        hdl_toplevel="ReLU",
        test_module="tb.test_relu",
        build_dir=build_dir,
        waves=True,
    )


if __name__ == "__main__":
    test_relu()
