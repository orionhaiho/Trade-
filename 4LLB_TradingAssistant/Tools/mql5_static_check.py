#!/usr/bin/env python3
"""
Static checks for the 4LLB MQL5 sources (no MetaEditor available here).

It is NOT a compiler. It catches the classes of mistakes a compiler would
reject and that are easy to make without one, plus project safety rules:

  1. balanced (), [], {} per file (comments/strings removed)
  2. every #include resolves to a file
  3. member access / method call on a variable whose type is a known
     struct/class must name an existing field/method (typo detection)
  4. every called LLB_* function / macro is defined
  5. string literals are ASCII only (MetaEditor encoding safety)
  6. safety rules: OrderSend/OrderCheck only in LLB_Execution.mqh,
     WebRequest only in LLB_Telegram.mqh, no bot token literal,
     the Telegram URL variable never reaches a log/print call
  7. lists every non-project function called, for manual API review

Usage: python3 mql5_static_check.py <path-to-MQL5-folder>
Exit code 0 = no errors (warnings may still be printed).
"""
import os
import re
import sys

KEYWORDS = {
    "if", "for", "while", "switch", "return", "sizeof", "case", "else", "do",
    "new", "delete", "operator", "template", "typename", "void", "string",
    "int", "uint", "long", "ulong", "double", "float", "bool", "char", "uchar",
    "short", "ushort", "datetime", "color", "this", "const", "static",
}

# fields of MQL5 built-in structures used by the project
BUILTIN_STRUCTS = {
    "MqlTick": "time bid ask last volume time_msc flags volume_real",
    "MqlRates": "time open high low close tick_volume spread real_volume",
    "MqlTradeRequest": "action magic order symbol volume price stoplimit sl tp deviation type "
                       "type_filling type_time expiration comment position position_by",
    "MqlTradeResult": "retcode deal order volume price bid ask comment request_id retcode_external",
    "MqlTradeCheckResult": "retcode balance equity profit margin margin_free margin_level comment",
    "MqlDateTime": "year mon day hour min sec day_of_week day_of_year",
    "MqlTradeTransaction": "deal order symbol type order_type order_state deal_type time_type "
                           "time_expiration price price_trigger price_sl price_tp volume position position_by",
}


def strip_code(text):
    """Remove comments; blank out string and char literal contents (keep length)."""
    out = []
    i, n = 0, len(text)
    strings = []  # (start, end, content)
    while i < n:
        c = text[i]
        if c == '/' and i + 1 < n and text[i + 1] == '/':
            j = text.find('\n', i)
            j = n if j < 0 else j
            out.append(' ' * (j - i))
            i = j
        elif c == '/' and i + 1 < n and text[i + 1] == '*':
            j = text.find('*/', i + 2)
            j = n if j < 0 else j + 2
            out.append(''.join(ch if ch == '\n' else ' ' for ch in text[i:j]))
            i = j
        elif c == '"' or c == "'":
            q = c
            j = i + 1
            while j < n and text[j] != q:
                if text[j] == '\\':
                    j += 1
                j += 1
            content = text[i + 1:j]
            if q == '"':
                strings.append((i, j, content))
            out.append(q + ' ' * (j - i - 1) + q)
            i = j + 1
        else:
            out.append(c)
            i += 1
    return ''.join(out), strings


def line_of(text, pos):
    return text.count('\n', 0, pos) + 1


def match_brace(s, pos, open_ch, close_ch):
    depth = 0
    for k in range(pos, len(s)):
        if s[k] == open_ch:
            depth += 1
        elif s[k] == close_ch:
            depth -= 1
            if depth == 0:
                return k
    return -1


DECL_RE = r'(?:const\s+)?({types})\s*[*&]?\s*(\w+)\s*(?:\[[^\]]*\])?\s*(?=[;,)=\[]|$)'


class Model:
    def __init__(self):
        self.structs = {}   # name -> {member: type}
        self.classes = {}   # name -> {member: type}
        self.bases = {}     # class -> base
        self.class_spans = []  # (file, start, end, name)
        self.functions = set()
        self.macros = set()
        self.globals = {}   # var -> type

    def members(self, typ):
        seen = set()
        res = {}
        t = typ
        while t and t not in seen:
            seen.add(t)
            res.update(self.structs.get(t, {}))
            res.update(self.classes.get(t, {}))
            t = self.bases.get(t)
        return res


