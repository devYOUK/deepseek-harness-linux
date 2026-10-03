# DeepSeek Harness · Linux 桌面构建

> **本仓库是个人维护的 Linux 移植镜像，非官方项目。**
> 原项目（上游）：**https://github.com/deepseek-ai/deepseek-harness**
> 上游的项目介绍、完整文档与贡献指南请以原仓库为准。

## 建仓目的

DeepSeek Harness 官方**不支持 Linux 桌面发布目标**——上游打包流水线只注册了
macOS / Windows 目标，不产出任何 Linux 安装包，应用内的自动更新通道也不存在
Linux 分支。

本仓库用于保存一套**可持续维护的 linux-x64 桌面版构建方案**：在上游代码之上
打补丁，使 DeepSeek Harness Desktop 能够在 Ubuntu 上从源码打包出可安装、可
日常使用的 **AppImage** 与 **deb**，并把每次与上游同步所需的改动以提交形式
固化下来，而不是散落在本地文件里。

## 分支结构

| 分支 | 内容 |
|---|---|
| `master` | 上游 `master` 的原样镜像，不作任何修改，仅用于同步 |
| `linux-port` | 移植改动所在分支，构建请使用此分支 |

## 构建

前提：Node.js ≥ 22.19 / 24.x、pnpm 11.7.0、C 编译器
（`sudo apt install build-essential`，或无 root 时用 micromamba 装 rootless
工具链）。GitHub 访问受限的网络需要为 Node 配置 `HTTPS_PROXY`；
Electron 及构建工具二进制建议使用 npmmirror 镜像。

```sh
git clone -b linux-port https://github.com/devYOUK/deepseek-harness-linux.git
cd deepseek-harness-linux
pnpm install

export DSH_CLIENT_COMMIT_HASH="$(git rev-parse HEAD)"
export DSH_CLIENT_VERSION="$(node -p "require('./package.json').version")"
export ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/
export ELECTRON_BUILDER_BINARIES_MIRROR=https://npmmirror.com/mirrors/electron-builder-binaries/

pnpm run package:desktop    # 完整流水线，热缓存约 10 分钟
```

产物位于 `apps/desktop/.desktop-build/targets/linux-x64/artifacts/`：

- `deepseek-harness-<version>-linux-x86_64.AppImage` — 免安装直接运行
  （Ubuntu 24.04+ 需 `sudo apt install libfuse2t64`，或加
  `--appimage-extract-and-run`）
- `deepseek-harness-<version>-linux-amd64.deb` — `sudo dpkg -i` 安装

AppImage 用户构建后运行一次桌面集成脚本（菜单/Dock 图标、`dsh://` 链接）：

```sh
bash apps/desktop/scripts/install-linux-desktop.sh
```

## 相对上游的主要改动

- 注册 `linux-x64` 打包目标；新增 `.env.linux` 发布配置（Linux 跳过代码签名、
  公证、自动更新源与强制更新策略）
- Linux 运行时适配：原生 sharp 与 Electron 的 glib 冲突改为 WASM 回退、
  打包冒烟剥离 `NODE_PATH`、Office 引擎从 `app.asar.unpacked` 物理路径加载、
  CLI 启动脚本与打包冒烟的 Linux 布局
- 桌面集成：`desktopName` / `linux.syncDesktopName` 使 Wayland `app_id` 与
  X11 `WM_CLASS` 正确匹配应用菜单和 Dock 图标

## 上游项目

- 原项目地址：https://github.com/deepseek-ai/deepseek-harness
- 许可证：MIT（见 [LICENSE](./LICENSE)，与上游一致）
- 本仓库与 DeepSeek 官方无关，改动仅用于个人构建与研究用途；如需给上游贡献
  代码，请直接向原仓库提交 Pull Request。
