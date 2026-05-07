# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

async def reset(dut):
    # Reset
    dut._log.info("Reset")
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1);
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3);
    dut.rst_n.value = 1

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 40ns (25MHz)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    await Timer(5, "us")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await Timer(5, "us")
    await reset(dut)

    dut._log.info("Test project behavior")

    # This does not actually test anything, we just run for a bit so we can
    # examine the trace
    await Timer(1, "ms")
