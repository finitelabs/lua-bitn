--- Benchmarks for bitn.bit16: `make bench` runs them, and so does the with-tests build's benchmark().

local bit16 = require("bitn.bit16")
local _compat = require("bitn._compat")

local impl_name = _compat.impl_name

local benchmark_op = require("benchmark").benchmark_op

--- Run performance benchmarks for 16-bit operations.
local function benchmark()
  local iterations = 100000

  print("16-bit Bitwise Operations:")
  print(string.format("  Implementation: %s", impl_name()))

  -- Test values
  local a, b = 0xAAAA, 0x5555

  benchmark_op("band", function()
    bit16.band(a, b)
  end, iterations)

  benchmark_op("bor", function()
    bit16.bor(a, b)
  end, iterations)

  benchmark_op("bxor", function()
    bit16.bxor(a, b)
  end, iterations)

  benchmark_op("bnot", function()
    bit16.bnot(a)
  end, iterations)

  print("\n16-bit Shift Operations:")

  benchmark_op("lshift", function()
    bit16.lshift(a, 4)
  end, iterations)

  benchmark_op("rshift", function()
    bit16.rshift(a, 4)
  end, iterations)

  benchmark_op("arshift", function()
    bit16.arshift(0x8000, 4)
  end, iterations)

  print("\n16-bit Rotate Operations:")

  benchmark_op("rol", function()
    bit16.rol(a, 4)
  end, iterations)

  benchmark_op("ror", function()
    bit16.ror(a, 4)
  end, iterations)

  print("\n16-bit Arithmetic:")

  benchmark_op("add", function()
    bit16.add(a, b)
  end, iterations)

  benchmark_op("mask", function()
    bit16.mask(0x12345)
  end, iterations)

  print("\n16-bit Byte Conversions:")

  local bytes_be = bit16.u16_to_be_bytes(0x1234)
  local bytes_le = bit16.u16_to_le_bytes(0x1234)

  benchmark_op("u16_to_be_bytes", function()
    bit16.u16_to_be_bytes(0x1234)
  end, iterations)

  benchmark_op("u16_to_le_bytes", function()
    bit16.u16_to_le_bytes(0x1234)
  end, iterations)

  benchmark_op("be_bytes_to_u16", function()
    bit16.be_bytes_to_u16(bytes_be)
  end, iterations)

  benchmark_op("le_bytes_to_u16", function()
    bit16.le_bytes_to_u16(bytes_le)
  end, iterations)
end

return benchmark
