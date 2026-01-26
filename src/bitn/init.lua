--- @module "bitn"
--- Pure Lua bitwise operations library.
--- This library provides standalone, version-agnostic implementations of
--- bitwise operations for 16-bit, 32-bit, and 64-bit integers. It works
--- across Lua 5.1, 5.2, 5.3, 5.4, and LuaJIT without depending on any
--- built-in bit libraries.
---
--- @usage
--- local bitn = require("bitn")
--- print(bitn.version())
---
--- -- 32-bit operations
--- local result = bitn.bit32.band(0xFF00, 0x0FF0)  -- 0x0F00
---
--- -- 64-bit operations (using {high, low} pairs)
--- local sum = bitn.bit64.add({0, 1}, {0, 2})  -- {0, 3}
---
--- -- 16-bit operations
--- local shifted = bitn.bit16.lshift(1, 8)  -- 256
---
--- @class bitn
local bitn = {
  --- @type bit16
  bit16 = require("bitn.bit16"),
  --- @type bit32
  bit32 = require("bitn.bit32"),
  --- @type bit64
  bit64 = require("bitn.bit64"),
}

--- Library version (injected at build time for releases).
local VERSION = "dev"

--- Get the library version string.
--- @return string version Version string (e.g., "v1.0.0" or "dev")
function bitn.version()
  return VERSION
end

return bitn
