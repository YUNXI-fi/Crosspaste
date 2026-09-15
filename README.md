# 跨贴 Crosspaste

> 跑在飞牛 fnOS 上的网页端剪贴板：文本、图片、视频、音频、文件统一收纳，任意设备随时取用。

后端是单个 Go 常驻服务（内嵌前端产物、静态编译，无 CGO 依赖），前端是 React 单页应用。经 fnOS
统一网关打开时自动复用系统登录态，同时保留独立端口供局域网内的手机与其他电脑直连，两种访问
方式共用同一份数据。

## 功能

- **统一收纳**：文本、图片、视频、音频、文件五类内容集中存放，上传即入库
- **文本自动识别**：按内容判定类型（URL、JSON、代码、Markdown 等），卡片以对应形式展示
- **文件类型图标**：内置 147 种扩展名图标，随主题着色；未收录的类型回退到语义图标
- **分组与访问密码**：分组可设置独立密码，解锁后才能查看组内条目
- **标签与收藏**：一条内容可挂多个标签；收藏用于标记常用内容，便于筛选
- **全文检索**：基于 SQLite FTS5，覆盖正文、摘要、标题与标签
- **对外分享**：生成只读分享链接，有效期可选 1 / 12 / 24 小时或 7 天，支持续期与撤销；提供
  访问量与下载量统计（访问按访客 24 小时去重，下载只计显式下载），并可逐条查看访问日志
- **深浅主题**：默认深色，一键切换，选择保存在本地

## 安装（fnOS）

本仓库发布的是 fnOS 应用包骨架，安装方式与常规飞牛应用一致：

```bash
fnpack build -d crosspaste          # 打包生成 crosspaste.fpk
appcenter-cli install-fpk crosspaste.fpk
appcenter-cli start crosspaste
```

也可以在飞牛应用中心直接上传 fpk 安装。安装向导中可设置：

| 向导字段 | 说明 |
| --- | --- |
| 服务端口 | 1024–65535，默认 `28531` |
| 设置页访问密码 | 留空则不启用；长度 4–64 位，以 argon2id 哈希存储，不明文落盘 |

## 访问方式

| 入口 | 地址 | 说明 |
| --- | --- | --- |
| 桌面入口 | `/app/crosspaste` | 经统一网关访问，随系统登录态，免记端口 |
| 独立端口 | `http://NAS_IP:端口/` | 局域网内其他设备直连，端口为安装时设置的值 |

## 技术栈

| 层 | 选型 |
| --- | --- |
| 后端 | Go 1.25 常驻服务；SQLite（`modernc.org/sqlite`，纯 Go 实现，交叉编译无需 CGO） |
| 前端 | React 18 + TypeScript + Vite；交互动效由 motion 驱动 |
| 打包 | fnOS 应用包，`platform=all`：单包内含 amd64 与 arm64 静态二进制，运行时按架构选择 |

## 本仓库内容

本仓库只跟踪 fnOS 应用包与版本记录，前后端源码不在本仓库发布：

- `crosspaste/manifest` — 应用元数据（版本、服务端口、网关入口、更新说明等）
- `crosspaste/cmd/` — 生命周期脚本（安装 / 配置 / 升级 / 卸载回调，以及启停入口 `main`）
- `crosspaste/config/` — 运行权限与资源声明
- `crosspaste/wizard/` — 安装与配置向导表单
- `crosspaste/app/ui/config` — 桌面入口定义
- `crosspaste/ICON.PNG`、`crosspaste/ICON_256.PNG` — 应用图标（64 / 256 像素）
- `CHANGELOG.md` — 版本变更记录

前端产物（`app/ui` 下的资源）与后端二进制（`app/server/bin/`）由构建流程生成，不入库。

从源码构建的流程：

```bash
# 1) 前端：构建并同步产物到包目录与后端内嵌目录
cd web && ./build.sh

# 2) 后端：交叉编译 amd64 / arm64 静态二进制（版本号自动取自 crosspaste/manifest）
cd backend && ./build.sh build
cp crosspaste_linux_amd64 crosspaste_linux_arm64 ../crosspaste/app/server/bin/

# 3) 打包
fnpack build -d crosspaste
```

## 版本

版本变更见 [CHANGELOG.md](CHANGELOG.md)。应用包版本以 `crosspaste/manifest` 的 `version` 为准；
前端设置页显示的版本由构建时注入，两者保持一致。
