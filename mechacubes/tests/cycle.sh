#!/bin/bash
# patch -> compile every script -> run the join test on every engine
set -e
cd "$(dirname "$0")/.."
ORIG=${ORIG:-/root/.claude/uploads/27bf8ab7-bc79-5902-9b1a-dd42fdb3c078/2347a6c2-Place1.rbxlsss.rbxl}
OUT=${OUT:-/tmp/claude-0/-home-user-School-is-good/27bf8ab7-bc79-5902-9b1a-dd42fdb3c078/scratchpad/cycle}
LUAUC=${LUAUC:-/tmp/claude-0/-home-user-School-is-good/27bf8ab7-bc79-5902-9b1a-dd42fdb3c078/scratchpad/luau/luau-compile}
mkdir -p $OUT
python3 tools/patch.py $ORIG MechaCubes_fixed.rbxl | tail -3
rm -rf $OUT/src && python3 ../casino/tools/dump.py MechaCubes_fixed.rbxl $OUT/src > /dev/null
bad=0
for f in $OUT/src/*.lua; do
  if ! python3 -c "
import sys
from lupa import lua51
L = lua51.LuaRuntime()
e = L.eval('function(s) local f, e = loadstring(s) return e end')(open(sys.argv[1]).read())
sys.exit(1 if e else 0)" "$f"; then echo "LUA 5.1 SYNTAX ERROR: $f"; bad=1; fi
done
[ $bad = 0 ] && echo "all scripts compile (Lua 5.1)"
rm -rf tests/.cache
for cfg in ${CONFIGS:-"v2018 ok" "v2018 unpublished" "v270 unpublished" "v270 ok" "v227 unpublished" "v227 hang"}; do
  set -- $cfg
  timeout 900 python3 tests/run.py MechaCubes_fixed.rbxl --api $1 --datastore $2 --seconds ${SECONDS_:-40} > $OUT/r_$1_$2.txt 2>&1 || true
  tail -1 $OUT/r_$1_$2.txt
done
