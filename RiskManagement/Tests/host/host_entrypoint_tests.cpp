// host_entrypoint_tests.cpp
// Lifecycle tests of the real entry point (RiskManagement.mq5: OnInit / OnTimer /
// OnDeinit) compiled as C++17 against mql5_shim.h. The shim simulates the
// terminal (connection, account values, API errors, timer creation failure).
//
// The EA globals persist between tests exactly as they do when MT5 calls
// OnDeinit/OnInit without unloading the EA (symbol/period change), so every
// test also exercises the "full reset in OnInit" requirement.
//
// Host-simulated evidence only; not a substitute for MT5 runtime tests.
#include "mql5_shim.h"
#include "RiskManagement.mq5"

#include <string>

namespace
{
int g_total = 0;
int g_failed = 0;
int g_checks = 0;
int g_check_failures = 0;
std::string g_name;

void Begin(const std::string &name)
{
   g_name = name;
   g_checks = 0;
   g_check_failures = 0;
   g_shim = ShimTerminalState();
   g_shim.echo = false;
   g_shim_last_error = 0;
   InpAccountRefreshSeconds = 1;
   InpEnableLogging = true;
   InpEnableDebugLogging = false;
   InpRequireConnectedTerminal = true;
   InpTelegramEnable = false;
   InpTelegramBotToken = "";
   InpTelegramChatId = "";
   InpTelegramSummaryMinutes = 0;
   InpTelegramTimeoutMs = 5000;
}

const std::string kToken = "123456789:TESTtokenTESTtokenTESTtoken_-0123";

void EnableTelegram()
{
   InpTelegramEnable = true;
   InpTelegramBotToken = kToken;
   InpTelegramChatId = "123456789";
}

int CountRequestsContaining(const std::string &needle)
{
   int count = 0;
   for (const ShimWebRequestRecord &request : g_shim.web_requests)
      if (request.body.find(needle) != std::string::npos)
         count++;
   return count;
}

bool LogContains(const std::string &needle)
{
   for (const std::string &line : g_shim.printed)
      if (line.find(needle) != std::string::npos)
         return true;
   return false;
}

void Expect(bool condition, const std::string &what)
{
   g_checks++;
   if (condition)
      return;
   g_check_failures++;
   std::cout << "[HOST-E]   check failed in " << g_name << ": " << what << '\n';
}

void End()
{
   g_total++;
   if (g_check_failures == 0 && g_checks > 0)
   {
      std::cout << "[HOST-E] PASS " << g_name << " (" << g_checks << " checks)\n";
   }
   else
   {
      g_failed++;
      std::cout << "[HOST-E] FAIL " << g_name << " (" << g_check_failures << " of " << g_checks << " checks failed)\n";
      for (const std::string &line : g_shim.printed)
         std::cout << "[HOST-E]     log: " << line << '\n';
   }
}

int CountLines(const std::string &needle)
{
   int count = 0;
   for (const std::string &line : g_shim.printed)
      if (line.find(needle) != std::string::npos)
         count++;
   return count;
}

int FirstLine(const std::string &needle)
{
   for (std::size_t i = 0; i < g_shim.printed.size(); i++)
      if (g_shim.printed[i].find(needle) != std::string::npos)
         return static_cast<int>(i);
   return -1;
}

void Timers(int count)
{
   for (int i = 0; i < count; i++)
      OnTimer();
}
} // namespace

