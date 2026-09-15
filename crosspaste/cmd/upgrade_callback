#!/bin/sh
# 升级应用文件后执行（幂等）：停旧进程 → 备份数据库 → 用新二进制跑迁移 → 修正属主。
# 数据（DB/媒体）全部在 var/，升级本身不动数据；迁移由后端 --migrate 幂等完成。
set -u

APP=crosspaste
APPDEST="${TRIM_APPDEST:-/var/apps/crosspaste/target}"
PKGVAR="${TRIM_PKGVAR:-/var/apps/crosspaste/var}"
BINDIR="$APPDEST/server/bin"
OLDVER="${TRIM_OLD_APPVER:-unknown}"
NEWVER="${TRIM_APPVER:-unknown}"

PIDFILE="$PKGVAR/crosspaste.pid"

log() { echo "$APP: $*"; }
fail() {
  echo "$APP: $*" >&2
  [ -n "${TRIM_TEMP_LOGFILE:-}" ] && echo "$APP upgrade $OLDVER->$NEWVER: $*" >>"$TRIM_TEMP_LOGFILE"
  exit 1
}

# 1) 停掉可能残留的旧版本进程（避免旧二进制占着端口 / 活跃 WAL）
if [ -s "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  kill "$(cat "$PIDFILE")" 2>/dev/null
  i=0
  while [ $i -lt 30 ]; do
    kill -0 "$(cat "$PIDFILE")" 2>/dev/null || break
    i=$((i+1)); sleep 0.5
  done
  kill -0 "$(cat "$PIDFILE")" 2>/dev/null && kill -9 "$(cat "$PIDFILE")" 2>/dev/null
  log "stopped old process (pid $(cat "$PIDFILE"))"
fi
rm -f "$PIDFILE"

# 2) 按架构挑选新二进制
arch="${TRIM_SYS_ARCH:-$(uname -m)}"
case "$arch" in
  x86_64|amd64|x86-64) BIN="$BINDIR/crosspaste_linux_amd64" ;;
  aarch64|arm64|armv8l) BIN="$BINDIR/crosspaste_linux_arm64" ;;
  *) BIN="$BINDIR/crosspaste_linux_amd64" ;;
esac
[ -x "$BIN" ] || fail "binary not found: $BIN"

# 3) 迁移前备份数据库（覆盖上一份备份，避免膨胀；WAL/SHM 一并保留）
DB="$PKGVAR/crosspaste.db"
if [ -f "$DB" ]; then
  cp -f "$DB" "$DB.bak"
  [ -f "$DB-wal" ] && cp -f "$DB-wal" "$DB.bak-wal"
  [ -f "$DB-shm" ] && cp -f "$DB-shm" "$DB.bak-shm"
  log "database backed up: $DB.bak"
fi

# 4) 幂等迁移（新二进制；脚本已以包专属非特权用户运行，无需也无法 runuser）
mkdir -p "$PKGVAR/media"
if ! env \
  APP_DB_PATH="$DB" STORAGE_ROOT="$PKGVAR/media" \
  "$BIN" --migrate >>"$PKGVAR/app.log" 2>&1; then
  fail "migration failed, see $PKGVAR/app.log (backup at $DB.bak)"
fi

log "upgraded $OLDVER -> $NEWVER, migration ok"
exit 0
