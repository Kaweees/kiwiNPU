from __future__ import annotations

import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_tools.runner import get_runner
import torch

@cocotb.test()
async def relu_test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    torch.manual_seed(0)

    N = 10
    in_vals = torch.randint(0, 256, (N,), dtype=torch.int64)
    out_vals = torch.relu(in_vals)

    for i in range(N):
        dut["in"].value = int(in_vals[i])
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        assert dut["out"].value == int(out_vals[i])


def test_relu():
    """Test for the ReLU module.

    Creates sources list, gets a cocotb Python Runner,
    builds HDL, runs cocotb testcases.
    """
    proj_path = Path(__file__).resolve().parent.parent

    sources = [proj_path / "rtl" / "ReLU.sv"]
    includes = [proj_path / "include"]

    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    # Use a unique build directory per test to avoid conflicts
    build_dir = proj_path / "sim_build" / "ReLU"

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
