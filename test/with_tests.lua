--- Main chunk of build/bitn-tests.lua, the with-tests build: the library, as `require("bitn")`
--- returns it, plus `selftest()` and `benchmark()` over every suite in test/ and bench/.

--- @class bitn.with_tests: bitn
local bitn = require("bitn")

local SELFTESTS = {
  require("test_bit16"),
  require("test_bit32"),
  require("test_bit64"),
}

local BENCHMARKS = {
  require("bench_bit16"),
  require("bench_bit32"),
  require("bench_bit64"),
}

--- Run every test suite.
--- @return boolean result True if all tests pass, false otherwise
function bitn.selftest()
  local ok = true
  for _, selftest in ipairs(SELFTESTS) do
    ok = selftest() and ok
  end
  return ok
end

--- Run every benchmark.
function bitn.benchmark()
  for _, benchmark in ipairs(BENCHMARKS) do
    benchmark()
  end
end

return bitn
