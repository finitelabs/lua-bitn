--- Tests for bitn.bit32: `make test` runs them, and so does the with-tests build's selftest().

local bit32 = require("bitn.bit32")
local _compat = require("bitn._compat")
local string_char = string.char
local string_byte = string.byte

local impl_name = _compat.impl_name

-- Compatibility for unpack
local unpack_fn = unpack or table.unpack

--- Run comprehensive self-test with test vectors.
--- @return boolean result True if all tests pass, false otherwise
local function selftest()
  local function fmt32(v)
    return v < 0 and tostring(v) or string.format("0x%08X", v)
  end

  print("Running 32-bit operations test vectors...")
  print(string.format("  Using: %s", impl_name()))
  local passed = 0
  local total = 0

  local test_vectors = {
    -- mask tests
    { name = "mask(0)", fn = bit32.mask, inputs = { 0 }, expected = 0 },
    { name = "mask(1)", fn = bit32.mask, inputs = { 1 }, expected = 1 },
    { name = "mask(0xFFFFFFFF)", fn = bit32.mask, inputs = { 0xFFFFFFFF }, expected = 0xFFFFFFFF },
    { name = "mask(0x100000000)", fn = bit32.mask, inputs = { 0x100000000 }, expected = 0 },
    { name = "mask(0x100000001)", fn = bit32.mask, inputs = { 0x100000001 }, expected = 1 },
    { name = "mask(-1)", fn = bit32.mask, inputs = { -1 }, expected = 0xFFFFFFFF },
    { name = "mask(-256)", fn = bit32.mask, inputs = { -256 }, expected = 0xFFFFFF00 },

    -- to_unsigned tests
    { name = "to_unsigned(0)", fn = bit32.to_unsigned, inputs = { 0 }, expected = 0 },
    { name = "to_unsigned(1)", fn = bit32.to_unsigned, inputs = { 1 }, expected = 1 },
    { name = "to_unsigned(0x7FFFFFFF)", fn = bit32.to_unsigned, inputs = { 0x7FFFFFFF }, expected = 0x7FFFFFFF },
    { name = "to_unsigned(-1)", fn = bit32.to_unsigned, inputs = { -1 }, expected = 0xFFFFFFFF },
    { name = "to_unsigned(-2147483648)", fn = bit32.to_unsigned, inputs = { -2147483648 }, expected = 0x80000000 },
    { name = "to_unsigned(-2147483647)", fn = bit32.to_unsigned, inputs = { -2147483647 }, expected = 0x80000001 },

    -- to_signed tests
    { name = "to_signed(0)", fn = bit32.to_signed, inputs = { 0 }, expected = 0 },
    { name = "to_signed(1)", fn = bit32.to_signed, inputs = { 1 }, expected = 1 },
    { name = "to_signed(0x7FFFFFFF)", fn = bit32.to_signed, inputs = { 0x7FFFFFFF }, expected = 0x7FFFFFFF },
    { name = "to_signed(0x80000000)", fn = bit32.to_signed, inputs = { 0x80000000 }, expected = -2147483648 },
    { name = "to_signed(0x80000001)", fn = bit32.to_signed, inputs = { 0x80000001 }, expected = -2147483647 },
    { name = "to_signed(0xFFFFFFFF)", fn = bit32.to_signed, inputs = { 0xFFFFFFFF }, expected = -1 },
    { name = "to_signed(-1)", fn = bit32.to_signed, inputs = { -1 }, expected = -1 },

    -- band tests
    { name = "band(0xFF00FF00, 0x00FF00FF)", fn = bit32.band, inputs = { 0xFF00FF00, 0x00FF00FF }, expected = 0 },
    {
      name = "band(0xFFFFFFFF, 0xFFFFFFFF)",
      fn = bit32.band,
      inputs = { 0xFFFFFFFF, 0xFFFFFFFF },
      expected = 0xFFFFFFFF,
    },
    { name = "band(0xAAAAAAAA, 0x55555555)", fn = bit32.band, inputs = { 0xAAAAAAAA, 0x55555555 }, expected = 0 },
    {
      name = "band(0xF0F0F0F0, 0xFF00FF00)",
      fn = bit32.band,
      inputs = { 0xF0F0F0F0, 0xFF00FF00 },
      expected = 0xF000F000,
    },
    { name = "band(0, 0xFFFFFFFF)", fn = bit32.band, inputs = { 0, 0xFFFFFFFF }, expected = 0 },

    -- bor tests
    {
      name = "bor(0xFF00FF00, 0x00FF00FF)",
      fn = bit32.bor,
      inputs = { 0xFF00FF00, 0x00FF00FF },
      expected = 0xFFFFFFFF,
    },
    { name = "bor(0, 0)", fn = bit32.bor, inputs = { 0, 0 }, expected = 0 },
    {
      name = "bor(0xAAAAAAAA, 0x55555555)",
      fn = bit32.bor,
      inputs = { 0xAAAAAAAA, 0x55555555 },
      expected = 0xFFFFFFFF,
    },
    {
      name = "bor(0xF0F0F0F0, 0x0F0F0F0F)",
      fn = bit32.bor,
      inputs = { 0xF0F0F0F0, 0x0F0F0F0F },
      expected = 0xFFFFFFFF,
    },

    -- bxor tests
    {
      name = "bxor(0xFF00FF00, 0x00FF00FF)",
      fn = bit32.bxor,
      inputs = { 0xFF00FF00, 0x00FF00FF },
      expected = 0xFFFFFFFF,
    },
    { name = "bxor(0xFFFFFFFF, 0xFFFFFFFF)", fn = bit32.bxor, inputs = { 0xFFFFFFFF, 0xFFFFFFFF }, expected = 0 },
    {
      name = "bxor(0xAAAAAAAA, 0x55555555)",
      fn = bit32.bxor,
      inputs = { 0xAAAAAAAA, 0x55555555 },
      expected = 0xFFFFFFFF,
    },
    { name = "bxor(0x12345678, 0x12345678)", fn = bit32.bxor, inputs = { 0x12345678, 0x12345678 }, expected = 0 },

    -- bnot tests
    { name = "bnot(0)", fn = bit32.bnot, inputs = { 0 }, expected = 0xFFFFFFFF },
    { name = "bnot(0xFFFFFFFF)", fn = bit32.bnot, inputs = { 0xFFFFFFFF }, expected = 0 },
    { name = "bnot(0xAAAAAAAA)", fn = bit32.bnot, inputs = { 0xAAAAAAAA }, expected = 0x55555555 },
    { name = "bnot(0x12345678)", fn = bit32.bnot, inputs = { 0x12345678 }, expected = 0xEDCBA987 },

    -- lshift tests
    { name = "lshift(1, 0)", fn = bit32.lshift, inputs = { 1, 0 }, expected = 1 },
    { name = "lshift(1, 1)", fn = bit32.lshift, inputs = { 1, 1 }, expected = 2 },
    { name = "lshift(1, 31)", fn = bit32.lshift, inputs = { 1, 31 }, expected = 0x80000000 },
    { name = "lshift(1, 32)", fn = bit32.lshift, inputs = { 1, 32 }, expected = 0 },
    { name = "lshift(0xFF, 8)", fn = bit32.lshift, inputs = { 0xFF, 8 }, expected = 0xFF00 },
    { name = "lshift(0x80000000, 1)", fn = bit32.lshift, inputs = { 0x80000000, 1 }, expected = 0 },

    -- rshift tests
    { name = "rshift(1, 0)", fn = bit32.rshift, inputs = { 1, 0 }, expected = 1 },
    { name = "rshift(2, 1)", fn = bit32.rshift, inputs = { 2, 1 }, expected = 1 },
    { name = "rshift(0x80000000, 31)", fn = bit32.rshift, inputs = { 0x80000000, 31 }, expected = 1 },
    { name = "rshift(0x80000000, 32)", fn = bit32.rshift, inputs = { 0x80000000, 32 }, expected = 0 },
    { name = "rshift(0xFF00, 8)", fn = bit32.rshift, inputs = { 0xFF00, 8 }, expected = 0xFF },
    { name = "rshift(0xFFFFFFFF, 16)", fn = bit32.rshift, inputs = { 0xFFFFFFFF, 16 }, expected = 0xFFFF },

    -- arshift tests (arithmetic shift - sign extending)
    { name = "arshift(0x80000000, 1)", fn = bit32.arshift, inputs = { 0x80000000, 1 }, expected = 0xC0000000 },
    { name = "arshift(0x80000000, 31)", fn = bit32.arshift, inputs = { 0x80000000, 31 }, expected = 0xFFFFFFFF },
    { name = "arshift(0x80000000, 32)", fn = bit32.arshift, inputs = { 0x80000000, 32 }, expected = 0xFFFFFFFF },
    { name = "arshift(0x7FFFFFFF, 1)", fn = bit32.arshift, inputs = { 0x7FFFFFFF, 1 }, expected = 0x3FFFFFFF },
    { name = "arshift(0x7FFFFFFF, 31)", fn = bit32.arshift, inputs = { 0x7FFFFFFF, 31 }, expected = 0 },
    { name = "arshift(0xFF000000, 8)", fn = bit32.arshift, inputs = { 0xFF000000, 8 }, expected = 0xFFFF0000 },
    { name = "arshift(0x0F000000, 8)", fn = bit32.arshift, inputs = { 0x0F000000, 8 }, expected = 0x000F0000 },

    -- rol tests
    { name = "rol(1, 0)", fn = bit32.rol, inputs = { 1, 0 }, expected = 1 },
    { name = "rol(1, 1)", fn = bit32.rol, inputs = { 1, 1 }, expected = 2 },
    { name = "rol(0x80000000, 1)", fn = bit32.rol, inputs = { 0x80000000, 1 }, expected = 1 },
    { name = "rol(1, 32)", fn = bit32.rol, inputs = { 1, 32 }, expected = 1 },
    { name = "rol(0x12345678, 8)", fn = bit32.rol, inputs = { 0x12345678, 8 }, expected = 0x34567812 },
    { name = "rol(0x12345678, 16)", fn = bit32.rol, inputs = { 0x12345678, 16 }, expected = 0x56781234 },

    -- ror tests
    { name = "ror(1, 0)", fn = bit32.ror, inputs = { 1, 0 }, expected = 1 },
    { name = "ror(1, 1)", fn = bit32.ror, inputs = { 1, 1 }, expected = 0x80000000 },
    { name = "ror(2, 1)", fn = bit32.ror, inputs = { 2, 1 }, expected = 1 },
    { name = "ror(1, 32)", fn = bit32.ror, inputs = { 1, 32 }, expected = 1 },
    { name = "ror(0x12345678, 8)", fn = bit32.ror, inputs = { 0x12345678, 8 }, expected = 0x78123456 },
    { name = "ror(0x12345678, 16)", fn = bit32.ror, inputs = { 0x12345678, 16 }, expected = 0x56781234 },

    -- add tests
    { name = "add(0, 0)", fn = bit32.add, inputs = { 0, 0 }, expected = 0 },
    { name = "add(1, 1)", fn = bit32.add, inputs = { 1, 1 }, expected = 2 },
    { name = "add(0xFFFFFFFF, 1)", fn = bit32.add, inputs = { 0xFFFFFFFF, 1 }, expected = 0 },
    { name = "add(0xFFFFFFFF, 2)", fn = bit32.add, inputs = { 0xFFFFFFFF, 2 }, expected = 1 },
    { name = "add(0x80000000, 0x80000000)", fn = bit32.add, inputs = { 0x80000000, 0x80000000 }, expected = 0 },

    -- u32_to_be_bytes tests
    {
      name = "u32_to_be_bytes(0)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 0 },
      expected = string_char(0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u32_to_be_bytes(1)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 1 },
      expected = string_char(0x00, 0x00, 0x00, 0x01),
    },
    {
      name = "u32_to_be_bytes(0x12345678)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 0x12345678 },
      expected = string_char(0x12, 0x34, 0x56, 0x78),
    },
    {
      name = "u32_to_be_bytes(0xFFFFFFFF)",
      fn = bit32.u32_to_be_bytes,
      inputs = { 0xFFFFFFFF },
      expected = string_char(0xFF, 0xFF, 0xFF, 0xFF),
    },

    -- u32_to_le_bytes tests
    {
      name = "u32_to_le_bytes(0)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 0 },
      expected = string_char(0x00, 0x00, 0x00, 0x00),
    },
    {
      name = "u32_to_le_bytes(1)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 1 },
      expected = string_char(0x01, 0x00, 0x00, 0x00),
    },
    {
      name = "u32_to_le_bytes(0x12345678)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 0x12345678 },
      expected = string_char(0x78, 0x56, 0x34, 0x12),
    },
    {
      name = "u32_to_le_bytes(0xFFFFFFFF)",
      fn = bit32.u32_to_le_bytes,
      inputs = { 0xFFFFFFFF },
      expected = string_char(0xFF, 0xFF, 0xFF, 0xFF),
    },

    -- be_bytes_to_u32 tests
    {
      name = "be_bytes_to_u32(0x00000000)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string_char(0x00, 0x00, 0x00, 0x00) },
      expected = 0,
    },
    {
      name = "be_bytes_to_u32(0x00000001)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string_char(0x00, 0x00, 0x00, 0x01) },
      expected = 1,
    },
    {
      name = "be_bytes_to_u32(0x12345678)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string_char(0x12, 0x34, 0x56, 0x78) },
      expected = 0x12345678,
    },
    {
      name = "be_bytes_to_u32(0xFFFFFFFF)",
      fn = bit32.be_bytes_to_u32,
      inputs = { string_char(0xFF, 0xFF, 0xFF, 0xFF) },
      expected = 0xFFFFFFFF,
    },

    -- le_bytes_to_u32 tests
    {
      name = "le_bytes_to_u32(0x00000000)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string_char(0x00, 0x00, 0x00, 0x00) },
      expected = 0,
    },
    {
      name = "le_bytes_to_u32(0x00000001)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string_char(0x01, 0x00, 0x00, 0x00) },
      expected = 1,
    },
    {
      name = "le_bytes_to_u32(0x12345678)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string_char(0x78, 0x56, 0x34, 0x12) },
      expected = 0x12345678,
    },
    {
      name = "le_bytes_to_u32(0xFFFFFFFF)",
      fn = bit32.le_bytes_to_u32,
      inputs = { string_char(0xFF, 0xFF, 0xFF, 0xFF) },
      expected = 0xFFFFFFFF,
    },
  }

  for _, test in ipairs(test_vectors) do
    total = total + 1
    local result = test.fn(unpack_fn(test.inputs))
    if result == test.expected then
      print("  PASS: " .. test.name)
      passed = passed + 1
    else
      print("  FAIL: " .. test.name)
      if type(test.expected) == "string" then
        local exp_hex, got_hex = "", ""
        for i = 1, #test.expected do
          exp_hex = exp_hex .. string.format("%02X", string_byte(test.expected, i))
        end
        for i = 1, #result do
          got_hex = got_hex .. string.format("%02X", string_byte(result, i))
        end
        print("    Expected: " .. exp_hex)
        print("    Got:      " .. got_hex)
      else
        print("    Expected: " .. fmt32(test.expected))
        print("    Got:      " .. fmt32(result))
      end
    end
  end

  -- Test raw_* operations
  print("\n  Testing raw_* operations...")

  local raw_tests = {
    -- Core bitwise (test high-bit cases where sign matters)
    {
      name = "raw_band(0xFFFFFFFF, 0x80000000)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_band(0xFFFFFFFF, 0x80000000))
      end,
      expected = bit32.band(0xFFFFFFFF, 0x80000000),
    },
    {
      name = "raw_bor(0x80000000, 0x00000001)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_bor(0x80000000, 0x00000001))
      end,
      expected = bit32.bor(0x80000000, 0x00000001),
    },
    {
      name = "raw_bxor(0xAAAAAAAA, 0x55555555)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_bxor(0xAAAAAAAA, 0x55555555))
      end,
      expected = bit32.bxor(0xAAAAAAAA, 0x55555555),
    },
    {
      name = "raw_bnot(0)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_bnot(0))
      end,
      expected = bit32.bnot(0),
    },
    {
      name = "raw_bnot(0x80000000)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_bnot(0x80000000))
      end,
      expected = bit32.bnot(0x80000000),
    },

    -- Shifts
    {
      name = "raw_lshift(1, 31)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_lshift(1, 31))
      end,
      expected = bit32.lshift(1, 31),
    },
    {
      name = "raw_rshift(0x80000000, 1)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_rshift(0x80000000, 1))
      end,
      expected = bit32.rshift(0x80000000, 1),
    },
    {
      name = "raw_arshift(0x80000000, 1)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_arshift(0x80000000, 1))
      end,
      expected = bit32.arshift(0x80000000, 1),
    },

    -- Shift masking (ensure 32-bit semantics on all platforms)
    -- Note: n >= 32 behavior is platform-specific for raw shifts; callers should use n in 0-31
    {
      name = "raw_lshift(0x12345678, 16) masks to 32 bits",
      fn = function()
        return bit32.to_unsigned(bit32.raw_lshift(0x12345678, 16))
      end,
      expected = 0x56780000,
    },
    {
      name = "raw_rshift(0xFFFFFFFF, 16) masks to 32 bits",
      fn = function()
        return bit32.to_unsigned(bit32.raw_rshift(0xFFFFFFFF, 16))
      end,
      expected = 0x0000FFFF,
    },

    -- Addition overflow
    {
      name = "raw_add(0xFFFFFFFF, 1)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_add(0xFFFFFFFF, 1))
      end,
      expected = bit32.add(0xFFFFFFFF, 1),
    },
    {
      name = "raw_add(0x80000000, 0x80000000)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_add(0x80000000, 0x80000000))
      end,
      expected = bit32.add(0x80000000, 0x80000000),
    },
  }

  for _, test in ipairs(raw_tests) do
    total = total + 1
    local result = test.fn()
    if result == test.expected then
      print("  PASS: " .. test.name)
      passed = passed + 1
    else
      print("  FAIL: " .. test.name)
      print(string.format("    Expected: 0x%08X", test.expected))
      print(string.format("    Got:      0x%08X", result))
    end
  end

  -- Test raw_rol/raw_ror (always available - falls back to computed if no native)
  print("\n  Testing raw_rol/raw_ror...")
  local rol_ror_tests = {
    {
      name = "raw_rol(0x80000000, 1)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_rol(0x80000000, 1))
      end,
      expected = bit32.rol(0x80000000, 1),
    },
    {
      name = "raw_rol(0x12345678, 8)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_rol(0x12345678, 8))
      end,
      expected = bit32.rol(0x12345678, 8),
    },
    {
      name = "raw_ror(1, 1)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_ror(1, 1))
      end,
      expected = bit32.ror(1, 1),
    },
    {
      name = "raw_ror(0x12345678, 8)",
      fn = function()
        return bit32.to_unsigned(bit32.raw_ror(0x12345678, 8))
      end,
      expected = bit32.ror(0x12345678, 8),
    },
  }

  for _, test in ipairs(rol_ror_tests) do
    total = total + 1
    local result = test.fn()
    if result == test.expected then
      print("  PASS: " .. test.name)
      passed = passed + 1
    else
      print("  FAIL: " .. test.name)
      print(string.format("    Expected: 0x%08X", test.expected))
      print(string.format("    Got:      0x%08X", result))
    end
  end

  -- Test zero-overhead on LuaJIT (identity check)
  if _compat.is_luajit then
    print("\n  Testing zero-overhead (LuaJIT function identity)...")
    local bit = require("bit")

    local identity_tests = {
      { name = "raw_band == bit.band", got = bit32.raw_band, expected = bit.band },
      { name = "raw_bor == bit.bor", got = bit32.raw_bor, expected = bit.bor },
      { name = "raw_bxor == bit.bxor", got = bit32.raw_bxor, expected = bit.bxor },
      { name = "raw_bnot == bit.bnot", got = bit32.raw_bnot, expected = bit.bnot },
      { name = "raw_lshift == bit.lshift", got = bit32.raw_lshift, expected = bit.lshift },
      { name = "raw_rshift == bit.rshift", got = bit32.raw_rshift, expected = bit.rshift },
      { name = "raw_arshift == bit.arshift", got = bit32.raw_arshift, expected = bit.arshift },
      { name = "raw_rol == bit.rol", got = bit32.raw_rol, expected = bit.rol },
      { name = "raw_ror == bit.ror", got = bit32.raw_ror, expected = bit.ror },
    }

    for _, test in ipairs(identity_tests) do
      total = total + 1
      if rawequal(test.got, test.expected) then
        print("  PASS: " .. test.name)
        passed = passed + 1
      else
        print("  FAIL: " .. test.name .. " (not identical function reference)")
      end
    end
  end

  total = total + 1
  local mask_failures = {}
  for k = 1, 32 do
    if bit32.band(0xDEADBEEF, 2 ^ k - 1) ~= 0xDEADBEEF % 2 ^ k then
      mask_failures[#mask_failures + 1] = k
    end
  end
  if #mask_failures == 0 then
    print("  PASS: band against every low-bit mask width")
    passed = passed + 1
  else
    print("  FAIL: band against every low-bit mask width: " .. table.concat(mask_failures, ", "))
  end

  local decoder_errors = {
    { "le_bytes_to_u32 rejects offset 0", bit32.le_bytes_to_u32, "\1\2\3\4\5", 0, "Offset must be at least 1" },
    { "be_bytes_to_u32 rejects offset 0", bit32.be_bytes_to_u32, "\1\2\3\4\5", 0, "Offset must be at least 1" },
    { "le_bytes_to_u32 rejects a NaN offset", bit32.le_bytes_to_u32, "\1\2\3\4\5", 0 / 0, "Offset must be at least 1" },
    { "be_bytes_to_u32 rejects a NaN offset", bit32.be_bytes_to_u32, "\1\2\3\4\5", 0 / 0, "Offset must be at least 1" },
    { "le_bytes_to_u32 rejects a short buffer", bit32.le_bytes_to_u32, "\1\2\3", 1, "Insufficient bytes for u32" },
    { "be_bytes_to_u32 rejects a short buffer", bit32.be_bytes_to_u32, "\1\2\3\4", 2, "Insufficient bytes for u32" },
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

  print(string.format("\n32-bit operations: %d/%d tests passed\n", passed, total))
  return passed == total
end

return selftest
