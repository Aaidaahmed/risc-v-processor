#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/../.."

LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

iverilog -g2012 -I include -s cpu_tb \
  -o sim/cpu_test rtl/*.v tb/cpu_tb.v > "$LOG" 2>&1
vvp sim/cpu_test >> "$LOG" 2>&1

{
  printf 'RV32I-STYLE RISC-V PROCESSOR | RTL SIMULATION\n'
  printf '%s\n' '--------------------------------------------'
  grep -E '^(PC=|PASS:|Memory word|Cycles |Instructions |Loads |Stores |Branches |MAC[[:space:]])' "$LOG" \
    | tail -n 25
  printf '\n%s\n' 'LOAD/STORE TEST SUMMARY'
  grep -E '^PASS:' "$LOG"
} > docs/demo/simulation_summary.txt

cat docs/demo/simulation_summary.txt
