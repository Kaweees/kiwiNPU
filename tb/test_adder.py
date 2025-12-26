# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

"""This module contains the cocotb Python test runner used to test ``adder``."""

from __future__ import annotations

import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_tools.runner import get_runner
import torch

@cocotb.test()
async def adder_test(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    torch.manual_seed(0)

    a = torch.randint(0, 256, (10,))
    b = torch.randint(0, 256, (10,))
    y = (a + b) & 0xFF

    for i in range(10):
        dut.a.value = int(a[i])
        dut.b.value = int(b[i])
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        assert dut.y.value == int(y[i])


def test_adder():
    """Test for the adder.

    Creates sources list, gets a cocotb Python Runner,
    builds HDL, runs cocotb testcases.
    """
    proj_path = Path(__file__).resolve().parent.parent

    sources = [proj_path / "rtl" / "adder.sv"]

    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    # Use a unique build directory per test to avoid conflicts
    build_dir = proj_path / "sim_build" / "adder"

    runner.build(
        sources=sources,
        hdl_toplevel="adder",
        build_dir=build_dir,
        waves=True,
    )

    runner.test(
        hdl_toplevel="adder",
        test_module="tb.test_adder",
        build_dir=build_dir,
        waves=True,
    )


if __name__ == "__main__":
    test_adder()
