// mql5_shim.h
// -----------------------------------------------------------------------------
// Minimal emulation of the MQL5 runtime used ONLY for host-side (Linux, C++17)
// verification of the EA Risk Management M1 sources. It is NOT part of the EA
// and is never installed into MetaTrader 5.
//
// Only the MQL5 functions/constants that M1 is allowed to use are provided.
// Deliberately absent: every trading / order / position / deal / history API,
// CTrade, files, network, chart objects, Sleep. If any M1 source referenced one
// of them, the host build would fail to compile (an extra read-only check).
//
// Enum values for account properties and margin modes are intentionally NOT
// the (undocumented) MT5 numbers, to prove the sources only use names.
// -----------------------------------------------------------------------------
#pragma once

#include <cmath>
#include <cstddef>
#include <cstdio>
#include <ctime>
#include <iostream>
#include <map>
#include <string>
#include <vector>

using string = std::string;
typedef long long datetime;
typedef unsigned short ushort; // only extra MQL5 type used by M1 (identical to glibc's)

// "input int X = 1;" becomes a mutable global the host tests can change.
#define input

// ---------------------------------------------------------------- constants
enum ENUM_INIT_RETCODE
{
   INIT_SUCCEEDED = 0,
   INIT_FAILED = 1,
   INIT_AGENT_NOT_SUITABLE = 32766,
   INIT_PARAMETERS_INCORRECT = 32767
};

#define REASON_PROGRAM 0
#define REASON_REMOVE 1
#define REASON_RECOMPILE 2
#define REASON_CHARTCHANGE 3
#define REASON_CHARTCLOSE 4
#define REASON_PARAMETERS 5
#define REASON_ACCOUNT 6
#define REASON_TEMPLATE 7
#define REASON_INITFAILED 8
#define REASON_CLOSE 9

#define TIME_DATE 1
#define TIME_MINUTES 2
#define TIME_SECONDS 4

enum ENUM_POINTER_TYPE
{
   POINTER_INVALID,
   POINTER_DYNAMIC,
   POINTER_AUTOMATIC
};

enum ENUM_ACCOUNT_INFO_INTEGER
{
   ACCOUNT_LOGIN = 900,
   ACCOUNT_TRADE_MODE,
   ACCOUNT_LEVERAGE,
   ACCOUNT_LIMIT_ORDERS,
   ACCOUNT_MARGIN_SO_MODE,
   ACCOUNT_TRADE_ALLOWED,
   ACCOUNT_TRADE_EXPERT,
   ACCOUNT_MARGIN_MODE,
   ACCOUNT_CURRENCY_DIGITS,
   ACCOUNT_FIFO_CLOSE
};

enum ENUM_ACCOUNT_INFO_DOUBLE
{
   ACCOUNT_BALANCE = 950,
   ACCOUNT_CREDIT,
   ACCOUNT_PROFIT,
   ACCOUNT_EQUITY,
   ACCOUNT_MARGIN,
   ACCOUNT_MARGIN_FREE,
   ACCOUNT_MARGIN_LEVEL,
   ACCOUNT_MARGIN_SO_CALL,
   ACCOUNT_MARGIN_SO_SO
};

enum ENUM_ACCOUNT_INFO_STRING
{
   ACCOUNT_NAME = 980,
   ACCOUNT_SERVER,
   ACCOUNT_CURRENCY,
   ACCOUNT_COMPANY
};

enum ENUM_ACCOUNT_MARGIN_MODE
{
   ACCOUNT_MARGIN_MODE_RETAIL_NETTING = 100,
   ACCOUNT_MARGIN_MODE_EXCHANGE = 101,
   ACCOUNT_MARGIN_MODE_RETAIL_HEDGING = 102
};

enum ENUM_TERMINAL_INFO_INTEGER
{
   TERMINAL_BUILD = 700,
   TERMINAL_CONNECTED,
   TERMINAL_TRADE_ALLOWED
};

// ------------------------------------------------------------ EnumToString
inline string EnumToString(ENUM_ACCOUNT_INFO_INTEGER value)
{
   switch (value)
   {
   case ACCOUNT_LOGIN: return "ACCOUNT_LOGIN";
   case ACCOUNT_TRADE_MODE: return "ACCOUNT_TRADE_MODE";
   case ACCOUNT_LEVERAGE: return "ACCOUNT_LEVERAGE";
   case ACCOUNT_LIMIT_ORDERS: return "ACCOUNT_LIMIT_ORDERS";
   case ACCOUNT_MARGIN_SO_MODE: return "ACCOUNT_MARGIN_SO_MODE";
   case ACCOUNT_TRADE_ALLOWED: return "ACCOUNT_TRADE_ALLOWED";
   case ACCOUNT_TRADE_EXPERT: return "ACCOUNT_TRADE_EXPERT";
   case ACCOUNT_MARGIN_MODE: return "ACCOUNT_MARGIN_MODE";
   case ACCOUNT_CURRENCY_DIGITS: return "ACCOUNT_CURRENCY_DIGITS";
   case ACCOUNT_FIFO_CLOSE: return "ACCOUNT_FIFO_CLOSE";
   }
   return "ENUM_ACCOUNT_INFO_INTEGER::" + std::to_string(static_cast<int>(value));
}

