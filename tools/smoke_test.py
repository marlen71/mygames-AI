#!/usr/bin/env python3
"""smoke_test.py — прогон Warcraft Online через lupa + моки GMod API.

Использование:
    python3 tools/smoke_test.py            # server + client
    python3 tools/smoke_test.py server     # только серверный сценарий
    python3 tools/smoke_test.py client     # только клиентский сценарий

Сценарии: tools/test/scenario_server.lua, tools/test/scenario_client.lua.
"""

import json
import os
import sqlite3
import sys
import time

try:
    from lupa import luajit21 as lupa  # LuaJIT — ближе всего к GMod (Lua 5.1)
except ImportError:
    from lupa import lua51 as lupa

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GM_ROOT = os.path.join(ROOT, "gamemodes", "warcraftonline", "gamemode")
TOOLS = os.path.join(ROOT, "tools")

assert os.path.isfile(os.path.join(GM_ROOT, "shared.lua")), GM_ROOT


def make_py(lua, db_path):
    conn = sqlite3.connect(db_path)
    conn.isolation_level = None

    def file_find(pattern):
        # pattern: "dir/*" — возвращаем "f1\1f2\1...\2d1\1d2..."
        base = pattern
        if base.endswith("/*"):
            base = base[:-2]
        elif base.endswith("*"):
            base = base[:-1]
        if not os.path.isabs(base):
            base = os.path.join(ROOT, base)
        files, dirs = [], []
        if os.path.isdir(base):
            for name in sorted(os.listdir(base)):
                full = os.path.join(base, name)
                if os.path.isdir(full):
                    dirs.append(name)
                else:
                    files.append(name)
        return "\1".join(files) + "\2" + "\1".join(dirs)

    def file_exists(path):
        return any(os.path.isfile(c) for c in (os.path.join(ROOT, path), path, os.path.join(GM_ROOT, path)))

    def file_read(path):
        candidates = [os.path.join(ROOT, path), path, os.path.join(GM_ROOT, path)]
        for cand in candidates:
            if os.path.isfile(cand):
                with open(cand, "r", encoding="utf-8", errors="replace") as fh:
                    return fh.read()
        return None

    def sql_query(text):
        try:
            cur = conn.execute(text)
            if text.lstrip().upper().startswith("SELECT") or text.lstrip().upper().startswith("PRAGMA"):
                rows_raw = cur.fetchall()
                if not rows_raw:
                    return json.dumps({"ok": True, "rows": None})
                cols = [d[0] for d in cur.description]
                rows = []
                for row in rows_raw:
                    rows.append({c: ("NULL" if v is None else str(v)) for c, v in zip(cols, row)})
                return json.dumps({"ok": True, "rows": rows})
            conn.commit()
            return json.dumps({"ok": True, "rows": None})
        except Exception as exc:  # noqa: BLE001
            return json.dumps({"ok": False, "err": str(exc), "rows": None})

    def now():
        return time.time()

    py = lua.table_from({
        "file_find": file_find,
        "file_exists": file_exists,
        "file_read": file_read,
        "sql_query": sql_query,
        "now": now,
    })
    return py


def run_realm(realm):
    print(f"\n=== SMOKE TEST: {realm.upper()} ===")
    lua = lupa.LuaRuntime(unpack_returned_tuples=False)
    g = lua.globals()
    g.py = make_py(lua, f"/tmp/wo_smoke_{realm}.sqlite")
    if os.path.exists(f"/tmp/wo_smoke_{realm}.sqlite"):
        os.remove(f"/tmp/wo_smoke_{realm}.sqlite")
        g.py = make_py(lua, f"/tmp/wo_smoke_{realm}.sqlite")
    g.MOCK_REALM = realm

    with open(os.path.join(TOOLS, "test", "mock_gmod.lua"), encoding="utf-8") as fh:
        lua.execute(fh.read())

    g.MOCK.realm = realm
    g.SERVER = realm == "server"
    g.CLIENT = realm == "client"

    scenario_path = os.path.join(TOOLS, "test", f"scenario_{realm}.lua")
    with open(scenario_path, encoding="utf-8") as fh:
        src = fh.read()

    try:
        lua.execute(src)
    except Exception as exc:
        print(f"\n!!! {realm} FAILED:\n{exc}")
        return False

    print(f"\n=== {realm.upper()} OK ===")
    return True


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    ok = True
    if which in ("all", "server"):
        ok = run_realm("server") and ok
    if which in ("all", "client"):
        ok = run_realm("client") and ok
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
