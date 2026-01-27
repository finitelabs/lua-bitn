#!/bin/bash

# Lua bitN Library Benchmark Runner
# Runs performance benchmarks for bit operation modules
#
# Usage: ./run_benchmarks.sh [module_names...]
#
# Examples:
#   ./run_benchmarks.sh                   # Run all benchmarks
#   ./run_benchmarks.sh bit32 bit64       # Run only bit32 and bit64 benchmarks
#
# Available modules: bit16, bit32, bit64

set -e  # Exit on any error

echo "============================================="
echo "⚡ Lua bitN Library - Benchmark Runner"
echo "============================================="
echo

# Colors for output
green='\033[0;32m'
red='\033[0;31m'
blue='\033[0;34m'
nc='\033[0m' # No Color

# Track overall results
completed_modules=()
failed_modules=()

lua_binary="${LUA_BINARY:-luajit}"  # Use luajit by default, can be overridden

# Check if the lua binary is available
if ! command -v "$lua_binary" &> /dev/null; then
    echo -e "${red}❌ Error: '$lua_binary' command not found.${nc}"
    exit 1
fi
echo "$($lua_binary -v)"
echo

# Get script directory
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Add repository root to Lua's package path
lua_path="$script_dir/?.lua;$script_dir/?/init.lua;$script_dir/src/?.lua;$script_dir/src/?/init.lua;$LUA_PATH"

# Parse command line arguments to determine which modules to run
default_modules=("bit16" "bit32" "bit64")
all_modules=("bit16" "bit32" "bit64")
modules_to_run=("$@")

# Validate modules if specified
if [ ${#modules_to_run[@]} -gt 0 ] && [ "${modules_to_run[0]}" != "all" ]; then
    for module in "${modules_to_run[@]}"; do
        valid=0
        for valid_module in "${all_modules[@]}"; do
            if [ "$module" = "$valid_module" ]; then
                valid=1
                break
            fi
        done
        if [ $valid -eq 0 ]; then
            echo -e "${red}❌ Error: Unknown module '$module' or benchmark not implemented${nc}"
            echo "Available modules: ${all_modules[*]}"
            exit 1
        fi
    done
fi

if [ ${#modules_to_run[@]} -eq 0 ]; then
    # No arguments provided, run all benchmarks
    modules_to_run=("${default_modules[@]}")
    echo "Running default benchmarks: ${modules_to_run[*]}"
elif [ "${modules_to_run[0]}" = "all" ]; then
    modules_to_run=("${all_modules[@]}")
    echo "Running all benchmarks: ${modules_to_run[*]}"
else
    echo "Running specified benchmarks: ${modules_to_run[*]}"
fi
echo

# Function to check if a module should be run
should_run_module() {
    local module_key="$1"
    for module in "${modules_to_run[@]}"; do
        if [ "$module" = "$module_key" ]; then
            return 0
        fi
    done
    return 1
}

# Function to run a benchmark and capture result
run_benchmark() {
    local module_name="$1"
    local module_key="$2"
    local lua_command="$3"

    if ! should_run_module "$module_key"; then
        return
    fi

    echo "---------------------------------------------"
    echo -e "${blue}Benchmarking $module_name...${nc}"
    echo "---------------------------------------------"

    if LUA_PATH="$lua_path" "$lua_binary" -e "$lua_command" 2>&1; then
        echo -e "\n${green}✅ $module_name: BENCHMARK COMPLETED${nc}"
        completed_modules+=("$module_name")
    else
        echo -e "\n${red}❌ $module_name: BENCHMARK FAILED${nc}"
        failed_modules+=("$module_name")
    fi

    echo
}

run_module_benchmark() {
  local module_name="$1"
  local module_key="$2"
  local lua_module="$3"
  run_benchmark "$module_name" "$module_key" "
    require('$lua_module').benchmark()
  "
}

# Run benchmarks
run_module_benchmark "16-bit Operations" "bit16" "bitn.bit16"
run_module_benchmark "32-bit Operations" "bit32" "bitn.bit32"
run_module_benchmark "64-bit Operations" "bit64" "bitn.bit64"

completed_count=${#completed_modules[@]}
failed_count=${#failed_modules[@]}
total_count=$((completed_count + failed_count))

# If only one module is run, no need to summarize
if [ $total_count -eq 1 ]; then
    exit 0
fi

# Summary
echo "============================================="
echo "📊 BENCHMARK SUMMARY"
echo "============================================="

if [ ${#failed_modules[@]} -eq 0 ]; then
    echo -e "${green}🎉 ALL BENCHMARKS COMPLETED: $completed_count/$total_count${nc}"
    echo
    echo "Completed benchmarks:"
    for module in "${completed_modules[@]}"; do
        echo "• $module: ✅ COMPLETE"
    done
else
    echo -e "${red}⚠️  SOME BENCHMARKS FAILED: $failed_count/$total_count${nc}"
    echo
    echo "Failed benchmarks:"
    for module in "${failed_modules[@]}"; do
        echo "• $module: ❌ FAILED"
    done
    exit 1
fi
