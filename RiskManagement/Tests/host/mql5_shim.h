// mql5_shim.h
// -----------------------------------------------------------------------------
// Minimal emulation of the MQL5 runtime used ONLY for host-side (Linux, C++17)
// verification of the EA Risk Management M1 sources. It is NOT part of the EA
// and is never installed into MetaTrader 5.
//
// Only the MQL5 functions/constants that M1 is allowed to use are provided.
// Deliberately absent: every trading / order / position / deal / history API,
// CTrade, files, chart objects, Sleep. If any source referenced one of them,
// the host build would fail to compile (an extra read-only check).
// WebRequest is emulated (recorder + scripted responses) for the Telegram add-on.
//
// Strings are UTF-8 std::string; StringLen / StringFind / StringSubstr /
// StringGetCharacter work on Unicode code points like MQL5 (UTF-16, BMP only).
//
// Enum values for account properties and margin modes are intentionally NOT
// the (undocumented) MT5 numbers, to prove the sources only use names.
// -----------------------------------------------------------------------------
#pragma once

#include <cmath>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
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

#define WHOLE_ARRAY (-1)
#define CP_ACP 0
#define CP_UTF8 65001

enum ENUM_MQL_INFO_INTEGER
{
   MQL_TESTER = 600,
   MQL_OPTIMIZATION,
   MQL_VISUAL_MODE
};

// MQL5 dynamic array "char x[];" (the build script rewrites the declaration)
template <typename T>
struct MqlDynArray
{
   std::vector<T> items;
   T &operator[](int index) { return items[static_cast<std::size_t>(index)]; }
   const T &operator[](int index) const { return items[static_cast<std::size_t>(index)]; }
};

template <typename T>
inline int ArrayResize(MqlDynArray<T> &array, int size)
{
   array.items.resize(static_cast<std::size_t>(size < 0 ? 0 : size));
   return static_cast<int>(array.items.size());
}

template <typename T>
inline int ArraySize(const MqlDynArray<T> &array) { return static_cast<int>(array.items.size()); }

struct ShimWebRequestRecord
{
   string method;
   string url;
   string headers;
   int timeout = 0;
   string body;
};

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

   bool tester = false;
   int web_status = 200; // HTTP status returned by WebRequest, or -1
   int web_error = 0;    // GetLastError() when web_status == -1
   string web_response = "{\"ok\":true,\"result\":{}}";
   std::vector<ShimWebRequestRecord> web_requests;

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
// byte offset of every code point, plus the total size at the end
inline std::vector<std::size_t> ShimCodePointOffsets(const string &text)
{
   std::vector<std::size_t> offsets;
   std::size_t i = 0;
   while (i < text.size())
   {
      offsets.push_back(i);
      unsigned char lead = static_cast<unsigned char>(text[i]);
      std::size_t length = 1;
      if (lead >= 0xF0)
         length = 4;
      else if (lead >= 0xE0)
         length = 3;
      else if (lead >= 0xC0)
         length = 2;
      i += length;
   }
   offsets.push_back(text.size());
   return offsets;
}

inline int StringLen(const string &text) { return static_cast<int>(ShimCodePointOffsets(text).size()) - 1; }

inline int StringFind(const string &text, const string &match, int start = 0)
{
   std::vector<std::size_t> offsets = ShimCodePointOffsets(text);
   int count = static_cast<int>(offsets.size()) - 1;
   if (start < 0)
      start = 0;
   if (start > count)
      return -1;
   std::size_t position = text.find(match, offsets[static_cast<std::size_t>(start)]);
   if (position == string::npos)
      return -1;
   for (int i = 0; i <= count; i++)
      if (offsets[static_cast<std::size_t>(i)] == position)
         return i;
   return -1;
}

inline string StringSubstr(const string &text, int start, int length = -1)
{
   std::vector<std::size_t> offsets = ShimCodePointOffsets(text);
   int count = static_cast<int>(offsets.size()) - 1;
   if (start < 0 || start >= count)
      return "";
   int stop = (length < 0 || start + length > count) ? count : start + length;
   std::size_t from = offsets[static_cast<std::size_t>(start)];
   return text.substr(from, offsets[static_cast<std::size_t>(stop)] - from);
}

inline ushort StringGetCharacter(const string &text, int position)
{
   std::vector<std::size_t> offsets = ShimCodePointOffsets(text);
   int count = static_cast<int>(offsets.size()) - 1;
   if (position < 0 || position >= count)
      return 0;
   std::size_t i = offsets[static_cast<std::size_t>(position)];
   unsigned char lead = static_cast<unsigned char>(text[i]);
   unsigned int code = lead;
   std::size_t extra = 0;
   if (lead >= 0xE0) { code = lead & 0x0F; extra = 2; }
   else if (lead >= 0xC0) { code = lead & 0x1F; extra = 1; }
   for (std::size_t k = 1; k <= extra && i + k < text.size(); k++)
      code = (code << 6) | (static_cast<unsigned char>(text[i + k]) & 0x3F);
   return static_cast<ushort>(code);
}

inline int StringReplace(string &text, const string &find, const string &replacement)
{
   if (find.empty())
      return 0;
   int count = 0;
   std::size_t position = 0;
   while ((position = text.find(find, position)) != string::npos)
   {
      text.replace(position, find.size(), replacement);
      position += replacement.size();
      count++;
   }
   return count;
}

inline long long StringToInteger(const string &text) { return std::strtoll(text.c_str(), nullptr, 10); }

// shim strings are already UTF-8: CP_UTF8 conversion is a byte copy (+ terminating 0)
inline int StringToCharArray(const string &text, MqlDynArray<char> &array, int start = 0, int count = -1, unsigned int codepage = CP_ACP)
{
   (void)start;
   (void)count;
   (void)codepage;
   array.items.assign(text.begin(), text.end());
   array.items.push_back(0);
   return static_cast<int>(array.items.size());
}

inline string CharArrayToString(const MqlDynArray<char> &array, int start = 0, int count = -1, unsigned int codepage = CP_ACP)
{
   (void)count;
   (void)codepage;
   string result;
   for (std::size_t i = static_cast<std::size_t>(start); i < array.items.size() && array.items[i] != 0; i++)
      result.push_back(array.items[i]);
   return result;
}

inline int MQLInfoInteger(int property) { return property == MQL_TESTER && g_shim.tester ? 1 : 0; }

// ---------------------------------------------------------------- WebRequest
inline int WebRequest(const string &method, const string &url, const string &headers, int timeout,
                      const MqlDynArray<char> &data, MqlDynArray<char> &result, string &result_headers)
{
   ShimWebRequestRecord record;
   record.method = method;
   record.url = url;
   record.headers = headers;
   record.timeout = timeout;
   record.body.assign(data.items.begin(), data.items.end());
   g_shim.web_requests.push_back(record);
   result_headers = "";
   result.items.clear();
   if (g_shim.web_status == -1)
   {
      g_shim_last_error = g_shim.web_error;
      return -1;
   }
   result.items.assign(g_shim.web_response.begin(), g_shim.web_response.end());
   return g_shim.web_status;
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
