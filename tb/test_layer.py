"""This module contains the cocotb Python test runner used to test ``Layer``."""

import math
import os
from pathlib import Path

import cocotb
import torch
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_tools.runner import get_runner
from utils import pack_values, unpack_values

N = 50  # Number of test cases
IN_N = 4  # Number of inputs
OUT_N = 4  # Number of outputs
DATA_WIDTH = 8  # Bit width of input
MIN_VAL = -(1 << (DATA_WIDTH - 1))
MAX_VAL = (1 << (DATA_WIDTH - 1)) - 1
ACC_WIDTH = DATA_WIDTH + DATA_WIDTH + math.ceil(math.log2(IN_N))


def model_layer(x: torch.Tensor, w: torch.Tensor, b: torch.Tensor) -> torch.Tensor:
    """PyTorch model of the Layer."""
    # Linear transformation: output = x @ w.T + b
    # x: (IN_N,), w: (OUT_N, IN_N), so x @ w.T gives (OUT_N,)
    output = torch.matmul(x, w.T) + b

    # Quantizer: clamp to signed data_width-bit range
    quant = torch.clamp(output, MIN_VAL, MAX_VAL)

    # ReLU
    relu = torch.relu(quant)

    return relu


@cocotb.test()
async def test_layer_random(dut) -> None:
    """Test Layer module with random values."""

    # Clock setup
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    torch.manual_seed(0)

    dut._log.info(f"Test parameters: N={N}, IN_N={IN_N}, OUT_N={OUT_N}, DATA_WIDTH={DATA_WIDTH}")

    # Reset
    dut["rst_n"].value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut["rst_n"].value = 1

    # Generate all test values at once
    in_x = torch.randint(low=MIN_VAL, high=MAX_VAL + 1, size=(N, IN_N), dtype=torch.int32)
    in_w = torch.randint(low=MIN_VAL, high=MAX_VAL + 1, size=(N, OUT_N, IN_N), dtype=torch.int32)
    in_b = torch.randint(low=MIN_VAL, high=MAX_VAL + 1, size=(N, OUT_N), dtype=torch.int32)

    for i in range(N):
        # Calculate expected output
        expected_y = model_layer(in_x[i], in_w[i], in_b[i]).tolist()

        # Drive inputs
        dut["in_vec"].value = pack_values(in_x[i].tolist(), DATA_WIDTH)
        dut["weights"].value = pack_values(in_w[i].flatten().tolist(), DATA_WIDTH)
        dut["biases"].value = pack_values(in_b[i].tolist(), DATA_WIDTH)

        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)

        packed_out = dut["out_vec"].value
        got_vec = unpack_values(packed_out, OUT_N, DATA_WIDTH)

        assert got_vec == expected_y, f"Test Case {i} failed: expected={expected_y}, got={got_vec}"
    dut._log.info(f"All {N} tests passed")


def test_layer() -> None:
    """Test for the Layer module."""
    proj_path = Path(__file__).resolve().parent.parent

    sources = [
        f"{proj_path}/rtl/Layer.sv",
        f"{proj_path}/rtl/Perceptron.sv",
        f"{proj_path}/rtl/PreActivation.sv",
        f"{proj_path}/rtl/Quantizer.sv",
        f"{proj_path}/rtl/ReLU.sv",
    ]
    includes = [proj_path / "include"]

    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    # Use a unique build directory per test to avoid conflicts
    build_dir = f"{proj_path}/sim_build/Layer"

    build_kwargs = {
        "sources": sources,
        "hdl_toplevel": "Layer",
        "build_dir": build_dir,
        "includes": includes,
        "waves": True,
    }

    if sim == "verilator":
        build_kwargs["build_args"] = ["--timescale", "1ns/1ps"]

    runner.build(**build_kwargs)

    runner.test(
        hdl_toplevel="Layer",
        test_module="tb.test_layer",
        build_dir=build_dir,
        waves=True,
    )


if __name__ == "__main__":
    test_layer()
