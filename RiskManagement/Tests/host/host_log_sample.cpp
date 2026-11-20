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

   std::cout << "\n=== G: Telegram messages (text of each sendMessage request, JSON unescaped) ===\n";
   g_shim = ShimTerminalState();
   g_shim.echo = false;
   InpAccountRefreshSeconds = 1;
   InpTelegramEnable = true;
   InpTelegramBotToken = "123456789:TESTtokenTESTtokenTESTtoken_-0123";
   InpTelegramChatId = "123456789";
   InpTelegramSummaryMinutes = 60;
   OnInit();
   Timers(1);
   g_shim.connected = false;
   Timers(1);
   g_shim.connected = true;
   Timers(95);
   g_shim.margin = -1.0;
   Timers(1);
   g_shim.margin = 50.0;
   Timers(1);
   g_shim.local_time += 3600;
   Timers(1);
   g_shim.login = 87654321;
   Timers(1);
   OnDeinit(REASON_REMOVE);
   for (const ShimWebRequestRecord &request : g_shim.web_requests)
   {
      std::string body = request.body;
      std::size_t start = body.find("\"text\":\"") + 8;
      std::size_t end = body.find("\",\"disable_web_page_preview\"");
      std::string text = body.substr(start, end - start);
      std::string out;
      for (std::size_t i = 0; i < text.size(); i++)
      {
         if (text[i] == '\\' && i + 1 < text.size())
         {
            char next = text[++i];
            out += (next == 'n') ? '\n' : next;
         }
         else
            out += text[i];
      }
      std::cout << "----- message -----\n" << out << '\n';
   }
   return 0;
}
