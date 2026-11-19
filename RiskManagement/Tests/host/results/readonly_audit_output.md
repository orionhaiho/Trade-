# Read-only audit output (generated)

- Generated: 2026-11-19 23:42:24 UTC by `Tools/readonly_audit.py`
- Result: **PASS** (0 failure(s), 1 item(s) for manual review)

## Files audited

- production: `RiskManagement.mq5`
- production: `Include/Utils/Logger.mqh`
- production: `Include/Models/AccountModel.mqh`
- production: `Include/Core/AccountEngine.mqh`
- production: `Include/Core/CoreEngine.mqh`
- production: `Include/Validation/DataValidator.mqh`
- test harness: `Tests/RiskManagement_M1_Tests.mq5`

## Findings

| Severity | File | Line | Finding |
|---|---|---|---|
| REVIEW | `Include/Models/AccountModel.mqh` | 208 | while-loop (checked manually for busy waiting) |

## Terminal / account API call sites

| File | Line | API | Enclosing class |
|---|---|---|---|
| `RiskManagement.mq5` | 143 | `EventSetTimer` | - |
| `RiskManagement.mq5` | 174 | `EventKillTimer` | - |
| `Include/Utils/Logger.mqh` | 160 | `TimeLocal` | CLogger |
| `Include/Core/AccountEngine.mqh` | 80 | `TerminalInfoInteger` | CTerminalAccountDataSource |
| `Include/Core/AccountEngine.mqh` | 89 | `AccountInfoInteger` | CTerminalAccountDataSource |
| `Include/Core/AccountEngine.mqh` | 97 | `AccountInfoDouble` | CTerminalAccountDataSource |
| `Include/Core/AccountEngine.mqh` | 105 | `AccountInfoString` | CTerminalAccountDataSource |
| `Include/Core/AccountEngine.mqh` | 114 | `TimeTradeServer` | CTerminalAccountDataSource |
| `Include/Core/AccountEngine.mqh` | 122 | `TimeLocal` | CTerminalAccountDataSource |

## Forbidden names mentioned only in comments or string literals (informational)

None.

## Whitelist used

- production: `AccountInfoDouble`, `AccountInfoInteger`, `AccountInfoString`, `CheckPointer`, `DoubleToString`, `EnumToString`, `EventKillTimer`, `EventSetTimer`, `GetLastError`, `GetPointer`, `IntegerToString`, `MathIsValidNumber`, `MathSqrt`, `Print`, `ResetLastError`, `StringFind`, `StringGetCharacter`, `StringLen`, `StringSubstr`, `TerminalInfoInteger`, `TimeLocal`, `TimeToString`, `TimeTradeServer`
- test harness only: `ExpertRemove`, `MathExp`
- forbidden identifiers checked: 119

