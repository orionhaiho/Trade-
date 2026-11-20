#!/usr/bin/env python3
"""
Negative-control self-test for Tools/readonly_audit.py.

Copies the project to a temporary folder, injects ONE read-only violation at a
time and checks that the audit then FAILS. A violation the audit does not
detect is reported as MISSED. The original sources are never modified.

Usage:  python3 -I Tools/readonly_audit_selftest.py [project_dir]
Exit code 0 = every injected violation was detected.
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
AUDIT = os.path.join(HERE, "readonly_audit.py")

# (id, file, anchor text, text inserted after the anchor, description)
CORE = "Include/Core/CoreEngine.mqh"
ENGINE = "Include/Core/AccountEngine.mqh"
MAIN = "RiskManagement.mq5"
NOTIFIER = "Include/Notify/TelegramNotifier.mqh"
HOOK_REFRESH = "      RunCycle();\n"
HOOK_INCLUDE = '#include "Include/Core/CoreEngine.mqh"\n'

INJECTIONS = [
    ("V01", CORE, HOOK_REFRESH, "      MqlTradeRequest request; MqlTradeResult result; OrderSend(request,result);\n", "direct OrderSend call"),
    ("V02", CORE, HOOK_REFRESH, "      OrderSendAsync(m_req,m_res);\n", "OrderSendAsync call"),
    ("V03", MAIN, HOOK_INCLUDE, "#include <Trade\\Trade.mqh>\n", "standard-library trade include"),
    ("V04", MAIN, HOOK_INCLUDE, "CTrade g_trade;\n", "CTrade object"),
    ("V05", CORE, HOOK_REFRESH, "      m_trade.PositionClose(0);\n", "PositionClose through a member"),
    ("V06", MAIN, HOOK_INCLUDE, "#define SAFE_CALL OrderSend\n", "macro hiding a trade function"),
    ("V07", MAIN, HOOK_INCLUDE, "#define WRAP(x) x\n", "function-like macro"),
    ("V08", MAIN, HOOK_INCLUDE, "#ifdef ENABLE_TRADING\n#endif\n", "conditional compilation branch"),
    ("V09", CORE, HOOK_REFRESH, "      double hidden=AccountInfoDouble(ACCOUNT_EQUITY);\n", "account API outside the data source"),
    ("V10", CORE, HOOK_REFRESH, "      Sleep(100);\n", "Sleep (blocking)"),
    ("V11", CORE, HOOK_REFRESH, "      int handle=FileOpen(\"x.csv\",0);\n", "file access"),
    ("V12", CORE, HOOK_REFRESH, "      Comment(\"status\");\n", "chart UI output"),
    ("V13", CORE, HOOK_REFRESH, "      SomeUnknownFunction();\n", "call outside the whitelist"),
    ("V14", MAIN, HOOK_INCLUDE, "#import \"user32.dll\"\n#import\n", "DLL import"),
    ("V15", CORE, HOOK_REFRESH, "      CLogger *leak=new CLogger();\n", "dynamic allocation"),
    ("V16", ENGINE, "class CAccountEngine\n", "void HiddenTrade() { PositionModify(1,0,0); }\n", "trade call in an unused helper"),
    ("V17", CORE, HOOK_REFRESH, "      WebRequest(\"GET\",\"https://example.invalid\",\"\",0,m_d,m_r,m_h);\n", "network request outside the transport"),
    ("V18", NOTIFIER, "#define RM_TG_API_URL            \"https://api.telegram.org/bot\"\n",
     "#define RM_EXFIL_URL \"https://example.invalid/collect\"\n", "URL to another host"),
    ("V19", NOTIFIER, "   void              ResetQueue()\n",
     "   void              Leak() { char d[]; char r[]; string h; WebRequest(\"POST\",RM_TG_API_URL,\"\",1000,d,r,h); }\n",
     "WebRequest in the notifier instead of the transport"),
    ("V20", NOTIFIER, "   void              ResetQueue()\n", "   void              Notify2() { SendNotification(\"x\"); }\n", "push notification API"),
]


def run_audit(root):
    completed = subprocess.run([sys.executable, "-I", AUDIT, root],
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
    return completed.returncode, completed.stdout


def main():
    project = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, ".."))
    code, _ = run_audit(project)
    print("baseline audit on the real sources: %s" % ("PASS" if code == 0 else "FAIL"))
    missed = 0
    for injection_id, rel, anchor, text, description in INJECTIONS:
        with tempfile.TemporaryDirectory() as temp:
            root = os.path.join(temp, "RiskManagement")
            shutil.copytree(project, root, ignore=shutil.ignore_patterns("build*", "results", "Documentation"))
            path = os.path.join(root, rel)
            with open(path, encoding="utf-8-sig") as handle:
                source = handle.read()
            if anchor not in source:
                print("%s NOT APPLIED (anchor missing) - %s" % (injection_id, description))
                missed += 1
                continue
            with open(path, "w", encoding="utf-8") as handle:
                handle.write(source.replace(anchor, anchor + text, 1))
            code, output = run_audit(root)
            if code != 0:
                reasons = [line.split("|")[4].strip() for line in output.splitlines() if line.startswith("| FAIL")]
                print("%s DETECTED - %s -> %s" % (injection_id, description, "; ".join(reasons[:3])))
            else:
                print("%s MISSED - %s" % (injection_id, description))
                missed += 1
    print("missed: %d of %d" % (missed, len(INJECTIONS)))
    return 0 if missed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
