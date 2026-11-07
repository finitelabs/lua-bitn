--- Benchmarks for bitn.bit32: `make bench` runs them, and so does the with-tests build's benchmark().

local bit32 = require("bitn.bit32")
local _compat = require("bitn._compat")

local impl_name = _compat.impl_name

local benchmark_op = require("benchmark").benchmark_op

--- Run performance benchmarks for 32-bit operations.
local function benchmark()
  local iterations = 100000

  print("32-bit Bitwise Operations:")
  print(string.format("  Implementation: %s", impl_name()))

  -- Test values
  local a, b = 0xAAAAAAAA, 0x55555555

  benchmark_op("band", function()
    bit32.band(a, b)
  end, iterations)

  benchmark_op("bor", function()
    bit32.bor(a, b)
  end, iterations)

  benchmark_op("bxor", function()
    bit32.bxor(a, b)
  end, iterations)

  benchmark_op("bnot", function()
    bit32.bnot(a)
  end, iterations)

  print("\n32-bit Shift Operations:")

  benchmark_op("lshift", function()
    bit32.lshift(a, 8)
  end, iterations)

  benchmark_op("rshift", function()
    bit32.rshift(a, 8)
  end, iterations)

  benchmark_op("arshift", function()
    bit32.arshift(0x80000000, 8)
  end, iterations)

  print("\n32-bit Rotate Operations:")

  benchmark_op("rol", function()
    bit32.rol(a, 8)
  end, iterations)

  benchmark_op("ror", function()
    bit32.ror(a, 8)
  end, iterations)

  print("\n32-bit Arithmetic:")

  benchmark_op("add", function()
    bit32.add(a, b)
  end, iterations)

  benchmark_op("mask", function()
    bit32.mask(0x123456789)
  end, iterations)

  print("\n32-bit Byte Conversions:")

  local bytes_be = bit32.u32_to_be_bytes(0x12345678)
  local bytes_le = bit32.u32_to_le_bytes(0x12345678)

  benchmark_op("u32_to_be_bytes", function()
    bit32.u32_to_be_bytes(0x12345678)
  end, iterations)

  benchmark_op("u32_to_le_bytes", function()
    bit32.u32_to_le_bytes(0x12345678)
  end, iterations)

  benchmark_op("be_bytes_to_u32", function()
    bit32.be_bytes_to_u32(bytes_be)
  end, iterations)

  benchmark_op("le_bytes_to_u32", function()
    bit32.le_bytes_to_u32(bytes_le)
  end, iterations)
end

return benchmark
