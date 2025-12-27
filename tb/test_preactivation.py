from __future__ import annotations

import math
import os
from pathlib import Path

import cocotb
import numpy as np
from cocotb.triggers import Timer
from cocotb.types import LogicArray, Range
from cocotb_tools.runner import get_runner

# Parameters (must match RTL defaults in width.svh)
DATA_WIDTH = 8
N = 4
ACC_WIDTH = DATA_WIDTH * 2 + math.ceil(math.log2(N))


def pack_values(values, width):
    """Pack a list of integers into a single LogicArray.

    Handles signed values by converting to two's complement representation.
    values[0] is packed at LSB, values[-1] is packed at MSB.
    """
    total_bits = len(values) * width

    # Construct the packed integer
    # values[0] is at LSB, values[-1] is at MSB
    result = 0
    for val in reversed(values):
        # Convert signed value to unsigned representation for the given width
        # This handles two's complement correctly
        if val < 0:
            val = val + (1 << width)  # Convert to unsigned two's complement
        # Mask to width to ensure we pack correctly
        val = val & ((1 << width) - 1)
        result = (result << width) | val

    return LogicArray(result, Range(total_bits - 1, "downto", 0))


def get_signed_value(val, width):
    """Convert unsigned bit representation to signed integer."""
    if val >= (1 << (width - 1)):
        return val - (1 << width)
    return val


def model_preactivation(x_vec, w_vec, b, data_width=DATA_WIDTH, n=N):
    """
    Python model of the PreActivation module.
    x_vec: list of N integers
    w_vec: list of N integers
    b: bias integer
    """
    # Calculate dot product
    dot_product = sum(x * w for x, w in zip(x_vec, w_vec))

    # Add bias
    result = dot_product + b

    return result


def generate_test_cases(num_tests=10, seed=None):
    """Generate test cases similar to preactivation_generate.py"""
    min_val = -(2 ** (DATA_WIDTH - 1))
    max_val = 2 ** (DATA_WIDTH - 1) - 1

    if seed is not None:
        np.random.seed(seed)

    test_cases = []

    for i in range(num_tests):
        strategy = i % 6

        if strategy == 0:
            # Completely random values
            x = np.random.randint(min_val, max_val + 1, size=N).tolist()
            w = np.random.randint(min_val, max_val + 1, size=N).tolist()
        elif strategy == 1:
            # Small random values, less likely to overflow
            small_min = max(min_val // 4, -128)
            small_max = min(max_val // 4, 127)
            x = np.random.randint(small_min, small_max + 1, size=N).tolist()
            w = np.random.randint(small_min, small_max + 1, size=N).tolist()
        elif strategy == 2:
            # Positive/negative mix with low probability of overflow
            x = np.random.randint(0, max_val // 2 + 1, size=N).tolist()
            w = np.random.randint(min_val // 2, 1, size=N).tolist()
        elif strategy == 3:
            # Some values close to limits to test edge cases
            choices = np.array([min_val, max_val])
            x = [int(np.random.choice(choices)) for _ in range(N)]
            w = [int(np.random.choice(choices)) for _ in range(N)]
        elif strategy == 4:
            # Non-saturating: ensure dot(x, w) + b is within [-100, 100]
            x = np.random.randint(-8, 9, size=N).tolist()
            w = np.random.randint(-8, 9, size=N).tolist()
            dot_product = int(np.dot(x, w))
            min_b = max(min_val, -100 - dot_product)
            max_b = min(max_val, 100 - dot_product)
            b = int(np.random.randint(min_b, max_b + 1))
        else:
            # Some values close to limits to test edge cases
            choices = np.array([min_val, max_val])
            x = [int(np.random.choice(choices)) for _ in range(N)]
            w = [int(np.random.choice(choices)) for _ in range(N)]

        # Generate random bias if not already set (strategy 4 sets it)
        if strategy != 4:
            b = int(np.random.randint(min_val, max_val + 1))

        # Calculate expected result
        expected = model_preactivation(x, w, b)

        test_cases.append({"x": x, "w": w, "b": b, "expected": expected, "name": f"random_{i + 1}"})

    return test_cases


@cocotb.test()
async def preactivation_test(dut):
    """Test PreActivation module with generated test cases."""
    np.random.seed(42)  # Use a fixed seed for reproducibility

    NUM_TESTS = 10
    dut._log.info(f"Test parameters: N={N}, DATA_WIDTH={DATA_WIDTH}, ACC_WIDTH={ACC_WIDTH}")

    # Generate test cases
    test_cases = generate_test_cases(num_tests=NUM_TESTS, seed=42)
    dut._log.info(f"Generated {len(test_cases)} test cases")

    # Initialize inputs to 0 first
    dut.x.value = 0
    dut.w.value = 0
    dut.b.value = 0
    dut._log.info("Set initial values")

    await Timer(1, unit="step")

    for i, test in enumerate(test_cases):
        dut._log.info(f"Running test case {i}: {test['name']}")
        # Pack x and w vectors
        dut.x.value = pack_values(test["x"], DATA_WIDTH)
        dut.w.value = pack_values(test["w"], DATA_WIDTH)
        dut.b.value = test["b"]  # Assign signed value directly

        await Timer(1, unit="step")

        # Read output - handle X/Z values by checking if value is resolvable
        pre_val = dut.pre.value
        # Check if value contains X or Z
        if pre_val.is_resolvable:
            got_val = pre_val.to_unsigned()
            # Convert to signed
            got_signed = get_signed_value(got_val, ACC_WIDTH)
        else:
            # Value contains X/Z, wait a bit more using Timer
            await Timer(2, unit="step")
            pre_val = dut.pre.value
            if not pre_val.is_resolvable:
                dut._log.error(f"Test Case {i}: Output still contains X/Z values after waiting")
                dut._log.error(f"X: {test['x']}, W: {test['w']}, B: {test['b']}")
                assert False, f"Test Case {i}: Output contains X/Z values"
            got_val = pre_val.to_unsigned()
            got_signed = get_signed_value(got_val, ACC_WIDTH)

        expected = test["expected"]

        # Check result
        if got_signed != expected:
            dut._log.error(f"Test Case {i} ({test['name']}) failed!")
            dut._log.error(f"X: {test['x']}")
            dut._log.error(f"W: {test['w']}")
            dut._log.error(f"B: {test['b']}")
            dut._log.error(f"Expected: {expected}")
            dut._log.error(f"Got:      {got_signed}")
            assert False, f"Test Case {i} failed: expected={expected}, got={got_signed}"
        else:
            dut._log.info(
                f"Test Case {i} ({test['name']}) passed: PreActivation({test['x']}, {test['w']}, {test['b']}) = {got_signed}"
            )

    dut._log.info(f"All {NUM_TESTS} tests passed")


def test_preactivation():
    """Test for the PreActivation module.

    Creates sources list, gets a cocotb Python Runner,
    builds HDL, runs cocotb testcases.
    """
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
        test_module="tb.test_preactivation",
        build_dir=build_dir,
        waves=True,
    )


if __name__ == "__main__":
    test_preactivation()
