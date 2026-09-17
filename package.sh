#!/usr/bin/env bash
# 打包飞牛应用包。fnpack 固定输出 <appname>.fpk，而发版包需要带版本号，
# 这里按 manifest 的 version 重命名并覆盖同名旧包——手工 mv 容易漏，
# 漏了就会留下一个不带版本号、无法从文件名判断版本的包。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="crosspaste"

command -v fnpack >/dev/null 2>&1 || { echo "未找到 fnpack，请先从飞牛开放平台安装" >&2; exit 1; }

# 版本号单一来源：飞牛应用包 manifest（与前端 web/package.json 保持一致）
VERSION="$(sed -n 's/^version=//p' "$ROOT/$APP/manifest" | head -n1)"
[ -n "$VERSION" ] || { echo "无法从 $APP/manifest 读取 version" >&2; exit 1; }
OUT="$ROOT/${APP}_v${VERSION}.fpk"

rm -f "$ROOT/$APP.fpk"
(cd "$ROOT" && fnpack build --directory "$APP")
mv -f "$ROOT/$APP.fpk" "$OUT"

echo "已生成 $OUT"