inline string EnumToString(ENUM_ACCOUNT_INFO_DOUBLE value)
{
   switch (value)
   {
   case ACCOUNT_BALANCE: return "ACCOUNT_BALANCE";
   case ACCOUNT_CREDIT: return "ACCOUNT_CREDIT";
   case ACCOUNT_PROFIT: return "ACCOUNT_PROFIT";
   case ACCOUNT_EQUITY: return "ACCOUNT_EQUITY";
   case ACCOUNT_MARGIN: return "ACCOUNT_MARGIN";
   case ACCOUNT_MARGIN_FREE: return "ACCOUNT_MARGIN_FREE";
   case ACCOUNT_MARGIN_LEVEL: return "ACCOUNT_MARGIN_LEVEL";
   case ACCOUNT_MARGIN_SO_CALL: return "ACCOUNT_MARGIN_SO_CALL";
   case ACCOUNT_MARGIN_SO_SO: return "ACCOUNT_MARGIN_SO_SO";
   }
   return "ENUM_ACCOUNT_INFO_DOUBLE::" + std::to_string(static_cast<int>(value));
}

inline string EnumToString(ENUM_ACCOUNT_INFO_STRING value)
{
   switch (value)
   {
   case ACCOUNT_NAME: return "ACCOUNT_NAME";
   case ACCOUNT_SERVER: return "ACCOUNT_SERVER";
   case ACCOUNT_CURRENCY: return "ACCOUNT_CURRENCY";
   case ACCOUNT_COMPANY: return "ACCOUNT_COMPANY";
   }
   return "ENUM_ACCOUNT_INFO_STRING::" + std::to_string(static_cast<int>(value));
}

// ------------------------------------------------- simulated terminal state
struct ShimTerminalState
{
   bool connected = true;
   int connected_error = 0;

   long long login = 12345678;
   string server = "Exness-MT5Real8";
   string company = "Exness Technologies Ltd";
   string currency = "USD";

   double balance = 1000.00;
   double equity = 1013.75;
   double profit = 12.50;
   double credit = 25.00;
   double margin = 50.00;
   double margin_free = 960.00;
   double margin_level = 2027.25;

   long long leverage = 500;
   long long margin_mode = ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
   long long trade_allowed = 1;
   long long trade_expert = 1;

   datetime server_time = 1795082400; // 2026.11.19 10:00:00
   datetime local_time = 1795107600;  // 2026.11.19 17:00:00 (differs on purpose)

   std::map<string, int> fail_errors; // EnumToString(property) -> GetLastError code

   bool timer_fails = false;
   int timer_fail_error = 4001;
   int set_timer_calls = 0;
   int last_timer_seconds = 0;
   int kill_timer_calls = 0;
   bool timer_active = false;
   int account_reads_at_set_timer = -1;

   int account_reads = 0;
   int expert_remove_calls = 0;

   std::vector<string> printed;
   bool echo = true;
};

inline ShimTerminalState g_shim;
inline int g_shim_last_error = 0;

// ------------------------------------------------------------ runtime/errors
inline void ResetLastError() { g_shim_last_error = 0; }
inline int GetLastError() { return g_shim_last_error; }

inline void Print(const string &text)
{
   g_shim.printed.push_back(text);
   if (g_shim.echo)
      std::cout << text << '\n';
}

inline void ExpertRemove() { g_shim.expert_remove_calls++; }

// ----------------------------------------------------------------- pointers
template <typename T>
inline ENUM_POINTER_TYPE CheckPointer(T *pointer) { return pointer ? POINTER_AUTOMATIC : POINTER_INVALID; }

template <typename T>
inline T *GetPointer(T &object) { return &object; }

// --------------------------------------------------------- account/terminal
inline bool ShimFail(const string &property)
{
   auto it = g_shim.fail_errors.find(property);
   if (it == g_shim.fail_errors.end())
      return false;
   g_shim_last_error = it->second;
   return true;
}

inline long long AccountInfoInteger(ENUM_ACCOUNT_INFO_INTEGER property)
{
   g_shim.account_reads++;
   if (ShimFail(EnumToString(property)))
      return 0;
   switch (property)
   {
   case ACCOUNT_LOGIN: return g_shim.login;
   case ACCOUNT_LEVERAGE: return g_shim.leverage;
   case ACCOUNT_MARGIN_MODE: return g_shim.margin_mode;
   case ACCOUNT_TRADE_ALLOWED: return g_shim.trade_allowed;
   case ACCOUNT_TRADE_EXPERT: return g_shim.trade_expert;
   default: break;
   }
   g_shim_last_error = 4003;
   return 0;
}

