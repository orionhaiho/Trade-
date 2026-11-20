# Read-only audit output (generated)

- Generated: 2026-11-20 00:01:27 UTC by `Tools/readonly_audit.py`
- Result: **PASS** (0 failure(s), 2 item(s) for manual review)

## Files audited

- production: `RiskManagement.mq5`
- production: `Include/Utils/Logger.mqh`
- production: `Include/Notify/HttpTransport.mqh`
- production: `Include/Notify/TelegramMessagesVi.mqh`
- production: `Include/Notify/TelegramNotifier.mqh`
- production: `Include/Models/AccountModel.mqh`
- production: `Include/Models/RiskEvent.mqh`
- production: `Include/Core/AccountEngine.mqh`
- production: `Include/Core/CoreEngine.mqh`
- production: `Include/Validation/DataValidator.mqh`
- test harness: `Tests/RiskManagement_M1_Tests.mq5`

## Findings

| Severity | File | Line | Finding |
|---|---|---|---|
| REVIEW | `Include/Notify/TelegramNotifier.mqh` | 253 | while-loop (checked manually for busy waiting) |
| REVIEW | `Include/Models/AccountModel.mqh` | 208 | while-loop (checked manually for busy waiting) |

## Terminal / account API call sites

| File | Line | API | Enclosing class |
|---|---|---|---|
| `RiskManagement.mq5` | 129 | `TimeLocal` | - |
| `RiskManagement.mq5` | 137 | `TimeLocal` | - |
| `RiskManagement.mq5` | 244 | `EventSetTimer` | - |
| `RiskManagement.mq5` | 261 | `TimeLocal` | - |
| `RiskManagement.mq5` | 272 | `TimeLocal` | - |
| `RiskManagement.mq5` | 284 | `EventKillTimer` | - |
| `RiskManagement.mq5` | 293 | `TimeLocal` | - |
| `RiskManagement.mq5` | 299 | `TimeLocal` | - |
| `Include/Utils/Logger.mqh` | 167 | `TimeLocal` | CLogger |
| `Include/Notify/HttpTransport.mqh` | 56 | `WebRequest` | CWebRequestTransport |
| `Include/Core/AccountEngine.mqh` | 80 | `TerminalInfoInteger` | CTerminalAccountDataSource |
| `Include/Core/AccountEngine.mqh` | 89 | `AccountInfoInteger` | CTerminalAccountDataSource |
| `Include/Core/AccountEngine.mqh` | 97 | `AccountInfoDouble` | CTerminalAccountDataSource |
| `Include/Core/AccountEngine.mqh` | 105 | `AccountInfoString` | CTerminalAccountDataSource |
| `Include/Core/AccountEngine.mqh` | 114 | `TimeTradeServer` | CTerminalAccountDataSource |
| `Include/Core/AccountEngine.mqh` | 122 | `TimeLocal` | CTerminalAccountDataSource |

## Forbidden names mentioned only in comments or string literals (informational)

None.

## Whitelist used

- production: `AccountInfoDouble`, `AccountInfoInteger`, `AccountInfoString`, `ArrayResize`, `CharArrayToString`, `CheckPointer`, `DoubleToString`, `EnumToString`, `EventKillTimer`, `EventSetTimer`, `GetLastError`, `GetPointer`, `IntegerToString`, `MQLInfoInteger`, `MathIsValidNumber`, `MathSqrt`, `Print`, `ResetLastError`, `StringFind`, `StringGetCharacter`, `StringLen`, `StringReplace`, `StringSubstr`, `StringToCharArray`, `StringToInteger`, `TerminalInfoInteger`, `TimeLocal`, `TimeToString`, `TimeTradeServer`, `WebRequest`
- test harness only: `ExpertRemove`, `MathExp`
- forbidden identifiers checked: 118

