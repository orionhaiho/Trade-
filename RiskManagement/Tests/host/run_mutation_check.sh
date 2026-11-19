#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Mutation check for the host-simulated tests (EA Risk Management M1).
# Each mutation injects one deliberate defect into a TEMPORARY copy of the
# sources and re-runs the host tests. Every mutation must be detected (tests
# fail); a surviving mutation means the tests are too weak.
# The original sources are never modified.
# -----------------------------------------------------------------------------
set -uo pipefail

HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${HOST_DIR}/../.." && pwd)"
WORK_DIR="${WORK_DIR:-${HOST_DIR}/build_mutation}"
RESULTS_DIR="${RESULTS_DIR:-${HOST_DIR}/results}"
mkdir -p "${RESULTS_DIR}"
REPORT="${RESULTS_DIR}/host_mutation_check.txt"

# id | file (relative to project) | sed expression | description
MUTATIONS=(
"M01|Include/Validation/DataValidator.mqh|s/snapshot.margin<0.0/snapshot.margin<-1000000.0/|negative margin accepted"
"M02|Include/Validation/DataValidator.mqh|s/if\(MathIsValidNumber\(value\)\)/if(true)/|NaN/Inf accepted"
"M03|Include/Core/AccountEngine.mqh|s/snapshot.equity=equity;/snapshot.equity=balance+profit;/|equity derived from balance + profit"
"M04|Include/Core/AccountEngine.mqh|s/snapshot.free_margin=free_margin;/snapshot.free_margin=equity-margin;/|free margin derived"
"M05|Include/Core/AccountEngine.mqh|s/AccountSnapshotReset\(snapshot\);/\/\/ reset removed/|snapshot not reset before/after collection"
"M06|Include/Core/AccountEngine.mqh|s/if\(!connected \&\& m_require_connected_terminal\)/if(false)/|disconnect ignored"
"M07|Include/Core/AccountEngine.mqh|s/value=TimeTradeServer\(\);/value=TimeLocal();/|local time used as server time"
"M08|Include/Core/CoreEngine.mqh|s/if\(m_in_failure \&\& key==m_failure_key\)/if(false)/|repeated failures logged every cycle"
"M09|Include/Core/CoreEngine.mqh|s/if\(m_identity_changed\)/if(false)/|identity change not latched"
"M10|Include/Core/CoreEngine.mqh|s/snapshot.data_status=DATA_STATUS_STALE;/snapshot.data_status=DATA_STATUS_VALID;/|historical copy presented as VALID"
"M11|Include/Core/CoreEngine.mqh|s/m_has_last_success \&\& m_current_status==DATA_STATUS_VALID/m_has_last_success/|GetLatestSnapshot true for stale data"
"M12|Include/Core/CoreEngine.mqh|s/if\(!m_account_engine.IsTerminalConnected\(\)\)/if(false)/|disconnected data published as VALID"
"M13|Include/Utils/Logger.mqh|s/if\(level==RM_LOG_ERROR\)/if(false)/|ERROR suppressed when logging is disabled"
"M14|RiskManagement.mq5|s/if\(g_timer_created\)/if(true)/|EventKillTimer called without a timer"
"M15|RiskManagement.mq5|s/return\(INIT_PARAMETERS_INCORRECT\);/return(INIT_SUCCEEDED);/|invalid refresh interval accepted"
"M16|Include/Core/CoreEngine.mqh|s/HandleFailure\(DATA_STATUS_INVALID,/HandleSuccess(snapshot);if(false)HandleFailure(DATA_STATUS_INVALID,/|invalid data published"
"M17|Include/Validation/DataValidator.mqh|s/if\(snapshot.login<=0\)/if(snapshot.login<0)/|login 0 accepted"
"M18|RiskManagement.mq5|/if\(!EventSetTimer/,/return\(INIT_FAILED\)/ s/g_core.Shutdown\(\);/\/\/ shutdown removed/|core not shut down after timer failure"
"M19|RiskManagement.mq5|/if\(!EventSetTimer/,/return\(INIT_FAILED\)/ s/return\(INIT_FAILED\);/return(INIT_SUCCEEDED);/|timer failure reported as success"
)

survivors=0
: > "${REPORT}"
echo "mutation check $(date -u '+%Y-%m-%d %H:%M:%S') UTC" >> "${REPORT}"
for entry in "${MUTATIONS[@]}"; do
   IFS='|' read -r id file expr description <<< "${entry}"
   rm -rf "${WORK_DIR}/project"
   mkdir -p "${WORK_DIR}/project"
   cp -R "${PROJECT_DIR}/RiskManagement.mq5" "${PROJECT_DIR}/Include" "${PROJECT_DIR}/Tests" "${WORK_DIR}/project/"
   before="$(md5sum "${WORK_DIR}/project/${file}" | cut -d' ' -f1)"
   sed -i -E "${expr}" "${WORK_DIR}/project/${file}"
   after="$(md5sum "${WORK_DIR}/project/${file}" | cut -d' ' -f1)"
   if [ "${before}" = "${after}" ]; then
      line="${id} NOT APPLIED (pattern not found)  - ${description}"
      survivors=$((survivors+1))
   elif BUILD_DIR="${WORK_DIR}/build" RESULTS_DIR="${WORK_DIR}/results" \
        bash "${WORK_DIR}/project/Tests/host/run_host_tests.sh" > "${WORK_DIR}/run.log" 2>&1; then
      line="${id} SURVIVED (tests still pass)      - ${description}"
      survivors=$((survivors+1))
   else
      failed="$(grep -hE '^\[(RM-TEST|HOST-E)\] FAIL' "${WORK_DIR}/results/"host_*_output.txt 2>/dev/null | sed -E 's/^\[(RM-TEST|HOST-E)\] FAIL ([A-Z0-9]+).*/\2/' | sort -u | tr '\n' ' ')"
      if grep -q 'error:' "${WORK_DIR}/results/"host_compile_*.log 2>/dev/null; then failed="(compile error) ${failed}"; fi
      line="${id} KILLED by: ${failed} - ${description}"
   fi
   echo "${line}" | tee -a "${REPORT}"
done
echo "surviving or unapplied mutations: ${survivors}" | tee -a "${REPORT}"
rm -rf "${WORK_DIR}"
[ "${survivors}" -eq 0 ]