inline double AccountInfoDouble(ENUM_ACCOUNT_INFO_DOUBLE property)
{
   g_shim.account_reads++;
   if (ShimFail(EnumToString(property)))
      return 0.0;
   switch (property)
   {
   case ACCOUNT_BALANCE: return g_shim.balance;
   case ACCOUNT_CREDIT: return g_shim.credit;
   case ACCOUNT_PROFIT: return g_shim.profit;
   case ACCOUNT_EQUITY: return g_shim.equity;
   case ACCOUNT_MARGIN: return g_shim.margin;
   case ACCOUNT_MARGIN_FREE: return g_shim.margin_free;
   case ACCOUNT_MARGIN_LEVEL: return g_shim.margin_level;
   default: break;
   }
   g_shim_last_error = 4003;
   return 0.0;
}

inline string AccountInfoString(ENUM_ACCOUNT_INFO_STRING property)
{
   g_shim.account_reads++;
   if (ShimFail(EnumToString(property)))
      return "";
   switch (property)
   {
   case ACCOUNT_SERVER: return g_shim.server;
   case ACCOUNT_CURRENCY: return g_shim.currency;
   case ACCOUNT_COMPANY: return g_shim.company;
   default: break;
   }
   g_shim_last_error = 4003;
   return "";
}

inline int TerminalInfoInteger(int property)
{
   if (property == TERMINAL_CONNECTED)
   {
      if (g_shim.connected_error != 0)
      {
         g_shim_last_error = g_shim.connected_error;
         return 0;
      }
      return g_shim.connected ? 1 : 0;
   }
   g_shim_last_error = 4003;
   return 0;
}

inline datetime TimeTradeServer() { return g_shim.server_time; }
inline datetime TimeLocal() { return g_shim.local_time; }

// -------------------------------------------------------------------- timer
inline bool EventSetTimer(int seconds)
{
   g_shim.set_timer_calls++;
   g_shim.last_timer_seconds = seconds;
   g_shim.account_reads_at_set_timer = g_shim.account_reads;
   if (g_shim.timer_fails)
   {
      g_shim_last_error = g_shim.timer_fail_error;
      return false;
   }
   g_shim.timer_active = true;
   return true;
}

inline void EventKillTimer()
{
   g_shim.kill_timer_calls++;
   g_shim.timer_active = false;
}

// --------------------------------------------------------------------- math
inline double MathSqrt(double value) { return std::sqrt(value); }
inline double MathExp(double value) { return std::exp(value); }
inline bool MathIsValidNumber(double value) { return std::isfinite(value); }

// ------------------------------------------------------------------ strings
inline int StringLen(const string &text) { return static_cast<int>(text.size()); }

inline int StringFind(const string &text, const string &match, int start = 0)
{
   if (start < 0)
      start = 0;
   std::size_t position = text.find(match, static_cast<std::size_t>(start));
   return position == string::npos ? -1 : static_cast<int>(position);
}

inline string StringSubstr(const string &text, int start, int length = -1)
{
   if (start < 0 || start >= static_cast<int>(text.size()))
      return "";
   if (length < 0)
      return text.substr(static_cast<std::size_t>(start));
   return text.substr(static_cast<std::size_t>(start), static_cast<std::size_t>(length));
}

inline ushort StringGetCharacter(const string &text, int position)
{
   if (position < 0 || position >= static_cast<int>(text.size()))
      return 0;
   return static_cast<unsigned char>(text[static_cast<std::size_t>(position)]);
}

inline string IntegerToString(long long value, int /*str_len*/ = 0, ushort /*fill*/ = ' ')
{
   return std::to_string(value);
}

inline string DoubleToString(double value, int digits = 8)
{
   char buffer[512];
   std::snprintf(buffer, sizeof(buffer), "%.*f", digits, value);
   return buffer;
}

inline string TimeToString(datetime value, int flags = TIME_DATE | TIME_MINUTES)
{
   std::time_t raw = static_cast<std::time_t>(value);
   std::tm parts{};
   gmtime_r(&raw, &parts);
   char buffer[64];
   string result;
   if (flags & TIME_DATE)
   {
      std::snprintf(buffer, sizeof(buffer), "%04d.%02d.%02d", parts.tm_year + 1900, parts.tm_mon + 1, parts.tm_mday);
      result += buffer;
   }
   if (flags & (TIME_MINUTES | TIME_SECONDS))
   {
      if (!result.empty())
         result += " ";
      if (flags & TIME_SECONDS)
         std::snprintf(buffer, sizeof(buffer), "%02d:%02d:%02d", parts.tm_hour, parts.tm_min, parts.tm_sec);
      else
         std::snprintf(buffer, sizeof(buffer), "%02d:%02d", parts.tm_hour, parts.tm_min);
      result += buffer;
   }
   return result;
}