int main()
{
   // E01 ---------------------------------------------------------------
   Begin("E01 valid start: inputs -> core -> initial collection -> timer -> EA_INITIALIZED");
   {
      int result = OnInit();
      Expect(result == INIT_SUCCEEDED, "OnInit returns INIT_SUCCEEDED");
      Expect(g_shim.set_timer_calls == 1, "EventSetTimer called once");
      Expect(g_shim.last_timer_seconds == 1, "EventSetTimer uses InpAccountRefreshSeconds (1)");
      Expect(g_shim.account_reads_at_set_timer > 0, "initial collection ran before the timer was created");
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_VALID, "initial collection VALID");
      int success = FirstLine("[INFO][ACCOUNT_COLLECTION_SUCCESS]");
      int initialized = FirstLine("[INFO][EA_INITIALIZED]");
      Expect(success >= 0 && initialized > success, "EA_INITIALIZED logged after the initial collection");
      Expect(CountLines("login=12345678 server=\"Exness-MT5Real8\" currency=\"USD\"") == 2, "identity logged at initialization");
      Expect(CountLines("[EA_INITIALIZATION_FAILED]") == 0, "no initialization failure");
      OnDeinit(REASON_REMOVE);
   }
   End();

   // E02 ---------------------------------------------------------------
   Begin("E02 OnTimer refreshes; configured interval passed to EventSetTimer");
   {
      InpAccountRefreshSeconds = 7;
      int result = OnInit();
      Expect(result == INIT_SUCCEEDED, "OnInit returns INIT_SUCCEEDED");
      Expect(g_shim.last_timer_seconds == 7, "EventSetTimer(7) for InpAccountRefreshSeconds=7");
      int reads = g_shim.account_reads;
      g_shim.equity = 1020.00;
      Timers(1);
      Expect(g_shim.account_reads > reads, "OnTimer performs a collection");
      AccountSnapshot snapshot;
      Expect(g_core.GetLatestSnapshot(snapshot) && snapshot.equity == 1020.00, "new terminal value published by the timer cycle");
      Expect(g_shim.printed.size() == 2, "no per-cycle log line with debug logging off");
      OnDeinit(REASON_REMOVE);
   }
   End();

   // E03 ---------------------------------------------------------------
   Begin("E03 invalid refresh interval: OnInit fails, nothing initialized, no timer");
   {
      InpAccountRefreshSeconds = 0;
      int result = OnInit();
      Expect(result == INIT_PARAMETERS_INCORRECT, "OnInit returns INIT_PARAMETERS_INCORRECT for 0");
      Expect(g_shim.set_timer_calls == 0, "no timer created");
      Expect(g_shim.account_reads == 0, "no account read");
      Expect(CountLines("[ERROR][EA_INITIALIZATION_FAILED] Invalid input: InpAccountRefreshSeconds must be >= 1") == 1, "failure logged with the reason");
      OnDeinit(REASON_INITFAILED);
      Expect(g_shim.kill_timer_calls == 0, "EventKillTimer not called (timer never created)");
      Expect(CountLines("[EA_SHUTDOWN] RiskManagement M1 stopped, reason=INITFAILED (8)") == 1, "shutdown logged with REASON_INITFAILED");
      InpAccountRefreshSeconds = -3;
      Expect(OnInit() == INIT_PARAMETERS_INCORRECT, "OnInit returns INIT_PARAMETERS_INCORRECT for -3");
      OnDeinit(REASON_INITFAILED);
   }
   End();

   // E04 ---------------------------------------------------------------
   Begin("E04 timer creation failure: OnInit fails safely, EventKillTimer never called");
   {
      g_shim.timer_fails = true;
      int result = OnInit();
      Expect(result == INIT_FAILED, "OnInit returns INIT_FAILED");
      Expect(CountLines("[ERROR][EA_INITIALIZATION_FAILED] EventSetTimer(1) failed, GetLastError=4001") == 1, "timer failure logged with GetLastError");
      Expect(CountLines("[EA_INITIALIZED]") == 0, "EA_INITIALIZED not logged");
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_UNAVAILABLE, "core shut down after the failure");
      AccountSnapshot snapshot;
      Expect(!g_core.GetLatestSnapshot(snapshot), "no snapshot served after the failure");
      OnDeinit(REASON_INITFAILED);
      Expect(g_shim.kill_timer_calls == 0, "EventKillTimer not called");
   }
   End();

   // E05 ---------------------------------------------------------------
   Begin("E05 safe shutdown: timer killed exactly once, core released, EA_SHUTDOWN logged");
   {
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      OnDeinit(REASON_REMOVE);
      Expect(g_shim.kill_timer_calls == 1, "EventKillTimer called once");
      Expect(!g_shim.timer_active, "timer inactive");
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_UNAVAILABLE, "core status UNAVAILABLE after shutdown");
      Expect(CountLines("[INFO][EA_SHUTDOWN] RiskManagement M1 stopped, reason=REMOVE (1)") == 1, "EA_SHUTDOWN logged with the reason");
      OnDeinit(REASON_REMOVE);
      Expect(g_shim.kill_timer_calls == 1, "a second OnDeinit does not kill the timer again");
   }
   End();

   // E06 ---------------------------------------------------------------
   Begin("E06 Q-01: start while disconnected -> init succeeds, UNAVAILABLE, then VALID on reconnect");
   {
      g_shim.connected = false;
      int result = OnInit();
      Expect(result == INIT_SUCCEEDED, "OnInit succeeds although the first collection is not VALID");
      Expect(g_shim.set_timer_calls == 1, "timer created");
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_UNAVAILABLE, "status UNAVAILABLE");
      Expect(CountLines("[WARNING][TERMINAL_DISCONNECTED]") == 1, "TERMINAL_DISCONNECTED logged");
      Expect(CountLines("Account identity pending (no valid snapshot yet)") == 1, "EA_INITIALIZED says the identity is pending");
      Timers(5);
      Expect(CountLines("[TERMINAL_DISCONNECTED]") == 1, "no repeated disconnect line");
      g_shim.connected = true;
      Timers(2);
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_VALID, "VALID after reconnect");
      Expect(CountLines("[INFO][TERMINAL_RECONNECTED]") == 1, "TERMINAL_RECONNECTED logged once");
      Expect(CountLines("Terminal connected to the trade server (it was not connected when the EA started)") == 1,
             "first connection after a disconnected start is worded as such");
      Expect(CountLines("First valid account snapshot; identity baseline locked: login=12345678") == 1, "identity baseline locked and logged");
      OnDeinit(REASON_REMOVE);
   }
   End();

   // E07 ---------------------------------------------------------------
   Begin("E07 re-init without unload (chart change / account reload) resets all state");
   {
      Expect(OnInit() == INIT_SUCCEEDED, "first OnInit");
      OnDeinit(REASON_CHARTCHANGE);
      g_shim.login = 55556666;
      Expect(OnInit() == INIT_SUCCEEDED, "second OnInit");
      AccountSnapshot snapshot;
      Expect(g_core.GetLatestSnapshot(snapshot) && snapshot.login == 55556666, "new account monitored after re-init");
      Expect(CountLines("[ACCOUNT_IDENTITY_CHANGED]") == 0, "re-init is a restart, not an identity change");
      Expect(g_shim.set_timer_calls == 2 && g_shim.kill_timer_calls == 1, "one live timer at a time");
      OnDeinit(REASON_REMOVE);
   }
   End();

   // E08 ---------------------------------------------------------------
   Begin("E08 Q-03: InpEnableLogging=false prints only ERROR events");
   {
      InpEnableLogging = false;
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      Expect(g_shim.printed.empty(), "no INFO line printed");
      g_shim.connected = false;
      Timers(3);
      Expect(g_shim.printed.empty(), "disconnect WARNINGs suppressed");
      g_shim.connected = true;
      g_shim.margin = -1.0;
      Timers(3);
      Expect(CountLines("[ERROR][ACCOUNT_COLLECTION_FAILED]") == 1, "INVALID data ERROR still printed once");
      Expect(g_shim.printed.size() == 1, "nothing else printed");
      OnDeinit(REASON_REMOVE);
      Expect(g_shim.printed.size() == 1, "EA_SHUTDOWN (INFO) suppressed");
      g_shim.printed.clear();
      InpAccountRefreshSeconds = 0;
      Expect(OnInit() == INIT_PARAMETERS_INCORRECT, "invalid input still rejected");
      Expect(CountLines("[ERROR][EA_INITIALIZATION_FAILED]") == 1, "initialization failure printed with logging disabled");
      OnDeinit(REASON_INITFAILED);
   }
   End();

   // E09 ---------------------------------------------------------------
   Begin("E09 debug logging: one detail line per successful cycle, only when enabled");
   {
      InpEnableDebugLogging = true;
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      Timers(3);
      Expect(CountLines("[DEBUG][ACCOUNT_COLLECTION_SUCCESS] cycle=") == 4, "4 successful cycles -> 4 DEBUG lines");
      Expect(CountLines("balance=1000.00 equity=1013.75 profit=12.50 credit=25.00 margin=50.00 free_margin=960.00 margin_level=2027.25 leverage=500 margin_mode=RETAIL_HEDGING") == 4,
             "DEBUG lines carry the collected values");
      OnDeinit(REASON_REMOVE);
      g_shim.printed.clear();
      InpEnableLogging = false;
      InpEnableDebugLogging = true;
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds (logging off, debug on)");
      Timers(3);
      Expect(CountLines("[DEBUG]") == 0, "debug requires InpEnableLogging=true");
      OnDeinit(REASON_REMOVE);
   }
   End();

   // E10 ---------------------------------------------------------------
   Begin("E10 InpRequireConnectedTerminal=false + disconnected -> STALE, never VALID");
   {
      InpRequireConnectedTerminal = false;
      g_shim.connected = false;
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_STALE, "status STALE");
      AccountSnapshot snapshot;
      Expect(!g_core.GetLatestSnapshot(snapshot), "STALE data not current");
      Expect(g_core.GetLastSuccessfulCollectionTime() == 0, "STALE data not stored as successful");
      g_shim.connected = true;
      Timers(1);
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_VALID, "VALID once connected");
      OnDeinit(REASON_REMOVE);
   }
   End();

   // E11 ---------------------------------------------------------------
   Begin("E11 server time unavailable -> UNAVAILABLE, logged once, local time never used");
   {
      g_shim.server_time = 0;
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      Timers(4);
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_UNAVAILABLE, "status UNAVAILABLE");
      Expect(CountLines("SERVER_TIME_UNAVAILABLE") == 2, "reported once by the failure line and once by EA_INITIALIZED");
      Expect(CountLines("[ERROR][ACCOUNT_COLLECTION_FAILED]") == 1, "one ERROR for five cycles");
      g_shim.server_time = 1795082460;
      Timers(1);
      AccountSnapshot snapshot;
      Expect(g_core.GetLatestSnapshot(snapshot) && snapshot.server_time == 1795082460, "server time from TimeTradeServer once available");
      Expect(snapshot.collection_time == 1795107600, "collection time from TimeLocal");
      OnDeinit(REASON_REMOVE);
   }
   End();

   // E12 ---------------------------------------------------------------
   Begin("E12 identity change without re-init -> latched UNAVAILABLE, reads stop, logged once");
   {
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      g_shim.login = 77778888;
      Timers(1);
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_UNAVAILABLE, "status UNAVAILABLE");
      int reads = g_shim.account_reads;
      Timers(10);
      Expect(g_shim.account_reads == reads, "no account read after the latch");
      Expect(CountLines("[ERROR][ACCOUNT_IDENTITY_CHANGED]") == 1, "ACCOUNT_IDENTITY_CHANGED logged once");
      Expect(CountLines("restart the EA") == 1, "restart requested");
      OnDeinit(REASON_REMOVE);
   }
   End();

   // E13 ---------------------------------------------------------------
   Begin("E13 terminal API error (GetLastError) -> UNAVAILABLE naming the property");
   {
      g_shim.fail_errors["ACCOUNT_EQUITY"] = 4001;
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      Timers(3);
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_UNAVAILABLE, "status UNAVAILABLE");
      Expect(CountLines("[ERROR][ACCOUNT_COLLECTION_FAILED] No valid account snapshot: status=UNAVAILABLE reason=API_ERROR: AccountInfoDouble(ACCOUNT_EQUITY) failed, GetLastError=4001") == 1,
             "API error logged once with property and code");
      g_shim.fail_errors.clear();
      Timers(1);
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_VALID, "VALID once the error clears");
      Expect(CountLines("First valid account snapshot") == 1, "first valid snapshot logged");
      OnDeinit(REASON_REMOVE);
   }
   End();


   // E14 ---------------------------------------------------------------
   Begin("E14 Telegram: start message sent by WebRequest, in Vietnamese, after the first refresh");
   {
      EnableTelegram();
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      Expect(g_shim.web_requests.empty(), "no network call inside OnInit");
      Timers(1);
      Expect(g_shim.web_requests.size() == 1, "one request on the first timer cycle");
      if (!g_shim.web_requests.empty())
      {
         const ShimWebRequestRecord &request = g_shim.web_requests[0];
         Expect(request.method == "POST", "POST");
         Expect(request.url == "https://api.telegram.org/bot" + kToken + "/sendMessage", "sendMessage URL");
         Expect(request.headers.find("Content-Type: application/json") != std::string::npos, "JSON content type");
         Expect(request.timeout == 5000, "InpTelegramTimeoutMs used");
         Expect(request.body.find("\"chat_id\":\"123456789\"") != std::string::npos, "chat id");
         Expect(request.body.find("EA đã khởi động") != std::string::npos, "Vietnamese UTF-8 start message");
         Expect(request.body.find("Balance: 1000.00 USD") != std::string::npos, "account values");
         Expect(request.body.find("Đã nhận dữ liệu tài khoản hợp lệ") == std::string::npos, "initial collection summarised by the start message (no duplicate)");
         Expect(request.body.back() == '}', "no terminating zero sent");
      }
      Timers(5);
      Expect(g_shim.web_requests.size() == 1, "nothing more while nothing changes");
      Expect(!LogContains(kToken), "token never logged");
      OnDeinit(REASON_REMOVE);
   }
   End();

   // E15 ---------------------------------------------------------------
   Begin("E15 Telegram: invalid token -> OnInit rejected, token not logged, no request");
   {
      EnableTelegram();
      InpTelegramBotToken = "123456789:" + std::string("short");
      Expect(OnInit() == INIT_PARAMETERS_INCORRECT, "INIT_PARAMETERS_INCORRECT");
      Expect(CountLines("[ERROR][EA_INITIALIZATION_FAILED] Invalid input: InpTelegramBotToken") == 1, "reason logged");
      Expect(!LogContains("short"), "token text not logged");
      OnDeinit(REASON_INITFAILED);
      Expect(g_shim.web_requests.empty(), "no request");
   }
   End();

   // E16 ---------------------------------------------------------------
   Begin("E16 Telegram: WebRequest not allowed (4014) -> monitoring unaffected, one ERROR, retried");
   {
      EnableTelegram();
      g_shim.web_status = -1;
      g_shim.web_error = 4014;
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      Timers(3);
      Expect(g_core.GetCurrentStatus() == DATA_STATUS_VALID, "account monitoring still VALID");
      Expect(g_shim.web_requests.size() == 1, "one attempt, then back-off");
      Expect(CountLines("[ERROR][TELEGRAM_SEND_FAILED] WebRequest is not allowed (error 4014)") == 1, "fix explained once");
      g_shim.local_time += 10;
      Timers(1);
      Expect(g_shim.web_requests.size() == 2, "retried after 10 s");
      g_shim.web_status = 200;
      g_shim.local_time += 20;
      Timers(1);
      Expect(CountLines("[INFO][TELEGRAM_SEND_RECOVERED]") == 1, "recovery logged");
      Expect(!LogContains(kToken), "token never logged");
      OnDeinit(REASON_REMOVE);
   }
   End();

   // E17 ---------------------------------------------------------------
   Begin("E17 Telegram: stop message flushed in OnDeinit with a short timeout");
   {
      EnableTelegram();
      InpTelegramTimeoutMs = 8000;
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      Timers(1);
      std::size_t before = g_shim.web_requests.size();
      OnDeinit(REASON_REMOVE);
      Expect(g_shim.web_requests.size() == before + 1, "one request in OnDeinit");
      Expect(CountRequestsContaining("EA đã dừng") == 1 && CountRequestsContaining("EA bị gỡ khỏi chart") == 1, "Vietnamese stop reason");
      Expect(g_shim.web_requests.back().timeout == 3000, "flush timeout capped at 3000 ms");
   }
   End();

   // E18 ---------------------------------------------------------------
   Begin("E18 Telegram disabled (default): no network call in the whole lifecycle");
   {
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      g_shim.connected = false;
      Timers(3);
      g_shim.connected = true;
      Timers(3);
      OnDeinit(REASON_REMOVE);
      Expect(g_shim.web_requests.empty(), "no WebRequest");
   }
   End();

   // E19 ---------------------------------------------------------------
   Begin("E19 Telegram: invalid refresh input is still reported to Telegram");
   {
      EnableTelegram();
      InpAccountRefreshSeconds = 0;
      Expect(OnInit() == INIT_PARAMETERS_INCORRECT, "rejected");
      OnDeinit(REASON_INITFAILED);
      Expect(g_shim.web_requests.size() == 1, "one request at OnDeinit");
      Expect(CountRequestsContaining("EA khởi động thất bại") == 1, "failure message in Vietnamese");
      Expect(CountRequestsContaining("InpAccountRefreshSeconds") == 1, "reason included");
   }
   End();

   // E20 ---------------------------------------------------------------
   Begin("E20 Telegram: disconnect/reconnect messages and periodic summary");
   {
      EnableTelegram();
      InpTelegramSummaryMinutes = 1;
      Expect(OnInit() == INIT_SUCCEEDED, "OnInit succeeds");
      Timers(1);
      g_shim.connected = false;
      g_shim.local_time += 1;
      Timers(1);
      Expect(CountRequestsContaining("Terminal mất kết nối tới máy chủ giao dịch") == 1, "disconnect message");
      g_shim.connected = true;
      g_shim.local_time += 4;
      Timers(1);
      Expect(CountRequestsContaining("Terminal đã kết nối lại") == 1, "reconnect message");
      Expect(CountRequestsContaining("khoảng 4 giây") == 1, "outage duration in Vietnamese");
      g_shim.local_time += 60;
      Timers(1);
      Expect(CountRequestsContaining("Tóm tắt tài khoản") == 1, "summary after 1 minute");
      Timers(3);
      Expect(CountRequestsContaining("Tóm tắt tài khoản") == 1, "no extra summary within the interval");
      OnDeinit(REASON_REMOVE);
   }
   End();

   std::cout << "[HOST-E] SUMMARY total=" << g_total << " passed=" << (g_total - g_failed)
             << " failed=" << g_failed << '\n';
   return g_failed == 0 ? 0 : 1;
}
