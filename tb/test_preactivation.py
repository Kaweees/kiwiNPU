"""This module contains the cocotb Python test runner used to test ``PreActivation``."""

import math
import os
from pathlib import Path

import cocotb
import torch
from cocotb.triggers import Timer
from cocotb_tools.runner import get_runner
from utils import get_signed_value, pack_values

# Parameters
NUM_TESTS = 10  # Number of test cases
N = 4  # Vector dimensionality
DATA_WIDTH = 8  # Bit width of input and output
ACC_WIDTH = DATA_WIDTH * 2 + math.ceil(math.log2(N))
MIN_VAL = -(1 << (DATA_WIDTH - 1))
MAX_VAL = (1 << (DATA_WIDTH - 1)) - 1


def model_preactivation(x_vec: torch.Tensor, w_vec: torch.Tensor, b: int) -> int:
    """Python model of the PreActivation module: dot(x, w) + b."""
    return int(torch.dot(x_vec, w_vec).item()) + b


@cocotb.test()
async def preactivation_test(dut):
    """Test PreActivation module with generated test cases."""

    torch.manual_seed(42)

    dut._log.info(f"Test parameters: NUM_TESTS={NUM_TESTS}, N={N}, DATA_WIDTH={DATA_WIDTH}, ACC_WIDTH={ACC_WIDTH}")

    # Generate all test inputs at once
    in_x = torch.randint(MIN_VAL, MAX_VAL + 1, (NUM_TESTS, N), dtype=torch.int32)
    in_w = torch.randint(MIN_VAL, MAX_VAL + 1, (NUM_TESTS, N), dtype=torch.int32)
    in_b = torch.randint(MIN_VAL, MAX_VAL + 1, (NUM_TESTS,), dtype=torch.int32)

    # Initialize inputs to 0
    dut.x.value = 0
    dut.w.value = 0
    dut.b.value = 0
    await Timer(1, unit="step")

    for i in range(NUM_TESTS):
        x_list = in_x[i].tolist()
        w_list = in_w[i].tolist()
        b_val = int(in_b[i].item())
        expected = model_preactivation(in_x[i], in_w[i], b_val)

        dut.x.value = pack_values(x_list, DATA_WIDTH)
        dut.w.value = pack_values(w_list, DATA_WIDTH)
        dut.b.value = b_val

        await Timer(1, unit="step")

        pre_val = dut.pre.value
        if not pre_val.is_resolvable:
            await Timer(2, unit="step")
            pre_val = dut.pre.value
            assert pre_val.is_resolvable, f"Test Case {i}: Output contains X/Z values"

        got_signed = get_signed_value(pre_val.to_unsigned(), ACC_WIDTH)

        assert got_signed == expected, (
            f"Test Case {i} failed: x={x_list}, w={w_list}, b={b_val}, expected={expected}, got={got_signed}"
        )
        dut._log.info(f"Test Case {i} passed: PreActivation({x_list}, {w_list}, {b_val}) = {got_signed}")

    dut._log.info(f"All {NUM_TESTS} tests passed")


def test_preactivation():
    """Test for the PreActivation module."""
    proj_path = Path(__file__).resolve().parent.parent

    sources = [proj_path / "rtl" / "PreActivation.sv"]
    includes = [proj_path / "include"]

    sim = os.getenv("SIM", "icarus")
    runner = get_runner(sim)

    # Use a unique build directory per test to avoid conflicts
    build_dir = proj_path / "sim_build" / "PreActivation"

    runner.build(
        sources=sources,
        hdl_toplevel="PreActivation",
        build_dir=build_dir,
        includes=includes,
        waves=True,
    )

    runner.test(
        hdl_toplevel="PreActivation",
        test_module="test_preactivation",
        test_dir=f"{proj_path}/tb",
        build_dir=build_dir,
        waves=True,
    )


if __name__ == "__main__":
    test_preactivation()