def parse_definitions(model, files):
    for path, (raw, code, _) in files.items():
        for m in re.finditer(r'#define\s+(\w+)', raw):
            model.macros.add(m.group(1))
        for kind in ("struct", "class"):
            for m in re.finditer(r'\b' + kind + r'\s+(\w+)\s*(?::\s*public\s+(\w+))?\s*\{', code):
                name = m.group(1)
                start = m.end() - 1
                end = match_brace(code, start, '{', '}')
                body = code[start + 1:end]
                if m.group(2):
                    model.bases[name] = m.group(2)
                model.class_spans.append((path, start, end, name))
                mem = {}
                # remove nested method bodies to keep only declarations
                flat = []
                depth = 0
                for ch in body:
                    if ch == '{':
                        depth += 1
                        if depth == 1:
                            flat.append(';')
                        continue
                    if ch == '}':
                        depth -= 1
                        continue
                    if depth == 0:
                        flat.append(ch)
                flat = ''.join(flat)
                for d in re.finditer(r'([A-Za-z_]\w*)\s*[*&]?\s*([A-Za-z_]\w*)\s*(\[[^\]]*\])?\s*(;|\()', flat):
                    typ, nm = d.group(1), d.group(2)
                    if typ in ("return", "public", "private", "protected", "virtual", "else"):
                        continue
                    mem[nm] = typ
                for d in re.finditer(r'virtual\s+([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*\(', flat):
                    mem[d.group(2)] = d.group(1)
                # constructors/destructors
                mem[name] = name
                target = model.structs if kind == "struct" else model.classes
                target[name] = mem
        # out-of-class method definitions Type Class::Method(
        for m in re.finditer(r'(\w+)\s+(\w+)::(\w+)\s*\(', code):
            model.classes.setdefault(m.group(2), {})[m.group(3)] = m.group(1)
    for name, fields in BUILTIN_STRUCTS.items():
        model.structs[name] = {f: "?" for f in fields.split()}
    known_types = set(model.structs) | set(model.classes)
    for path, (raw, code, _) in files.items():
        # global functions: at brace depth 0
        depth = 0
        for k, ch in enumerate(code):
            if ch == '{':
                if depth == 0:
                    sig_start = max(code.rfind(';', 0, k), code.rfind('}', 0, k), code.rfind('#', 0, k))
                    sig = code[sig_start + 1:k]
                    fm = re.search(r'(\w+)\s*\([^()]*(\([^()]*\)[^()]*)*\)\s*(const)?\s*$', sig.strip())
                    if fm and not re.search(r'\b(struct|class|enum)\b', sig):
                        model.functions.add(fm.group(1))
                depth += 1
            elif ch == '}':
                depth -= 1
        # global variables of known types
        for m in re.finditer(r'^(\w+)\s+(\w+)\s*;', code, re.M):
            if m.group(1) in known_types:
                model.globals[m.group(2)] = m.group(1)
    return known_types


def enclosing_class(model, path, pos):
    best = None
    for (p, s, e, name) in model.class_spans:
        if p == path and s < pos < e:
            if best is None or s > best[0]:
                best = (s, name)
    if best:
        return best[1]
    return None


def function_start(code, pos):
    """Start of the signature of the innermost function/method around pos."""
    depth_stack = []
    for k in range(0, pos):
        ch = code[k]
        if ch == '{':
            depth_stack.append(k)
        elif ch == '}':
            if depth_stack:
                depth_stack.pop()
    # innermost block whose signature ends with ')' (a function body)
    for open_pos in reversed(depth_stack):
        before = code[:open_pos].rstrip()
        if before.endswith(')') or before.endswith('const'):
            sig_start = max(code.rfind(';', 0, open_pos), code.rfind('}', 0, open_pos), code.rfind('{', 0, open_pos))
            # skip over a nested call's parentheses in the signature
            return sig_start + 1
    return 0


def resolve_var(model, known_types, path, code, pos, name):
    start = function_start(code, pos)
    region = code[start:pos]
    types_alt = '|'.join(sorted(known_types, key=len, reverse=True))
    last = None
    for m in re.finditer(r'\b(' + types_alt + r')\s*[*&]?\s*' + re.escape(name) + r'\b', region):
        last = m.group(1)
    if last:
        return last
    cls = enclosing_class(model, path, pos)
    if cls:
        mem = model.members(cls)
        if name in mem and mem[name] in known_types:
            return mem[name]
    # out-of-class method body: Type Class::Method(
    hdr = re.findall(r'\w+\s+(\w+)::\w+\s*\(', code[start:pos])
    if hdr:
        mem = model.members(hdr[-1])
        if name in mem and mem[name] in known_types:
            return mem[name]
    if name in model.globals:
        return model.globals[name]
    return None


