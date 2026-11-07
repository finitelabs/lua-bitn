--- Benchmarks for bitn.bit64: `make bench` runs them, and so does the with-tests build's benchmark().

local bit64 = require("bitn.bit64")
local _compat = require("bitn._compat")

local impl_name = _compat.impl_name

local benchmark_op = require("benchmark").benchmark_op

--- Run performance benchmarks for 64-bit operations.
local function benchmark()
  local iterations = 100000

  print("64-bit Bitwise Operations:")
  print(string.format("  Implementation: %s", impl_name()))

  -- Test values
  local a = bit64.new(0xAAAAAAAA, 0x55555555)
  local b = bit64.new(0x55555555, 0xAAAAAAAA)

  benchmark_op("band", function()
    bit64.band(a, b)
  end, iterations)

  benchmark_op("bor", function()
    bit64.bor(a, b)
  end, iterations)

  benchmark_op("bxor", function()
    bit64.bxor(a, b)
  end, iterations)

  benchmark_op("bnot", function()
    bit64.bnot(a)
  end, iterations)

  print("\n64-bit Shift Operations:")

  benchmark_op("lshift (small)", function()
    bit64.lshift(a, 8)
  end, iterations)

  benchmark_op("lshift (large)", function()
    bit64.lshift(a, 40)
  end, iterations)

  benchmark_op("rshift (small)", function()
    bit64.rshift(a, 8)
  end, iterations)

  benchmark_op("rshift (large)", function()
    bit64.rshift(a, 40)
  end, iterations)

  benchmark_op("arshift", function()
    bit64.arshift(bit64.new(0x80000000, 0), 8)
  end, iterations)

  print("\n64-bit Rotate Operations:")

  benchmark_op("rol (small)", function()
    bit64.rol(a, 8)
  end, iterations)

  benchmark_op("rol (large)", function()
    bit64.rol(a, 40)
  end, iterations)

  benchmark_op("ror (small)", function()
    bit64.ror(a, 8)
  end, iterations)

  benchmark_op("ror (large)", function()
    bit64.ror(a, 40)
  end, iterations)

  print("\n64-bit Arithmetic:")

  benchmark_op("add", function()
    bit64.add(a, b)
  end, iterations)

  benchmark_op("add (with carry)", function()
    bit64.add(bit64.new(0, 0xFFFFFFFF), bit64.new(0, 1))
  end, iterations)

  print("\n64-bit Byte Conversions:")

  local val = bit64.new(0x12345678, 0x9ABCDEF0)
  local bytes_be = bit64.u64_to_be_bytes(val)
  local bytes_le = bit64.u64_to_le_bytes(val)

  benchmark_op("u64_to_be_bytes", function()
    bit64.u64_to_be_bytes(val)
  end, iterations)

  benchmark_op("u64_to_le_bytes", function()
    bit64.u64_to_le_bytes(val)
  end, iterations)

  benchmark_op("be_bytes_to_u64", function()
    bit64.be_bytes_to_u64(bytes_be)
  end, iterations)

  benchmark_op("le_bytes_to_u64", function()
    bit64.le_bytes_to_u64(bytes_le)
  end, iterations)

  print("\n64-bit Utility Functions:")

  benchmark_op("new", function()
    bit64.new(0x12345678, 0x9ABCDEF0)
  end, iterations)

  benchmark_op("is_int64", function()
    bit64.is_int64(a)
  end, iterations)

  benchmark_op("to_hex", function()
    bit64.to_hex(a)
  end, iterations)

  benchmark_op("to_number", function()
    bit64.to_number(a)
  end, iterations)

  benchmark_op("from_number", function()
    bit64.from_number(12345678901234)
  end, iterations)

  benchmark_op("eq", function()
    bit64.eq(a, b)
  end, iterations)

  benchmark_op("is_zero", function()
    bit64.is_zero(a)
  end, iterations)
end

return benchmark
