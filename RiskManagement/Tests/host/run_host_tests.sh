#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Host-simulated verification for EA Risk Management M1 (Linux / C++17).
#
# Compiles the MQL5 sources as C++ against mql5_shim.h and runs:
#   1. the MQL5 test harness   Tests/RiskManagement_M1_Tests.mq5
#   2. entry-point lifecycle tests on RiskManagement.mq5 (host_entrypoint_tests.cpp)
#   3. a documentation-only log transcript (host_log_sample.cpp)
#
# The original sources are never modified. A temporary copy receives only these
# mechanical transforms:
#   - '#property ...' lines removed (MQL5-only directive)
#   - 'm_source.' / 'm_logger.' -> '->' (MQL5 accesses object pointers with '.')
#
# Results are HOST-SIMULATED evidence only. They do not replace compiling with
# MetaEditor and running the harness inside MetaTrader 5.
# -----------------------------------------------------------------------------
set -euo pipefail

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${HOST_DIR}/../.." && pwd)"
BUILD_DIR="${BUILD_DIR:-${HOST_DIR}/build}"
RESULTS_DIR="${RESULTS_DIR:-${HOST_DIR}/results}"
CXX="${CXX:-g++}"
CXXFLAGS=(-std=c++17 -O0 -g -Wall -Wextra -Wno-unused-parameter)

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/src/Tests" "${RESULTS_DIR}"

cp "${PROJECT_DIR}/RiskManagement.mq5" "${BUILD_DIR}/src/"
cp -R "${PROJECT_DIR}/Include" "${BUILD_DIR}/src/"
cp "${PROJECT_DIR}/Tests/RiskManagement_M1_Tests.mq5" "${BUILD_DIR}/src/Tests/"

find "${BUILD_DIR}/src" -type f \( -name '*.mq5' -o -name '*.mqh' \) -print0 \
   | xargs -0 sed -i -E \
        -e '/^[[:space:]]*#property[[:space:]]/d' \
        -e 's/\bm_source\./m_source->/g' \
        -e 's/\bm_logger\./m_logger->/g'

{
   echo "date_utc: $(date -u '+%Y-%m-%d %H:%M:%S')"
   echo "compiler: $("${CXX}" --version | head -n 1)"
   echo "flags: ${CXXFLAGS[*]}"
} > "${RESULTS_DIR}/host_build_info.txt"

status=0

echo "== compile: harness =="
if ! "${CXX}" "${CXXFLAGS[@]}" -I "${HOST_DIR}" -I "${BUILD_DIR}/src/Tests" \
      -o "${BUILD_DIR}/rm_m1_harness" "${HOST_DIR}/host_harness_main.cpp" \
      2> "${RESULTS_DIR}/host_compile_harness.log"; then
   cat "${RESULTS_DIR}/host_compile_harness.log"
   exit 2
fi
echo "warnings: $(grep -c 'warning:' "${RESULTS_DIR}/host_compile_harness.log" || true)"

echo "== compile: entry point =="
if ! "${CXX}" "${CXXFLAGS[@]}" -I "${HOST_DIR}" -I "${BUILD_DIR}/src" \
      -o "${BUILD_DIR}/rm_m1_entrypoint" "${HOST_DIR}/host_entrypoint_tests.cpp" \
      2> "${RESULTS_DIR}/host_compile_entrypoint.log"; then
   cat "${RESULTS_DIR}/host_compile_entrypoint.log"
   exit 2
fi
echo "warnings: $(grep -c 'warning:' "${RESULTS_DIR}/host_compile_entrypoint.log" || true)"

echo "== compile: log sample (documentation only) =="
if ! "${CXX}" "${CXXFLAGS[@]}" -I "${HOST_DIR}" -I "${BUILD_DIR}/src" \
      -o "${BUILD_DIR}/rm_m1_log_sample" "${HOST_DIR}/host_log_sample.cpp" \
      2> "${RESULTS_DIR}/host_compile_log_sample.log"; then
   cat "${RESULTS_DIR}/host_compile_log_sample.log"
   exit 2
fi
"${BUILD_DIR}/rm_m1_log_sample" > "${RESULTS_DIR}/host_log_sample.txt" 2>&1 || status=1

echo "== run: harness =="
if ! "${BUILD_DIR}/rm_m1_harness" > "${RESULTS_DIR}/host_harness_output.txt" 2>&1; then
   status=1
fi
grep -E '^\[RM-TEST\] (PASS|FAIL|NOT RUN|SUMMARY|RESULT)|check failed' "${RESULTS_DIR}/host_harness_output.txt" | tail -n 60

echo "== run: entry point =="
if ! "${BUILD_DIR}/rm_m1_entrypoint" > "${RESULTS_DIR}/host_entrypoint_output.txt" 2>&1; then
   status=1
fi
cat "${RESULTS_DIR}/host_entrypoint_output.txt"

exit "${status}"