def check_chains(model, known_types, path, code, errors, shown=None):
    shown = shown or path
    ident = re.compile(r'[A-Za-z_]\w*')
    k = 0
    n = len(code)
    while k < n:
        m = ident.match(code, k)
        if not m or (k > 0 and (code[k - 1].isalnum() or code[k - 1] in '_.')):
            k += 1
            continue
        name = m.group(0)
        j = m.end()
        # skip index
        while j < n and code[j] == '[':
            e = match_brace(code, j, '[', ']')
            if e < 0:
                break
            j = e + 1
        if j < n and code[j] == '.' and j + 1 < n and (code[j + 1].isalpha() or code[j + 1] == '_'):
            typ = resolve_var(model, known_types, path, code, k, name)
            while typ is not None and j < n and code[j] == '.':
                mm = ident.match(code, j + 1)
                if not mm:
                    break
                member = mm.group(0)
                mem = model.members(typ)
                if member not in mem:
                    errors.append(f"{shown}:{line_of(code, j)}: '{name}...{member}': '{member}' is not a member of {typ}")
                    break
                j = mm.end()
                while j < n and code[j] == '[':
                    e = match_brace(code, j, '[', ']')
                    if e < 0:
                        break
                    j = e + 1
                if j < n and code[j] == '(':
                    break
                nxt = mem.get(member)
                typ = nxt if nxt in known_types else None
        k = m.end()



def split_args(s):
    """split a parameter/argument list on top-level commas"""
    parts, depth, cur = [], 0, ''
    for ch in s:
        if ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
        if ch == ',' and depth == 0:
            parts.append(cur)
            cur = ''
        else:
            cur += ch
    if cur.strip():
        parts.append(cur)
    return [x.strip() for x in parts if x.strip() and x.strip() != 'void']


def collect_signatures(files, model):
    """name -> list of (min,max) for global functions; (class,name) -> list for methods"""
    sigs = {}
    for path, (raw, code, _) in files.items():
        for m in re.finditer(r'\b([A-Za-z_]\w*)\s+(?:(\w+)::)?([A-Za-z_]\w*)\s*\(', code):
            ret, cls, name = m.group(1), m.group(2), m.group(3)
            if ret in ('return', 'new', 'delete', 'else', 'case') or name in KEYWORDS:
                continue
            start = m.end() - 1
            end = match_brace(code, start, '(', ')')
            if end < 0:
                continue
            after = code[end + 1:end + 40].lstrip()
            if not (after.startswith('{') or after.startswith(';') or after.startswith('const') or after.startswith('=0')):
                continue
            params = split_args(code[start + 1:end])
            if any(not re.search(r'[A-Za-z_]\w*\s*[*&]?\s*[A-Za-z_]\w*(\s*\[\s*\])?(\s*=.*)?$', x) for x in params):
                continue   # not a declaration (a call with expressions)
            mx = len(params)
            mn = len([x for x in params if '=' not in x])
            owner = cls or enclosing_class(model, path, m.start())
            key = (owner, name) if owner else (None, name)
            sigs.setdefault(key, set()).add((mn, mx))
    return sigs


