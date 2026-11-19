// host_harness_main.cpp
// Runs the MQL5 test harness (Tests/RiskManagement_M1_Tests.mq5) on the host,
// compiled as C++17 against mql5_shim.h. Host-simulated evidence only:
// it does not replace compiling and running the harness inside MetaTrader 5.
#include "mql5_shim.h"
#include "RiskManagement_M1_Tests.mq5"

int main()
{
   g_shim.echo = true;
   int init_result = OnInit();
   OnDeinit(REASON_PROGRAM);
   std::cout << "[HOST] harness OnInit returned " << init_result
             << ", ExpertRemove() calls=" << g_shim.expert_remove_calls << '\n';
   return (g_tests_failed == 0 && init_result == INIT_SUCCEEDED) ? 0 : 1;
}
