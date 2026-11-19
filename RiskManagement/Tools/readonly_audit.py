#!/usr/bin/env python3
"""
Read-only audit for EA Risk Management M1 (static analysis, Python 3.8+).

Checks every MQL5 source file of the project:
  A. no forbidden identifier in code (trading, order/position/deal/history,
     trade classes, files, network, chart objects/UI, Sleep, DLL import, ...)
  B. includes: only quoted includes that resolve inside the project;
     no standard-library (<...>) include, no #import
  C. preprocessor: only include guards as conditionals; no macro that hides a
     forbidden name or wraps a function call
  D. call whitelist: every called identifier is either defined in the project
     or in the explicit list of allowed read-only MQL5 functions
  E. terminal/account API call sites are listed; AccountInfo*,
     TerminalInfoInteger and TimeTradeServer may only be called inside
     CTerminalAccountDataSource
  F. no dynamic allocation (new/delete), no while-loops (busy wait)

Comments and string literals are removed before matching, so text such as
"no OrderSend here" in a comment never hides or fakes a finding. Mentions in
comments are listed separately for transparency.

Usage:  python3 Tools/readonly_audit.py [project_dir] [--output report.md]
Exit code 0 = PASS, 1 = FAIL.
"""
import argparse
import os
import re
import sys
from datetime import datetime, timezone

FORBIDDEN = [
    # trade functions
    "OrderSend", "OrderSendAsync", "OrderCheck", "OrderCalcMargin", "OrderCalcProfit",
    "OrderSelect", "OrderGetTicket", "OrderGetInteger", "OrderGetDouble", "OrderGetString",
    "OrdersTotal", "OrderClose", "OrderModify", "OrderDelete", "OrderCloseBy",
    "PositionSelect", "PositionSelectByTicket", "PositionGetTicket", "PositionGetSymbol",
    "PositionGetInteger", "PositionGetDouble", "PositionGetString", "PositionsTotal",
    "PositionOpen", "PositionClose", "PositionCloseBy", "PositionClosePartial", "PositionModify",
    "HistorySelect", "HistorySelectByPosition", "HistoryOrderSelect", "HistoryDealSelect",
    "HistoryOrdersTotal", "HistoryDealsTotal", "HistoryOrderGetTicket", "HistoryDealGetTicket",
    "HistoryOrderGetInteger", "HistoryOrderGetDouble", "HistoryOrderGetString",
    "HistoryDealGetInteger", "HistoryDealGetDouble", "HistoryDealGetString",
    # trade classes / structures (Standard Library and MQL5)
    "CTrade", "CPositionInfo", "COrderInfo", "CHistoryOrderInfo", "CDealInfo", "CAccountInfo",
    "CExpert", "CExpertTrade", "CExpertMoney", "CExpertTrailing",
    "Buy", "Sell", "BuyLimit", "SellLimit", "BuyStop", "SellStop",
    "MqlTradeRequest", "MqlTradeResult", "MqlTradeCheckResult", "MqlTradeTransaction",
    "OnTrade", "OnTradeTransaction",
    # files, network, notifications, DLL
    "FileOpen", "FileClose", "FileWrite", "FileWriteString", "FileWriteArray", "FileWriteStruct",
    "FileWriteDouble", "FileWriteInteger", "FileWriteLong", "FileDelete", "FileMove", "FileCopy",
    "FileFlush", "FolderCreate", "FolderDelete", "FolderClean",
    "WebRequest", "SocketCreate", "SocketConnect", "SocketSend", "SocketTlsSend",
    "SendFTP", "SendMail", "SendNotification",
    # chart / UI
    "ObjectCreate", "ObjectDelete", "ObjectsDeleteAll", "ObjectSetInteger", "ObjectSetDouble",
    "ObjectSetString", "ObjectMove", "ChartSetInteger", "ChartSetDouble", "ChartSetString",
    "ChartApplyTemplate", "ChartOpen", "ChartClose", "ChartRedraw", "Comment", "Alert",
    "PlaySound", "MessageBox", "ResourceCreate", "EventChartCustom",
    # blocking / global state / terminal control
    "Sleep", "GlobalVariableSet", "GlobalVariableSetOnCondition", "GlobalVariableDel",
    "GlobalVariablesDeleteAll", "GlobalVariablesFlush", "GlobalVariableTemp", "TerminalClose",
    "iCustom", "IndicatorCreate", "CustomSymbolCreate",
]