def check_arg_counts(files, model, known_types, sigs, errors, root):
    ident = re.compile(r'[A-Za-z_]\w*')
    for path, (raw, code, _) in files.items():
        rel = os.path.relpath(path, root)
        for m in re.finditer(r'(?:([A-Za-z_]\w*)(?:\[[^\]]*\])?\s*\.\s*)?([A-Za-z_]\w*)\s*\(', code):
            obj, name = m.group(1), m.group(2)
            if name in KEYWORDS:
                continue
            start = m.end() - 1
            end = match_brace(code, start, '(', ')')
            if end < 0:
                continue
            # skip definitions/declarations
            before = code[max(0, m.start() - 60):m.start()]
            if re.search(r'[A-Za-z_]\w*\s+(\w+::)?$', before.rstrip()) and not re.search(r'(return|else|=|\(|,|!|&&|\|\|)\s*$', before.rstrip()):
                if not obj:
                    continue
            nargs = len(split_args(code[start + 1:end]))
            cands = None
            if obj:
                typ = resolve_var(model, known_types, path, code, m.start(), obj)
                if typ:
                    t = typ
                    seen = set()
                    while t and t not in seen and cands is None:
                        seen.add(t)
                        cands = sigs.get((t, name))
                        t = model.bases.get(t)
            else:
                if m.start() > 0 and code[m.start() - 1] == '.':
                    continue
                cls = enclosing_class(model, path, m.start())
                hdr = re.findall(r'\w+\s+(\w+)::\w+\s*\(', code[function_start(code, m.start()):m.start()])
                cls = cls or (hdr[-1] if hdr else None)
                t = cls
                seen = set()
                while t and t not in seen and cands is None:
                    seen.add(t)
                    cands = sigs.get((t, name))
                    t = model.bases.get(t)
                if cands is None:
                    cands = sigs.get((None, name))
            if not cands:
                continue
            if not any(mn <= nargs <= mx for (mn, mx) in cands):
                errors.append(f"{rel}:{line_of(code, m.start())}: {('%s.' % obj) if obj else ''}{name}() called with {nargs} argument(s), expected {sorted(cands)}")


MQL5_WORDS = set("""
input sinput group const static virtual public private protected class struct enum return if else for while do
switch case default break continue new delete this true false NULL sizeof operator void int uint long ulong double
float string bool datetime color char uchar short ushort property define include ifndef endif define copyright
version description C D _Symbol _Point _Digits _Period _LastError
""".split())


