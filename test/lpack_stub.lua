--- @diagnostic disable: duplicate-set-field
-- Installs string.pack/string.unpack in the shape Control4's LuaJIT ships (lpack):
-- single-letter codes with no size suffix, '<' accepted and ignored, and
-- unpack(data, fmt, pos) returning the next position before the values. Loaded
-- ahead of bitn so a byte helper that assumes the 5.3 dialect fails here rather
-- than on a controller.
local SIZE = { b = 1, B = 1, c = 1, h = 2, H = 2, i = 4, I = 4, l = 4, L = 4 }

local function pack_int(value, size)
  value = value % 2 ^ (8 * size)
  local out = {}
  for _ = 1, size do
    out[#out + 1] = string.char(value % 256)
    value = math.floor(value / 256)
  end
  return table.concat(out)
end

local function unpack_int(data, pos, size)
  local value = 0
  for i = 0, size - 1 do
    value = value + string.byte(data, pos + i) * 2 ^ (8 * i)
  end
  return pos + size, value
end

function string.pack(fmt, ...)
  local args, i, out = { ... }, 0, {}
  for c in fmt:gmatch(".") do
    if c == "<" or c == ">" or c == "=" then
      -- lpack: endian markers are accepted and ignored
    elseif SIZE[c] then
      i = i + 1
      out[#out + 1] = pack_int(args[i], SIZE[c])
    else
      error("lpack stub: unsupported code '" .. c .. "'")
    end
  end
  return table.concat(out)
end

function string.unpack(data, fmt, pos)
  pos = pos or 1
  local out = {}
  for c in fmt:gmatch(".") do
    if c == "<" or c == ">" or c == "=" then
      -- lpack: endian markers are accepted and ignored
    elseif SIZE[c] then
      local value
      pos, value = unpack_int(data, pos, SIZE[c])
      out[#out + 1] = value
    else
      error("lpack stub: unsupported code '" .. c .. "'")
    end
  end
  return pos, (table.unpack or unpack)(out)
end
