#!/bin/sh
# 安装应用文件后执行：按当前架构挑选二进制并初始化数据库（幂等）。
set -u
APP=crosspaste
APPDEST="${TRIM_APPDEST:-/var/apps/crosspaste/target}"
PKGVAR="${TRIM_PKGVAR:-/var/apps/crosspaste/var}"
BINDIR="$APPDEST/server/bin"

log() { echo "$APP: $*"; }
fail() { echo "$APP: $*" >&2; [ -n "${TRIM_TEMP_LOGFILE:-}" ] && echo "$*" >>"$TRIM_TEMP_LOGFILE"; exit 1; }

mkdir -p "$PKGVAR/media"

# 按架构挑选二进制
arch="${TRIM_SYS_ARCH:-$(uname -m)}"
case "$arch" in
  x86_64|amd64|x86-64) BIN="$BINDIR/crosspaste_linux_amd64" ;;
  aarch64|arm64|armv8l) BIN="$BINDIR/crosspaste_linux_arm64" ;;
  *) BIN="$BINDIR/crosspaste_linux_amd64" ;;
esac

[ -x "$BIN" ] || fail "binary not found: $BIN"
if ! env \
  APP_DB_PATH="$PKGVAR/crosspaste.db" STORAGE_ROOT="$PKGVAR/media" \
  "$BIN" --migrate >>"$PKGVAR/app.log" 2>&1; then
  fail "migration failed, see $PKGVAR/app.log"
fi

# 向导收集的设置页访问密码（留空则不启用）；只经环境变量传入，不写入日志
if [ -n "${wizard_settings_password:-}" ]; then
  if ! env \
    APP_DB_PATH="$PKGVAR/crosspaste.db" \
    SETTINGS_PASSWORD="$wizard_settings_password" \
    "$BIN" --set-settings-password >>"$PKGVAR/app.log" 2>&1; then
    fail "apply settings password failed, see $PKGVAR/app.log"
  fi
  log "settings password applied"
fi

log "install migration ok"
exit 0