# read-only MQL5 functions the production sources may call
ALLOWED_PRODUCTION = {
    "AccountInfoInteger", "AccountInfoDouble", "AccountInfoString",
    "TerminalInfoInteger", "TimeTradeServer", "TimeLocal",
    "EventSetTimer", "EventKillTimer",
    "Print", "ResetLastError", "GetLastError",
    "MathIsValidNumber", "MathSqrt",
    "StringLen", "StringFind", "StringSubstr", "StringGetCharacter",
    "IntegerToString", "DoubleToString", "TimeToString", "EnumToString",
    "CheckPointer", "GetPointer",
}
# extra functions allowed in the test harness only
ALLOWED_TEST_ONLY = {"MathExp", "ExpertRemove"}

ACCOUNT_APIS = {"AccountInfoInteger", "AccountInfoDouble", "AccountInfoString"}
# may be called only inside CTerminalAccountDataSource
DATA_SOURCE_ONLY = ACCOUNT_APIS | {"TerminalInfoInteger", "TimeTradeServer"}
TERMINAL_APIS = DATA_SOURCE_ONLY | {"TimeLocal", "EventSetTimer", "EventKillTimer"}

KEYWORDS = {"if", "for", "while", "switch", "return", "sizeof", "case", "do", "else",
            "catch", "delete", "new", "operator", "template", "typename", "defined"}

CALL_RE = re.compile(r"\b([A-Za-z_]\w*)\s*\(")
DEF_RE = re.compile(r"\b([A-Za-z_]\w*)\s*\([^;{}()]*(?:\([^;{}()]*\)[^;{}()]*)*\)\s*(?:const\s*)?\{")
CLASS_RE = re.compile(r"\b(?:class|struct|interface|enum)\s+([A-Za-z_]\w*)")
INCLUDE_RE = re.compile(r'^\s*#\s*include\s+(["<])([^">]+)[">]', re.M)


