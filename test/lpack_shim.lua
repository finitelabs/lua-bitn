--- @module "test.lpack_shim"
--- Installs an lpack-shaped `string.pack`/`string.unpack`, the pair Control4's
--- DriverWorks ships under those two names, so the suite can prove that bitn
--- rejects the dialect and takes its manual byte path instead of calling it.
---
--- The shape and the two quiet behaviours below were measured on a controller:
---   * `pack(fmt, ...)` has no size-suffixed codes, so a digit is an unknown code
---   * `unpack(data, fmt, pos)` is argument-swapped, and returns position then value
---   * the format is read as a C string, so a NUL byte ends it
---   * a code with fewer bytes left than it needs stops the run without raising
---
--- The last two are why a Lua 5.3 shaped call is not simply an error here: the
--- payload lands where the format is expected, so `>I4` decodes of 0, 42 and 65535
--- all come back as the position 1, matching the controller.
---
--- Only the integer codes are modelled. Sweeping the first payload byte over 0-255
--- accepts 14 of them here against the controller's 22, and the two sets differ
--- both ways (`B` is accepted here and not there, `A a c d f n p z` there and not
--- here). Those bytes are reachable: the swapped signature is what puts the payload
--- in the format slot, so a little-endian u32 whose low byte is one of the eight is
--- quiet on a controller and raises here, about 3% of values. The divergence still
--- does not affect what this double is for, because `packs_like_lua53()` compares
--- returned values on every format the library emits including the offset case, so
--- it fails closed whether the dialect raises or answers quietly, and the suite
--- asserts `_compat.string_pack` came out nil, which neither behaviour perturbs.
local lpack_shim = {}

local SIZE = { b = 1, B = 1, h = 2, H = 2, i = 4, I = 4, l = 8, L = 8 }

--- @param fmt string
--- @return string codes Format up to the first NUL, which terminates it
local function codes(fmt)
  local stop = string.find(fmt, "\0", 1, true)
  return stop and string.sub(fmt, 1, stop - 1) or fmt
end

--- @param fmt string Format string, lpack dialect
--- @param ... integer Values to pack
--- @return string bytes
function lpack_shim.pack(fmt, ...)
  local args, taken, little, out = { ... }, 0, true, {}
  local format = codes(fmt)
  for i = 1, #format do
    local c = string.sub(format, i, i)
    if c == "<" or c == "=" then
      little = true
    elseif c == ">" then
      little = false
    elseif c ~= " " and c ~= "," then
      local size = SIZE[c]
      if not size then
        error("lpack shim: unsupported code '" .. c .. "'")
      end
      taken = taken + 1
      local v = args[taken] % (2 ^ (size * 8))
      local bytes = {}
      for b = 1, size do
        bytes[b] = string.char(math.floor(v / 2 ^ ((b - 1) * 8)) % 256)
      end
      if not little then
        local reversed = {}
        for b = 1, size do
          reversed[b] = bytes[size - b + 1]
        end
        bytes = reversed
      end
      out[#out + 1] = table.concat(bytes)
    end
  end
  return table.concat(out)
end

--- @param data string Binary data
--- @param fmt string Format string, lpack dialect
--- @param pos? integer Starting position (default: 1)
--- @return integer nextpos, integer ... Position first, then the values
function lpack_shim.unpack(data, fmt, pos)
  pos = pos or 1
  local little, out = true, {}
  local format = codes(fmt)
  for i = 1, #format do
    local c = string.sub(format, i, i)
    if c == "<" or c == "=" then
      little = true
    elseif c == ">" then
      little = false
    elseif c ~= " " and c ~= "," then
      local size = SIZE[c]
      if not size then
        error("lpack shim: unsupported code '" .. c .. "'")
      end
      if pos + size - 1 > #data then
        break
      end
      local v = 0
      for b = 0, size - 1 do
        local byte = string.byte(data, pos + b)
        v = v + byte * 2 ^ (little and (b * 8) or ((size - 1 - b) * 8))
      end
      out[#out + 1] = v
      pos = pos + size
    end
  end
  return pos, (unpack or table.unpack)(out)
end

--- Replace `string.pack`/`string.unpack` with the lpack-shaped pair. Must run
--- before the module under test is required, since the dialect is probed at load.
function lpack_shim.install()
  string.pack = lpack_shim.pack
  string.unpack = lpack_shim.unpack
end

return lpack_shim