def check_identifiers(files, model, known_types, builtin_funcs, errors, root):
    declared = set(known_types) | set(model.functions) | set(model.macros) | set(model.globals)
    for mem in list(model.classes.values()) + list(model.structs.values()):
        declared |= set(mem)
    for path, (raw, code, _) in files.items():
        for m in re.finditer(r'\benum\s+\w+\s*\{([^}]*)\}', code):
            for item in m.group(1).split(','):
                nm = item.split('=')[0].strip()
                if nm:
                    declared.add(nm)
        # every "Type name" / "Type *name" / "Type &name[]" declaration anywhere
        for m in re.finditer(r'\b([A-Za-z_]\w*)\s*[*&]?\s+[*&]?\s*([A-Za-z_]\w*)\s*(?=[;,)=\[:]|\s*$)', code, re.M):
            declared.add(m.group(2))
        # comma separated declarations: "double a=0.0,b=1.0,c;"  "string lines[],back;"
        type_alt = '|'.join(sorted(set(known_types) | {'int', 'uint', 'long', 'ulong', 'double', 'float', 'string', 'bool',
                                                      'datetime', 'color', 'char', 'uchar', 'short', 'ushort'}, key=len, reverse=True))
        for m in re.finditer(r'(?:(?<=[;{}(\n])|^)\s*(?:const\s+|static\s+)?(?:' + type_alt + r')\s+([^;(){}]*);', code):
            for part in split_args(m.group(1)):
                nm = re.match(r'[*&]?\s*([A-Za-z_]\w*)', part)
                if nm:
                    declared.add(nm.group(1))
        for m in re.finditer(r'#define\s+\w+\(([^)]*)\)', raw):
            for a in m.group(1).split(','):
                declared.add(a.strip())
    unknown = {}
    for path, (raw, code, _) in files.items():
        body = re.sub(r'#\s*(include|property|define|ifndef|endif)[^\n]*', ' ', code)
        for m in re.finditer(r'(?<![\w.])([A-Za-z_]\w*)\b', body):
            nm = m.group(1)
            if nm in declared or nm in MQL5_WORDS or nm in KEYWORDS or nm in builtin_funcs:
                continue
            if re.fullmatch(r'[A-Z][A-Z0-9_]+', nm) or nm.startswith('clr') or nm.startswith('ENUM_') or nm.startswith('Mql'):
                continue   # MQL5 constants / enums / types (reviewed manually)
            unknown.setdefault(nm, []).append(f"{os.path.relpath(path, root)}:{line_of(code, m.start())}")
    for nm, where in sorted(unknown.items()):
        errors.append(f"undeclared identifier '{nm}' at {', '.join(where[:3])}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    root = sys.argv[1]
    include_root = os.path.join(root, "Include")
    paths = []
    for d, _, fs in os.walk(root):
        for f in fs:
            if f.endswith((".mqh", ".mq5")):
                paths.append(os.path.join(d, f))
    paths.sort()
    files = {}
    errors, warnings = [], []
    for p in paths:
        raw = open(p, encoding="utf-8").read()
        code, strings = strip_code(raw)
        files[p] = (raw, code, strings)
        rel = os.path.relpath(p, root)
        # 1. balance
        for o, c in ("()", "[]", "{}"):
            if code.count(o) != code.count(c):
                errors.append(f"{rel}: unbalanced {o}{c}: {code.count(o)} vs {code.count(c)}")
        # 2. includes
        for m in re.finditer(r'#include\s+([<"])([^>"]+)[>"]', raw):
            target = m.group(2).replace('\\', os.sep)
            base = include_root if m.group(1) == '<' else os.path.dirname(p)
            if not os.path.exists(os.path.join(base, target)):
                errors.append(f"{rel}: include not found: {m.group(2)}")
        # 5. ASCII string literals
        for (s, e, content) in strings:
            if any(ord(ch) > 127 for ch in content):
                errors.append(f"{rel}:{line_of(raw, s)}: non-ASCII characters in a string literal")
        # 6. safety rules
        base = os.path.basename(p)
        for fn, allowed in (("OrderSend", "LLB_Execution.mqh"), ("OrderCheck", "LLB_Execution.mqh"),
                            ("WebRequest", "LLB_Telegram.mqh")):
            for m in re.finditer(r'\b' + fn + r'\s*\(', code):
                if base != allowed:
                    errors.append(f"{rel}:{line_of(code, m.start())}: {fn} outside {allowed}")
        if re.search(r'\d{6,12}:[A-Za-z0-9_-]{30,}', raw):
            errors.append(f"{rel}: something that looks like a bot token literal")
        for m in re.finditer(r'(Print|PrintFormat|Alert|Comment|g_llbLog\.(?:Error|Warn|Info|Debug|Write))\s*\(([^;]*)\)\s*;', code):
            if re.search(r'\burl\b|m_token', m.group(2)):
                errors.append(f"{rel}:{line_of(code, m.start())}: url/token passed to a log call")

    model = Model()
    known_types = parse_definitions(model, files)
    for p, (raw, code, _) in files.items():
        check_chains(model, known_types, p, code, errors, os.path.relpath(p, root))

    # 4. LLB_ functions / macros defined
    builtin_calls = {}
    for p, (raw, code, _) in files.items():
        for m in re.finditer(r'(?<![\w.])([A-Za-z_]\w*)\s*\(', code):
            nm = m.group(1)
            if nm in KEYWORDS or nm in known_types or nm in model.macros:
                continue
            if nm.startswith("LLB_"):
                if nm not in model.functions:
                    errors.append(f"{os.path.relpath(p, root)}:{line_of(code, m.start())}: call to undefined {nm}")
                continue
            if nm in model.functions:
                continue
            if any(nm in mem for mem in model.classes.values()) or any(nm in mem for mem in model.structs.values()):
                continue
            builtin_calls.setdefault(nm, set()).add(os.path.basename(p))

    sigs = collect_signatures(files, model)
    check_arg_counts(files, model, known_types, sigs, errors, root)
    check_identifiers(files, model, known_types, set(builtin_calls), errors, root)
    consts = set()
    for p, (raw, code, _) in files.items():
        for m in re.finditer(r'(?<![\w.])([A-Z][A-Z0-9_]{2,})\b', re.sub(r'#\s*(include|property|define|ifndef|endif)[^\n]*', ' ', code)):
            if m.group(1) not in model.macros:
                consts.add(m.group(1))
    print("== MQL5 constants used (review) ==")
    print("  " + " ".join(sorted(c for c in consts if not c.startswith('LLB_'))))
    print("== MQL5 built-in / external functions called (review against the MQL5 reference) ==")
    for nm in sorted(builtin_calls):
        print(f"  {nm}")
    print(f"\nfiles: {len(files)}  structs: {len(model.structs)}  classes: {len(model.classes)}  functions: {len(model.functions)}")
    for w in warnings:
        print("WARN ", w)
    for e in errors:
        print("ERROR", e)
    print(f"\n{len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