def strip_comments_and_strings(text):
    """Replace comments and string/char literals by spaces, keeping newlines."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if c == "/" and nxt == "/":
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif c == "/" and nxt == "*":
            j = text.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append(re.sub(r"[^\n]", " ", text[i:j]))
            i = j
        elif c in "\"'":
            quote = c
            j = i + 1
            while j < n and text[j] != quote:
                if text[j] == "\\":
                    j += 1
                if j < n and text[j] == "\n":
                    break
                j += 1
            j = min(j + 1, n)
            out.append(quote + " " * max(0, j - i - 2) + (quote if j - i >= 2 else ""))
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def comment_text(text):
    """Only comments and string literals (for the informational 'mentions' list)."""
    code = strip_comments_and_strings(text)
    return "".join(t if c == " " and t != " " else (" " if t != "\n" else "\n")
                   for t, c in zip(text, code))


def line_of(text, index):
    return text.count("\n", 0, index) + 1


def collect_files(root):
    production, tests = [], []
    main = os.path.join(root, "RiskManagement.mq5")
    if os.path.isfile(main):
        production.append(main)
    for base, _dirs, files in os.walk(os.path.join(root, "Include")):
        for name in sorted(files):
            if name.endswith((".mqh", ".mq5")):
                production.append(os.path.join(base, name))
    tests_dir = os.path.join(root, "Tests")
    if os.path.isdir(tests_dir):
        for name in sorted(os.listdir(tests_dir)):
            if name.endswith((".mq5", ".mqh")):
                tests.append(os.path.join(tests_dir, name))
    return production, tests


def class_ranges(code):
    """(name, start_index, end_index) of each class body, by brace matching."""
    ranges = []
    for m in re.finditer(r"\bclass\s+([A-Za-z_]\w*)[^;{]*\{", code):
        depth, j = 0, m.end() - 1
        while j < len(code):
            if code[j] == "{":
                depth += 1
            elif code[j] == "}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        ranges.append((m.group(1), m.start(), j))
    return ranges


def audit(root):
    production, tests = collect_files(root)
    findings = []          # (severity, file, line, message)
    api_sites = []         # (file, line, api, enclosing class)
    mentions = []          # (file, line, word)
    defined = set()
    sources = {}

    for path in production + tests:
        with open(path, encoding="utf-8") as handle:
            raw = handle.read()
        code = strip_comments_and_strings(raw)
        sources[path] = (raw, code)
        defined.update(m.group(1) for m in DEF_RE.finditer(code))
        defined.update(m.group(1) for m in CLASS_RE.finditer(code))

    forbidden_re = re.compile(r"\b(" + "|".join(sorted(map(re.escape, FORBIDDEN), key=len, reverse=True)) + r")\b")

    for path in production + tests:
        raw, code = sources[path]
        rel = os.path.relpath(path, root)
        is_test = path in tests

        # A. forbidden identifiers in code
        for m in forbidden_re.finditer(code):
            findings.append(("FAIL", rel, line_of(code, m.start()), "forbidden identifier in code: " + m.group(1)))
        for m in forbidden_re.finditer(comment_text(raw)):
            mentions.append((rel, line_of(raw, m.start()), m.group(1)))

        # B. includes
        for m in INCLUDE_RE.finditer(raw):
            kind, target = m.group(1), m.group(2)
            line = line_of(raw, m.start())
            if kind == "<":
                findings.append(("FAIL", rel, line, "standard-library include <%s> (not allowed in M1)" % target))
                continue
            resolved = os.path.normpath(os.path.join(os.path.dirname(path), target))
            if not os.path.isfile(resolved):
                findings.append(("FAIL", rel, line, "include does not resolve: " + target))
            elif not resolved.startswith(os.path.join(root, "Include") + os.sep):
                findings.append(("FAIL", rel, line, "include outside the project Include folder: " + target))
        if re.search(r"^\s*#\s*import\b", code, re.M):
            findings.append(("FAIL", rel, 0, "#import (DLL / external library) present"))

        # C. preprocessor
        for m in re.finditer(r"^\s*#\s*(ifdef|ifndef|if|elif)\b\s*([^\n]*)", code, re.M):
            directive, argument = m.group(1), m.group(2).strip()
            line = line_of(code, m.start())
            if directive == "ifndef" and argument.endswith("_MQH"):
                continue
            findings.append(("FAIL", rel, line, "conditional compilation other than an include guard: #%s %s" % (directive, argument)))
        for m in re.finditer(r"^\s*#\s*define\s+([A-Za-z_]\w*)(\()?([^\n]*)", raw, re.M):
            name, function_like, body = m.group(1), m.group(2), m.group(3)
            line = line_of(raw, m.start())
            if function_like:
                findings.append(("FAIL", rel, line, "function-like macro (could hide a call): " + name))
            if forbidden_re.search(strip_comments_and_strings(body)):
                findings.append(("FAIL", rel, line, "macro body references a forbidden identifier: " + name))
            if CALL_RE.search(strip_comments_and_strings(body)):
                findings.append(("FAIL", rel, line, "macro body contains a call: " + name))

        # D/E. call whitelist and terminal API call sites
        # (preprocessor lines are blanked here: they are checked in step C, and
        #  "#define NAME (-1)" must not be mistaken for a call to NAME)
        allowed = ALLOWED_PRODUCTION | (ALLOWED_TEST_ONLY if is_test else set())
        classes = class_ranges(code)
        code_without_pp = re.sub(r"^[ \t]*#[^\n]*", lambda pp: " " * len(pp.group(0)), code, flags=re.M)
        for m in CALL_RE.finditer(code_without_pp):
            name = m.group(1)
            if name in KEYWORDS or name in defined:
                continue
            line = line_of(code, m.start())
            if name not in allowed:
                findings.append(("FAIL", rel, line, "call to a function outside the read-only whitelist: " + name))
                continue
            if name in TERMINAL_APIS:
                owner = "-"
                for cls, start, end in classes:
                    if start <= m.start() <= end:
                        owner = cls
                api_sites.append((rel, line, name, owner))
                if name in DATA_SOURCE_ONLY and owner != "CTerminalAccountDataSource":
                    findings.append(("FAIL", rel, line, "%s called outside CTerminalAccountDataSource" % name))

        # F. dynamic allocation / loops
        for m in re.finditer(r"\b(new|delete)\b", code):
            findings.append(("FAIL", rel, line_of(code, m.start()), "dynamic allocation keyword: " + m.group(1)))
        for m in re.finditer(r"\bwhile\s*\(", code):
            findings.append(("REVIEW", rel, line_of(code, m.start()), "while-loop (checked manually for busy waiting)"))

    return production, tests, findings, api_sites, mentions


def render(root, production, tests, findings, api_sites, mentions):
    failures = [f for f in findings if f[0] == "FAIL"]
    reviews = [f for f in findings if f[0] == "REVIEW"]
    lines = []
    lines.append("# Read-only audit output (generated)")
    lines.append("")
    lines.append("- Generated: %s UTC by `Tools/readonly_audit.py`" % datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S"))
    lines.append("- Result: **%s** (%d failure(s), %d item(s) for manual review)" %
                 ("PASS" if not failures else "FAIL", len(failures), len(reviews)))
    lines.append("")
    lines.append("## Files audited")
    lines.append("")
    for path in production:
        lines.append("- production: `%s`" % os.path.relpath(path, root))
    for path in tests:
        lines.append("- test harness: `%s`" % os.path.relpath(path, root))
    lines.append("")
    lines.append("## Findings")
    lines.append("")
    if not findings:
        lines.append("None.")
    else:
        lines.append("| Severity | File | Line | Finding |")
        lines.append("|---|---|---|---|")
        for severity, rel, line, message in findings:
            lines.append("| %s | `%s` | %d | %s |" % (severity, rel, line, message))
    lines.append("")
    lines.append("## Terminal / account API call sites")
    lines.append("")
    lines.append("| File | Line | API | Enclosing class |")
    lines.append("|---|---|---|---|")
    for rel, line, name, owner in api_sites:
        lines.append("| `%s` | %d | `%s` | %s |" % (rel, line, name, owner))
    lines.append("")
    lines.append("## Forbidden names mentioned only in comments or string literals (informational)")
    lines.append("")
    if not mentions:
        lines.append("None.")
    else:
        for rel, line, word in mentions:
            lines.append("- `%s:%d` mentions `%s`" % (rel, line, word))
    lines.append("")
    lines.append("## Whitelist used")
    lines.append("")
    lines.append("- production: " + ", ".join("`%s`" % n for n in sorted(ALLOWED_PRODUCTION)))
    lines.append("- test harness only: " + ", ".join("`%s`" % n for n in sorted(ALLOWED_TEST_ONLY)))
    lines.append("- forbidden identifiers checked: %d" % len(FORBIDDEN))
    lines.append("")
    return "\n".join(lines), not failures


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    default_root = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    parser.add_argument("project_dir", nargs="?", default=default_root)
    parser.add_argument("--output", help="write the markdown report to this file")
    args = parser.parse_args()
    root = os.path.abspath(args.project_dir)
    report, passed = render(root, *audit(root))
    if args.output:
        with open(args.output, "w", encoding="utf-8") as handle:
            handle.write(report + "\n")
    print(report)
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
