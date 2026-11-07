--- Tests for bitn.bit64: `make test` runs them, and so does the with-tests build's selftest().

local bit64 = require("bitn.bit64")
local _compat = require("bitn._compat")

local impl_name = _compat.impl_name

-- Compatibility for unpack
local unpack_fn = unpack or table.unpack

--- Compare two 64-bit values (high/low pairs).
--- @param a Int64HighLow First value {high, low}
--- @param b Int64HighLow Second value {high, low}
--- @return boolean equal True if equal
local function eq64(a, b)
  return a[1] == b[1] and a[2] == b[2]
end

--- Format 64-bit value as hex string.
--- @param x Int64HighLow Value {high, low}
--- @return string formatted Hex string
local function fmt64(x)
  return string.format("{0x%08X, 0x%08X}", x[1], x[2])
end

--- Run comprehensive self-test with test vectors.
--- @return boolean result True if all tests pass, false otherwise
local function selftest()
  print("Running 64-bit operations test vectors...")
  print(string.format("  Using: %s", impl_name()))
  local passed = 0
  local total = 0

  local test_vectors = {
    -- band tests
    {
      name = "band({0xFFFFFFFF, 0}, {0, 0xFFFFFFFF})",
      fn = bit64.band,
      inputs = { { 0xFFFFFFFF, 0 }, { 0, 0xFFFFFFFF } },
      expected = { 0, 0 },
    },
    {
      name = "band({0xFFFFFFFF, 0xFFFFFFFF}, {0xFFFFFFFF, 0xFFFFFFFF})",
      fn = bit64.band,
      inputs = { { 0xFFFFFFFF, 0xFFFFFFFF }, { 0xFFFFFFFF, 0xFFFFFFFF } },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "band({0xAAAAAAAA, 0x55555555}, {0x55555555, 0xAAAAAAAA})",
      fn = bit64.band,
      inputs = { { 0xAAAAAAAA, 0x55555555 }, { 0x55555555, 0xAAAAAAAA } },
      expected = { 0, 0 },
    },

    -- bor tests
    {
      name = "bor({0xFFFF0000, 0}, {0, 0x0000FFFF})",
      fn = bit64.bor,
      inputs = { { 0xFFFF0000, 0 }, { 0, 0x0000FFFF } },
      expected = { 0xFFFF0000, 0x0000FFFF },
    },
    { name = "bor({0, 0}, {0, 0})", fn = bit64.bor, inputs = { { 0, 0 }, { 0, 0 } }, expected = { 0, 0 } },
    {
      name = "bor({0xAAAAAAAA, 0x55555555}, {0x55555555, 0xAAAAAAAA})",
      fn = bit64.bor,
      inputs = { { 0xAAAAAAAA, 0x55555555 }, { 0x55555555, 0xAAAAAAAA } },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },

    -- bxor tests
    {
      name = "bxor({0xFFFFFFFF, 0}, {0, 0xFFFFFFFF})",
      fn = bit64.bxor,
      inputs = { { 0xFFFFFFFF, 0 }, { 0, 0xFFFFFFFF } },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "bxor({0x12345678, 0x9ABCDEF0}, {0x12345678, 0x9ABCDEF0})",
      fn = bit64.bxor,
      inputs = { { 0x12345678, 0x9ABCDEF0 }, { 0x12345678, 0x9ABCDEF0 } },
      expected = { 0, 0 },
    },

    -- bnot tests
    { name = "bnot({0, 0})", fn = bit64.bnot, inputs = { { 0, 0 } }, expected = { 0xFFFFFFFF, 0xFFFFFFFF } },
    {
      name = "bnot({0xFFFFFFFF, 0xFFFFFFFF})",
      fn = bit64.bnot,
      inputs = { { 0xFFFFFFFF, 0xFFFFFFFF } },
      expected = { 0, 0 },
    },
    {
      name = "bnot({0xAAAAAAAA, 0x55555555})",
      fn = bit64.bnot,
      inputs = { { 0xAAAAAAAA, 0x55555555 } },
      expected = { 0x55555555, 0xAAAAAAAA },
    },

    -- lshift tests
    { name = "lshift({0, 1}, 0)", fn = bit64.lshift, inputs = { { 0, 1 }, 0 }, expected = { 0, 1 } },
    { name = "lshift({0, 1}, 1)", fn = bit64.lshift, inputs = { { 0, 1 }, 1 }, expected = { 0, 2 } },
    { name = "lshift({0, 1}, 32)", fn = bit64.lshift, inputs = { { 0, 1 }, 32 }, expected = { 1, 0 } },
    { name = "lshift({0, 1}, 63)", fn = bit64.lshift, inputs = { { 0, 1 }, 63 }, expected = { 0x80000000, 0 } },
    { name = "lshift({0, 1}, 64)", fn = bit64.lshift, inputs = { { 0, 1 }, 64 }, expected = { 0, 0 } },
    {
      name = "lshift({0, 0xFFFFFFFF}, 8)",
      fn = bit64.lshift,
      inputs = { { 0, 0xFFFFFFFF }, 8 },
      expected = { 0xFF, 0xFFFFFF00 },
    },

    -- rshift tests
    { name = "rshift({0, 1}, 0)", fn = bit64.rshift, inputs = { { 0, 1 }, 0 }, expected = { 0, 1 } },
    { name = "rshift({0, 2}, 1)", fn = bit64.rshift, inputs = { { 0, 2 }, 1 }, expected = { 0, 1 } },
    { name = "rshift({1, 0}, 32)", fn = bit64.rshift, inputs = { { 1, 0 }, 32 }, expected = { 0, 1 } },
    {
      name = "rshift({0x80000000, 0}, 63)",
      fn = bit64.rshift,
      inputs = { { 0x80000000, 0 }, 63 },
      expected = { 0, 1 },
    },
    { name = "rshift({1, 0}, 64)", fn = bit64.rshift, inputs = { { 1, 0 }, 64 }, expected = { 0, 0 } },
    {
      name = "rshift({0xFF000000, 0}, 8)",
      fn = bit64.rshift,
      inputs = { { 0xFF000000, 0 }, 8 },
      expected = { 0x00FF0000, 0 },
    },

    -- arshift tests (sign-extending)
    {
      name = "arshift({0x80000000, 0}, 1)",
      fn = bit64.arshift,
      inputs = { { 0x80000000, 0 }, 1 },
      expected = { 0xC0000000, 0 },
    },
    {
      name = "arshift({0x80000000, 0}, 32)",
      fn = bit64.arshift,
      inputs = { { 0x80000000, 0 }, 32 },
      expected = { 0xFFFFFFFF, 0x80000000 },
    },
    {
      name = "arshift({0x80000000, 0}, 63)",
      fn = bit64.arshift,
      inputs = { { 0x80000000, 0 }, 63 },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "arshift({0x80000000, 0}, 64)",
      fn = bit64.arshift,
      inputs = { { 0x80000000, 0 }, 64 },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "arshift({0x7FFFFFFF, 0xFFFFFFFF}, 1)",
      fn = bit64.arshift,
      inputs = { { 0x7FFFFFFF, 0xFFFFFFFF }, 1 },
      expected = { 0x3FFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "arshift({0x7FFFFFFF, 0}, 63)",
      fn = bit64.arshift,
      inputs = { { 0x7FFFFFFF, 0 }, 63 },
      expected = { 0, 0 },
    },

    -- rol tests
    { name = "rol({0, 1}, 0)", fn = bit64.rol, inputs = { { 0, 1 }, 0 }, expected = { 0, 1 } },
    { name = "rol({0, 1}, 1)", fn = bit64.rol, inputs = { { 0, 1 }, 1 }, expected = { 0, 2 } },
    { name = "rol({0x80000000, 0}, 1)", fn = bit64.rol, inputs = { { 0x80000000, 0 }, 1 }, expected = { 0, 1 } },
    { name = "rol({0, 1}, 32)", fn = bit64.rol, inputs = { { 0, 1 }, 32 }, expected = { 1, 0 } },
    { name = "rol({0, 1}, 64)", fn = bit64.rol, inputs = { { 0, 1 }, 64 }, expected = { 0, 1 } },
    {
      name = "rol({0x12345678, 0x9ABCDEF0}, 16)",
      fn = bit64.rol,
      inputs = { { 0x12345678, 0x9ABCDEF0 }, 16 },
      expected = { 0x56789ABC, 0xDEF01234 },
    },

    -- ror tests
    { name = "ror({0, 1}, 0)", fn = bit64.ror, inputs = { { 0, 1 }, 0 }, expected = { 0, 1 } },
    { name = "ror({0, 1}, 1)", fn = bit64.ror, inputs = { { 0, 1 }, 1 }, expected = { 0x80000000, 0 } },
    { name = "ror({0, 2}, 1)", fn = bit64.ror, inputs = { { 0, 2 }, 1 }, expected = { 0, 1 } },
    { name = "ror({1, 0}, 32)", fn = bit64.ror, inputs = { { 1, 0 }, 32 }, expected = { 0, 1 } },
    { name = "ror({0, 1}, 64)", fn = bit64.ror, inputs = { { 0, 1 }, 64 }, expected = { 0, 1 } },
    {
      name = "ror({0x12345678, 0x9ABCDEF0}, 16)",
      fn = bit64.ror,
      inputs = { { 0x12345678, 0x9ABCDEF0 }, 16 },
      expected = { 0xDEF01234, 0x56789ABC },
    },

    -- add tests
    { name = "add({0, 0}, {0, 0})", fn = bit64.add, inputs = { { 0, 0 }, { 0, 0 } }, expected = { 0, 0 } },
    { name = "add({0, 1}, {0, 1})", fn = bit64.add, inputs = { { 0, 1 }, { 0, 1 } }, expected = { 0, 2 } },
    {
      name = "add({0, 0xFFFFFFFF}, {0, 1})",
      fn = bit64.add,
      inputs = { { 0, 0xFFFFFFFF }, { 0, 1 } },
      expected = { 1, 0 },
    },
    {
      name = "add({0xFFFFFFFF, 0xFFFFFFFF}, {0, 1})",
      fn = bit64.add,
      inputs = { { 0xFFFFFFFF, 0xFFFFFFFF }, { 0, 1 } },
      expected = { 0, 0 },
    },
    {
      name = "add({0xFFFFFFFF, 0xFFFFFFFF}, {0, 2})",
      fn = bit64.add,
      inputs = { { 0xFFFFFFFF, 0xFFFFFFFF }, { 0, 2 } },
      expected = { 0, 1 },
    },

    -- u64_to_be_bytes tests
    {
      name = "u64_to_be_bytes({0, 0})",
      fn = bit64.u64_to_be_bytes,
      inputs = { { 0, 0 } },
      expected = string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u64_to_be_bytes({0, 1})",
      fn = bit64.u64_to_be_bytes,
      inputs = { { 0, 1 } },
      expected = string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01),
    },
    {
      name = "u64_to_be_bytes({0x12345678, 0x9ABCDEF0})",
      fn = bit64.u64_to_be_bytes,
      inputs = { { 0x12345678, 0x9ABCDEF0 } },
      expected = string.char(0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0),
    },

    -- u64_to_le_bytes tests
    {
      name = "u64_to_le_bytes({0, 0})",
      fn = bit64.u64_to_le_bytes,
      inputs = { { 0, 0 } },
      expected = string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u64_to_le_bytes({0, 1})",
      fn = bit64.u64_to_le_bytes,
      inputs = { { 0, 1 } },
      expected = string.char(0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u64_to_le_bytes({0x12345678, 0x9ABCDEF0})",
      fn = bit64.u64_to_le_bytes,
      inputs = { { 0x12345678, 0x9ABCDEF0 } },
      expected = string.char(0xF0, 0xDE, 0xBC, 0x9A, 0x78, 0x56, 0x34, 0x12),
    },

    -- be_bytes_to_u64 tests
    {
      name = "be_bytes_to_u64(zeros)",
      fn = bit64.be_bytes_to_u64,
      inputs = { string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) },
      expected = { 0, 0 },
    },
    {
      name = "be_bytes_to_u64(one)",
      fn = bit64.be_bytes_to_u64,
      inputs = { string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01) },
      expected = { 0, 1 },
    },
    {
      name = "be_bytes_to_u64(0x123456789ABCDEF0)",
      fn = bit64.be_bytes_to_u64,
      inputs = { string.char(0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0) },
      expected = { 0x12345678, 0x9ABCDEF0 },
    },

    -- le_bytes_to_u64 tests
    {
      name = "le_bytes_to_u64(zeros)",
      fn = bit64.le_bytes_to_u64,
      inputs = { string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) },
      expected = { 0, 0 },
    },
    {
      name = "le_bytes_to_u64(one)",
      fn = bit64.le_bytes_to_u64,
      inputs = { string.char(0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) },
      expected = { 0, 1 },
    },
    {
      name = "le_bytes_to_u64(0x123456789ABCDEF0)",
      fn = bit64.le_bytes_to_u64,
      inputs = { string.char(0xF0, 0xDE, 0xBC, 0x9A, 0x78, 0x56, 0x34, 0x12) },
      expected = { 0x12345678, 0x9ABCDEF0 },
    },

    -- to_hex tests
    {
      name = "to_hex({0x00001800, 0x00001000})",
      fn = bit64.to_hex,
      inputs = { { 0x00001800, 0x00001000 } },
      expected = "0000180000001000",
    },
    {
      name = "to_hex({0xFFFFFFFF, 0xFFFFFFFF})",
      fn = bit64.to_hex,
      inputs = { { 0xFFFFFFFF, 0xFFFFFFFF } },
      expected = "FFFFFFFFFFFFFFFF",
    },
    {
      name = "to_hex({0x00000000, 0x00000000})",
      fn = bit64.to_hex,
      inputs = { { 0x00000000, 0x00000000 } },
      expected = "0000000000000000",
    },

    -- to_number tests
    {
      name = "to_number({0x00000000, 0x00000001})",
      fn = bit64.to_number,
      inputs = { bit64.new(0x00000000, 0x00000001) },
      expected = 1,
    },
    {
      name = "to_number({0x00000000, 0xFFFFFFFF})",
      fn = bit64.to_number,
      inputs = { bit64.new(0x00000000, 0xFFFFFFFF) },
      expected = 4294967295,
    },
    {
      name = "to_number({0x00000001, 0x00000000})",
      fn = bit64.to_number,
      inputs = { bit64.new(0x00000001, 0x00000000) },
      expected = 4294967296,
    },

    -- from_number tests
    {
      name = "from_number(1)",
      fn = bit64.from_number,
      inputs = { 1 },
      expected = { 0x00000000, 0x00000001 },
    },
    {
      name = "from_number(4294967296)",
      fn = bit64.from_number,
      inputs = { 4294967296 },
      expected = { 0x00000001, 0x00000000 },
    },
    {
      name = "from_number(0)",
      fn = bit64.from_number,
      inputs = { 0 },
      expected = { 0x00000000, 0x00000000 },
    },
    {
      name = "from_number(-1)",
      fn = bit64.from_number,
      inputs = { -1 },
      expected = { 0xFFFFFFFF, 0xFFFFFFFF },
    },
    {
      name = "from_number(-2^70) wraps to 64 bits",
      fn = bit64.from_number,
      inputs = { -(2 ^ 70) },
      expected = { 0x00000000, 0x00000000 },
    },

    -- eq tests
    { name = "eq({1,2}, {1,2})", fn = bit64.eq, inputs = { { 1, 2 }, { 1, 2 } }, expected = true },
    { name = "eq({1,2}, {1,3})", fn = bit64.eq, inputs = { { 1, 2 }, { 1, 3 } }, expected = false },
    { name = "eq({1,2}, {2,2})", fn = bit64.eq, inputs = { { 1, 2 }, { 2, 2 } }, expected = false },

    -- is_zero tests
    { name = "is_zero({0,0})", fn = bit64.is_zero, inputs = { { 0, 0 } }, expected = true },
    { name = "is_zero({0,1})", fn = bit64.is_zero, inputs = { { 0, 1 } }, expected = false },
    { name = "is_zero({1,0})", fn = bit64.is_zero, inputs = { { 1, 0 } }, expected = false },

    -- to_number strict mode tests (values within 53-bit range)
    {
      name = "to_number({0x001FFFFF, 0xFFFFFFFF}, true) -- max 53-bit",
      fn = bit64.to_number,
      inputs = { bit64.new(0x001FFFFF, 0xFFFFFFFF), true },
      expected = 9007199254740991,
    },
    {
      name = "to_number({0, 1}, true)",
      fn = bit64.to_number,
      inputs = { bit64.new(0, 1), true },
      expected = 1,
    },
  }

  for _, test in ipairs(test_vectors) do
    total = total + 1
    local result = test.fn(unpack_fn(test.inputs))
    -- Held in a local so the type narrowing below applies to it; a table field
    -- is not narrowed by a `type()` check.
    local expected = test.expected

    if type(expected) == "table" then
      -- 64-bit comparison
      if eq64(result, expected) then
        print("  PASS: " .. test.name)
        passed = passed + 1
      else
        print("  FAIL: " .. test.name)
        print("    Expected: " .. fmt64(expected))
        print("    Got:      " .. fmt64(result))
      end
    elseif type(expected) == "string" then
      -- Byte string comparison
      if result == expected then
        print("  PASS: " .. test.name)
        passed = passed + 1
      else
        print("  FAIL: " .. test.name)
        if type(result) ~= "string" then
          print("    Expected: string")
          print("    Got:      " .. type(result))
        else
          local exp_hex, got_hex = "", ""
          for i = 1, #expected do
            exp_hex = exp_hex .. string.format("%02X", string.byte(expected, i))
          end
          for i = 1, #result do
            got_hex = got_hex .. string.format("%02X", string.byte(result, i))
          end
          print("    Expected: " .. exp_hex)
          print("    Got:      " .. got_hex)
        end
      end
    else
      if result == expected then
        print("  PASS: " .. test.name)
        passed = passed + 1
      else
        print("  FAIL: " .. test.name)
        print("    Expected: " .. tostring(expected))
        print("    Got:      " .. tostring(result))
      end
    end
  end

  -- Int64 type identification tests
  print("\nRunning Int64 type identification tests...")

  -- Test bit64.new() creates Int64 values
  total = total + 1
  local new_val = bit64.new(0x12345678, 0x9ABCDEF0)
  if bit64.is_int64(new_val) and new_val[1] == 0x12345678 and new_val[2] == 0x9ABCDEF0 then
    print("  PASS: new() creates Int64 with correct values")
    passed = passed + 1
  else
    print("  FAIL: new() creates Int64 with correct values")
  end

  -- Test bit64.new() with defaults
  total = total + 1
  local zero_val = bit64.new()
  if bit64.is_int64(zero_val) and zero_val[1] == 0 and zero_val[2] == 0 then
    print("  PASS: new() with no args creates {0, 0}")
    passed = passed + 1
  else
    print("  FAIL: new() with no args creates {0, 0}")
  end

  -- Test bit64.new() normalizes negative values (LuaJIT raw_* compatibility)
  total = total + 1
  local neg_val = bit64.new(-1, -2147483648) -- -1 -> 0xFFFFFFFF, -2147483648 -> 0x80000000
  if bit64.is_int64(neg_val) and neg_val[1] == 0xFFFFFFFF and neg_val[2] == 0x80000000 then
    print("  PASS: new() normalizes negative values to unsigned")
    passed = passed + 1
  else
    print("  FAIL: new() normalizes negative values to unsigned")
    print(string.format("    Expected: {0x%08X, 0x%08X}", 0xFFFFFFFF, 0x80000000))
    print(string.format("    Got:      {0x%08X, 0x%08X}", neg_val[1], neg_val[2]))
  end

  -- Test is_int64() returns false for regular tables
  total = total + 1
  local plain_table = { 0x12345678, 0x9ABCDEF0 }
  if not bit64.is_int64(plain_table) then
    print("  PASS: is_int64() returns false for plain table")
    passed = passed + 1
  else
    print("  FAIL: is_int64() returns false for plain table")
  end

  -- Test is_int64() returns false for non-tables
  total = total + 1
  if not bit64.is_int64(123) and not bit64.is_int64("string") and not bit64.is_int64(nil) then
    print("  PASS: is_int64() returns false for non-tables")
    passed = passed + 1
  else
    print("  FAIL: is_int64() returns false for non-tables")
  end

  -- Test all operations return Int64 values
  local ops_returning_int64 = {
    {
      name = "band",
      fn = function()
        return bit64.band(bit64.new(1, 2), bit64.new(3, 4))
      end,
    },
    {
      name = "bor",
      fn = function()
        return bit64.bor(bit64.new(1, 2), bit64.new(3, 4))
      end,
    },
    {
      name = "bxor",
      fn = function()
        return bit64.bxor(bit64.new(1, 2), bit64.new(3, 4))
      end,
    },
    {
      name = "bnot",
      fn = function()
        return bit64.bnot(bit64.new(1, 2))
      end,
    },
    {
      name = "lshift",
      fn = function()
        return bit64.lshift(bit64.new(1, 2), 1)
      end,
    },
    {
      name = "rshift",
      fn = function()
        return bit64.rshift(bit64.new(1, 2), 1)
      end,
    },
    {
      name = "arshift",
      fn = function()
        return bit64.arshift(bit64.new(1, 2), 1)
      end,
    },
    {
      name = "rol",
      fn = function()
        return bit64.rol(bit64.new(1, 2), 1)
      end,
    },
    {
      name = "ror",
      fn = function()
        return bit64.ror(bit64.new(1, 2), 1)
      end,
    },
    {
      name = "add",
      fn = function()
        return bit64.add(bit64.new(1, 2), bit64.new(3, 4))
      end,
    },
    {
      name = "be_bytes_to_u64",
      fn = function()
        return bit64.be_bytes_to_u64("\0\0\0\1\0\0\0\2")
      end,
    },
    {
      name = "le_bytes_to_u64",
      fn = function()
        return bit64.le_bytes_to_u64("\2\0\0\0\1\0\0\0")
      end,
    },
  }

  for _, op in ipairs(ops_returning_int64) do
    total = total + 1
    local result = op.fn()
    if bit64.is_int64(result) then
      print("  PASS: " .. op.name .. "() returns Int64")
      passed = passed + 1
    else
      print("  FAIL: " .. op.name .. "() returns Int64")
    end
  end

  -- Test to_number strict mode error case
  print("\nRunning to_number/from_number edge case tests...")
  total = total + 1
  local ok, err = pcall(function()
    bit64.to_number(bit64.new(0x00200000, 0x00000000), true) -- 2^53, exceeds 53-bit
  end)
  if not ok and type(err) == "string" and string.find(err, "53%-bit precision") then
    print("  PASS: to_number strict mode errors on values > 53 bits")
    passed = passed + 1
  else
    print("  FAIL: to_number strict mode errors on values > 53 bits")
    if ok then
      print("    Expected error but got success")
    else
      print("    Expected '53-bit precision' error but got: " .. tostring(err))
    end
  end

  -- Test to_number pass-through for number input
  total = total + 1
  local num_input = 12345
  local num_result = bit64.to_number(num_input)
  if num_result == num_input then
    print("  PASS: to_number passes through number input unchanged")
    passed = passed + 1
  else
    print("  FAIL: to_number passes through number input unchanged")
    print("    Expected: " .. tostring(num_input))
    print("    Got:      " .. tostring(num_result))
  end

  -- Test to_number errors on plain table (non-Int64)
  total = total + 1
  ok, err = pcall(function()
    bit64.to_number({ 1, 2 }) -- plain table, not Int64
  end)
  if not ok and type(err) == "string" and string.find(err, "not a valid Int64") then
    print("  PASS: to_number errors on plain table (non-Int64)")
    passed = passed + 1
  else
    print("  FAIL: to_number errors on plain table (non-Int64)")
    if ok then
      print("    Expected error but got success")
    else
      print("    Expected 'not a valid Int64' error but got: " .. tostring(err))
    end
  end

  -- Test from_number pass-through for Int64 input
  total = total + 1
  local int64_input = bit64.new(0x12345678, 0x9ABCDEF0)
  local int64_result = bit64.from_number(int64_input)
  if rawequal(int64_result, int64_input) then
    print("  PASS: from_number passes through Int64 input unchanged")
    passed = passed + 1
  else
    print("  FAIL: from_number passes through Int64 input unchanged")
    print("    Expected same reference, got different object")
  end

  -- Test raw_* operations
  print("\n  Testing raw_* operations...")

  local raw_tests = {
    -- Core bitwise (test high-bit cases where sign matters)
    {
      name = "raw_band(new(0xFFFFFFFF, 0x80000000), new(0x80000000, 0xFFFFFFFF))",
      fn = function()
        return bit64.raw_band(bit64.new(0xFFFFFFFF, 0x80000000), bit64.new(0x80000000, 0xFFFFFFFF))
      end,
      expected = bit64.new(0x80000000, 0x80000000),
    },
    {
      name = "raw_bor(new(0x80000000, 0), new(0, 0x80000000))",
      fn = function()
        return bit64.raw_bor(bit64.new(0x80000000, 0), bit64.new(0, 0x80000000))
      end,
      expected = bit64.new(0x80000000, 0x80000000),
    },
    {
      name = "raw_bxor(new(0xAAAAAAAA, 0x55555555), new(0x55555555, 0xAAAAAAAA))",
      fn = function()
        return bit64.raw_bxor(bit64.new(0xAAAAAAAA, 0x55555555), bit64.new(0x55555555, 0xAAAAAAAA))
      end,
      expected = bit64.new(0xFFFFFFFF, 0xFFFFFFFF),
    },
    {
      name = "raw_bnot(new(0, 0))",
      fn = function()
        return bit64.raw_bnot(bit64.new(0, 0))
      end,
      expected = bit64.new(0xFFFFFFFF, 0xFFFFFFFF),
    },

    -- Shifts
    {
      name = "raw_lshift(new(0, 1), 63)",
      fn = function()
        return bit64.raw_lshift(bit64.new(0, 1), 63)
      end,
      expected = bit64.new(0x80000000, 0),
    },
    {
      name = "raw_rshift(new(0x80000000, 0), 63)",
      fn = function()
        return bit64.raw_rshift(bit64.new(0x80000000, 0), 63)
      end,
      expected = bit64.new(0, 1),
    },
    {
      name = "raw_arshift(new(0x80000000, 0), 32)",
      fn = function()
        return bit64.raw_arshift(bit64.new(0x80000000, 0), 32)
      end,
      expected = bit64.new(0xFFFFFFFF, 0x80000000),
    },

    -- Rotates
    {
      name = "raw_rol(new(0x12345678, 0x9ABCDEF0), 16)",
      fn = function()
        return bit64.raw_rol(bit64.new(0x12345678, 0x9ABCDEF0), 16)
      end,
      expected = bit64.new(0x56789ABC, 0xDEF01234),
    },
    {
      name = "raw_ror(new(0x12345678, 0x9ABCDEF0), 16)",
      fn = function()
        return bit64.raw_ror(bit64.new(0x12345678, 0x9ABCDEF0), 16)
      end,
      expected = bit64.new(0xDEF01234, 0x56789ABC),
    },

    -- Addition
    {
      name = "raw_add(new(0xFFFFFFFF, 0xFFFFFFFF), new(0, 1))",
      fn = function()
        return bit64.raw_add(bit64.new(0xFFFFFFFF, 0xFFFFFFFF), bit64.new(0, 1))
      end,
      expected = bit64.new(0, 0),
    },
  }

  for _, test in ipairs(raw_tests) do
    total = total + 1
    local result = test.fn()
    if eq64(result, test.expected) then
      print("  PASS: " .. test.name)
      passed = passed + 1
    else
      print("  FAIL: " .. test.name)
      print("    Expected: " .. fmt64(test.expected))
      print("    Got:      " .. fmt64(result))
    end
  end

  -- Test that raw_* operations return Int64
  print("\n  Testing raw_* operations return Int64...")
  local raw_ops_returning_int64 = {
    {
      name = "raw_band",
      fn = function()
        return bit64.raw_band(bit64.new(1, 2), bit64.new(3, 4))
      end,
    },
    {
      name = "raw_bor",
      fn = function()
        return bit64.raw_bor(bit64.new(1, 2), bit64.new(3, 4))
      end,
    },
    {
      name = "raw_bxor",
      fn = function()
        return bit64.raw_bxor(bit64.new(1, 2), bit64.new(3, 4))
      end,
    },
    {
      name = "raw_bnot",
      fn = function()
        return bit64.raw_bnot(bit64.new(1, 2))
      end,
    },
    {
      name = "raw_lshift",
      fn = function()
        return bit64.raw_lshift(bit64.new(1, 2), 1)
      end,
    },
    {
      name = "raw_rshift",
      fn = function()
        return bit64.raw_rshift(bit64.new(1, 2), 1)
      end,
    },
    {
      name = "raw_arshift",
      fn = function()
        return bit64.raw_arshift(bit64.new(1, 2), 1)
      end,
    },
    {
      name = "raw_rol",
      fn = function()
        return bit64.raw_rol(bit64.new(1, 2), 1)
      end,
    },
    {
      name = "raw_ror",
      fn = function()
        return bit64.raw_ror(bit64.new(1, 2), 1)
      end,
    },
    {
      name = "raw_add",
      fn = function()
        return bit64.raw_add(bit64.new(1, 2), bit64.new(3, 4))
      end,
    },
  }

  for _, op in ipairs(raw_ops_returning_int64) do
    total = total + 1
    local result = op.fn()
    if bit64.is_int64(result) then
      print("  PASS: " .. op.name .. "() returns Int64")
      passed = passed + 1
    else
      print("  FAIL: " .. op.name .. "() returns Int64")
    end
  end

  total = total + 1
  if 1 / bit64.from_number(-1 / math.huge)[1] > 0 then
    print("  PASS: from_number(-0.0) gives a +0 high word")
    passed = passed + 1
  else
    print("  FAIL: from_number(-0.0) gives a +0 high word")
  end

  local decoder_errors = {
    { "le_bytes_to_u64 rejects offset 0", bit64.le_bytes_to_u64, "\1\2\3\4\5\6\7\8\9", 0, "Offset must be at least 1" },
    { "be_bytes_to_u64 rejects offset 0", bit64.be_bytes_to_u64, "\1\2\3\4\5\6\7\8\9", 0, "Offset must be at least 1" },
    {
      "le_bytes_to_u64 rejects a NaN offset",
      bit64.le_bytes_to_u64,
      "\1\2\3\4\5\6\7\8\9",
      0 / 0,
      "Offset must be at least 1",
    },
    {
      "be_bytes_to_u64 rejects a NaN offset",
      bit64.be_bytes_to_u64,
      "\1\2\3\4\5\6\7\8\9",
      0 / 0,
      "Offset must be at least 1",
    },
    {
      "le_bytes_to_u64 rejects a short buffer",
      bit64.le_bytes_to_u64,
      "\1\2\3\4\5\6\7",
      1,
      "Insufficient bytes for u64",
    },
    {
      "be_bytes_to_u64 rejects a short buffer",
      bit64.be_bytes_to_u64,
      "\1\2\3\4\5\6\7\8",
      2,
      "Insufficient bytes for u64",
    },
  }
  for _, test in ipairs(decoder_errors) do
    local test_name, fn, input, offset, message = test[1], test[2], test[3], test[4], test[5]
    total = total + 1
    local raised, err_text = pcall(fn, input, offset)
    if not raised and type(err_text) == "string" and string.find(err_text, message, 1, true) then
      print("  PASS: " .. test_name)
      passed = passed + 1
    else
      print("  FAIL: " .. test_name)
    end
  end

  print(string.format("\n64-bit operations: %d/%d tests passed\n", passed, total))
  return passed == total
end

return selftest
