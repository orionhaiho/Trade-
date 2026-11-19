// host_log_sample.cpp
// Prints a host-simulated Experts-tab transcript of RiskManagement.mq5 for
// typical situations (documentation only; values come from mql5_shim.h).
// The timestamps are simulated: one OnTimer call = one simulated second.
#include "mql5_shim.h"
#include "RiskManagement.mq5"

#include <cmath>

static void Timers(int count)
{
   for (int i = 0; i < count; i++)
   {
      g_shim.local_time++;
      g_shim.server_time++;
      OnTimer();
   }
}

int main()
{
   g_shim.echo = true;
   std::cout << "--- A: EA starts while the terminal is not yet connected (login still 0) ---\n";
   g_shim.connected = false;
   g_shim.login = 0;
   OnInit();
   Timers(3);
   g_shim.connected = true;
   g_shim.login = 12345678;
   Timers(2);
   std::cout << "--- B: invalid data (NaN equity) during 5 cycles, then recovery ---\n";
   g_shim.equity = std::nan("");
   Timers(5);
   g_shim.equity = 1013.75;
   Timers(1);
   std::cout << "--- C: network drop during 4 cycles ---\n";
   g_shim.connected = false;
   Timers(4);
   g_shim.connected = true;
   Timers(1);
   std::cout << "--- D: account identity changes without an EA reload ---\n";
   g_shim.login = 87654321;
   Timers(3);
   OnDeinit(REASON_REMOVE);
   std::cout << "--- E: InpEnableDebugLogging=true (one detail line per successful cycle) ---\n";
   InpEnableDebugLogging = true;
   g_shim.login = 12345678;
   OnInit();
   Timers(1);
   OnDeinit(REASON_REMOVE);
   std::cout << "--- F: invalid input InpAccountRefreshSeconds=0 ---\n";
   InpEnableDebugLogging = false;
   InpAccountRefreshSeconds = 0;
   int result = OnInit();
   std::cout << "OnInit returned " << result << " (INIT_PARAMETERS_INCORRECT)\n";
   OnDeinit(REASON_INITFAILED);
   return 0;
}
