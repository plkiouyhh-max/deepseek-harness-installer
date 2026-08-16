# DeepSeek Harness 安装器

[English](README.md) | 中文

[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（`dsh`）一键安装工具 —— 由 DeepSeek AI 开发的开源智能体框架。

本工具自动完成：
- 全局安装 `@deepseek-ai/dsh` npm 包
- 安装插件（默认装 `dsh-web-plugin-manager` —— 在 Web UI 里直接管理/安装插件的插件市场）
- 使用 DeepSeek 官方 Logo 作为桌面图标（离线时回退自绘图标）
- 创建一键快捷方式，点击即启动服务并打开浏览器

## 图标预览

快捷方式使用 DeepSeek 官方 Logo：

![deepseek-official-icon](assets/deepseek-official.png)

## 前置要求

- **Node.js** v18+ — 从 https://nodejs.org/ 下载

## 快速开始

### Windows

```powershell
git clone https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer.git
cd dsh-deepseek-harness-installer
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

<details>
<summary><b>需要指定桌面路径？（点击展开）</b></summary>

大多数用户**无需此参数** — 脚本会自动检测桌面位置。但如果你把桌面移动到了其他盘（例如 `D:\` 或 `E:\`），则需要手动指定。

**如何找到你的桌面路径：**

**方法一** — 文件资源管理器：
1. 打开文件资源管理器
2. 左侧右键点击 **桌面**（或 **此文件夹**）→ **属性**
3. 查看 **位置** 一栏，即为你的桌面路径

**方法二** — PowerShell 命令：
```powershell
[Environment]::GetFolderPath("Desktop")
```
运行后会输出桌面路径，例如 `C:\Users\你的用户名\Desktop` 或 `D:\桌面`。

找到路径后，安装时加上 `-DesktopPath` 参数：
```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1 -DesktopPath "D:\桌面"
```

</details>

### macOS / Linux

```bash
git clone https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer.git
cd dsh-deepseek-harness-installer
chmod +x scripts/install.sh
./scripts/install.sh
```

## 安装过程说明

| 步骤 | Windows | macOS / Linux |
|------|---------|---------------|
| 1. 检查 Node.js | `node --version` | `node --version` |
| 2. 安装 dsh | `npm install -g @deepseek-ai/dsh` | `sudo npm install -g @deepseek-ai/dsh` |
| 3. 安装插件 | 缺 pnpm 时自动安装，然后 `dsh plugin --profile web add <包名>` | 相同 |
| 4. 生成图标 | 官方 DeepSeek Logo（.ico，离线时自动回退自绘图标） | 复制 SVG 图标 |
| 5. 创建快捷方式 | PowerShell 启动脚本 + `.lnk` 快捷方式 | `.command`（macOS）/ `.desktop`（Linux） |

## 内置插件

安装器默认安装 [dsh-web-plugin-manager](https://www.npmjs.com/package/dsh-web-plugin-manager)，它会在 Web UI 里提供插件市场 —— 浏览、安装、启用/禁用、卸载插件全部图形化操作，无需命令行。

**自定义要安装的插件：**

```powershell
# Windows — 自定义插件集
powershell -ExecutionPolicy Bypass -File scripts/install.ps1 -Plugins "dsh-web-plugin-manager","dsh-better-sidebar"

# Windows — 只装核心，不装插件
powershell -ExecutionPolicy Bypass -File scripts/install.ps1 -NoPlugins
```

```bash
# macOS / Linux — 自定义插件集
PLUGINS="dsh-web-plugin-manager dsh-better-sidebar" ./scripts/install.sh

# macOS / Linux — 只装核心，不装插件
PLUGINS="" ./scripts/install.sh
```

**随时安装更多插件：**

```bash
dsh plugin --profile web add <包名>
```

热门社区插件（更多可在 [npm](https://www.npmjs.com/search?q=dsh) 搜索）：

| 插件 | 说明 |
|------|------|
| `dsh-web-plugin-manager` | Web UI 内的插件市场 |
| `dsh-better-sidebar` | VSCode 风格侧边栏（资源管理器 / 终端 / Git / 浏览器） |
| `dsh-pocket` | 手机访问电脑上的 DSH（局域网 + 公网） |
| `@linxin666/dsh-pet` | 会响应模型活动的浮动桌宠 |

> 说明：安装插件需要 `pnpm`，安装器会在缺失时自动安装。插件在下次 `dsh web` 启动时加载。

## 使用快捷方式

1. **双击**桌面上的 "DeepSeek Harness" 快捷方式
2. 快捷方式会自动：
   - 检测 `dsh web` 是否已运行（端口 3080）
   - 若未运行则自动启动服务
   - 等待服务就绪（每 2 秒检测一次）
   - 打开浏览器访问 `http://127.0.0.1:3080`
3. 首次使用需配置模型：
   - 进入 **Settings → Models**
   - 输入你的 DeepSeek API Key
   - 保存
4. 选择工作区目录
5. 创建会话，开始使用！

## 项目结构

```
dsh-deepseek-harness-installer/
├── README.md              # 英文文档
├── README.zh.md           # 中文文档
├── SKILL.md               # AI Agent 技能定义
├── LICENSE                # MIT 许可证
├── assets/
│   ├── deepseek-official.png  # DeepSeek 官方 Logo（Windows 使用）
│   └── dsh-icon.svg           # 图标源文件（SVG，macOS/Linux 使用）
└── scripts/
    ├── install.ps1        # Windows 安装脚本
    └── install.sh         # macOS / Linux 安装脚本
```

## 兼容的 AI Agent

本项目包含 `SKILL.md` 文件，内含结构化的分步指令，任何 AI 编程助手都能读取并执行。以下是各主流 Agent 的使用方式：

### TRAE

将 `SKILL.md` 复制到 `.trae/skills/` 目录：

```bash
mkdir -p .trae/skills/dsh-deepseek-harness-installer
cp SKILL.md .trae/skills/dsh-deepseek-harness-installer/
```

然后对 Agent 说：*"安装 DeepSeek Harness 并创建桌面快捷方式"*

### Claude Code

```bash
claude "Read SKILL.md from https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer and execute the installation"
```

或将 `SKILL.md` 保存为项目根目录的 `CLAUDE.md`，然后让 Claude Code 执行。

### Cursor

将 `SKILL.md` 内容添加到项目的 `.cursorrules` 文件：

```bash
curl -o .cursorrules https://raw.githubusercontent.com/plkiouyhh-max/dsh-deepseek-harness-installer/main/SKILL.md
```

然后在 Cursor 对话框中输入：*"按照指令安装 DeepSeek Harness"*

### Windsurf（Codeium）

将 `SKILL.md` 保存为工作区的 `.windsurfrules`，然后对 Cascade 说：*"执行 DeepSeek Harness 的安装步骤"*

### GitHub Copilot Chat

在 VS Code 中使用 Copilot Chat 输入：

```
@workspace Read SKILL.md and follow the steps to install DeepSeek Harness
```

### Cline

在 Cline 中创建新任务，输入：

```
Read and execute the instructions from https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer/blob/main/SKILL.md
```

### Continue.dev

将 `SKILL.md` 内容添加到 `.continuerc`，或直接粘贴到对话窗口中，然后让 Continue 执行。

### Aider

```bash
aider --message "Read SKILL.md and run the DeepSeek Harness installation"
```

### OpenHands

创建新任务，输入：

```
Clone https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer and run the installation script for my OS.
```

### 其他 Agent

`SKILL.md` 包含通用的分步指令。只需将你的 Agent 指向[本仓库](https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer)，让它按照指南执行安装即可。

## 手动安装（不使用脚本）

如果你更愿意手动操作：

```bash
# 1. 安装 dsh
npm install -g @deepseek-ai/dsh

# 2. 启动 Web UI
dsh web

# 3. 浏览器打开 http://127.0.0.1:3080
```

## 常见问题

| 问题 | 解决方案 |
|------|----------|
| 找不到 `dsh` 命令 | 重启终端，或将 npm 全局 bin 路径加入 PATH |
| 端口 3080 已被占用 | 关闭已有的 `dsh web` 进程 |
| 端口 3080 权限拒绝（`EACCES`） | 见[下方说明](#端口-3080-被-windows-保留eacces-permission-denied) |
| 图标不显示（Windows） | 按 F5 刷新桌面 |
| npm 权限错误（Linux/macOS）| 使用 `sudo npm install -g @deepseek-ai/dsh` |

### 端口 3080 被 Windows 保留（EACCES: permission denied）

**症状**：`dsh web` 启动报错 `listen EACCES: permission denied 127.0.0.1:3080`，桌面快捷方式弹出"启动失败"提示。这不是安装器的问题，而是 Windows 的已知行为 —— 在使用 WSL2 / Hyper-V / Docker 的电脑上，**重启后**容易出现。

**原因**：Windows 的 WinNAT 服务每次开机都会动态保留随机端口段。一旦 3080 落入保留区间，任何程序都无法监听该端口。

**验证** — PowerShell 运行：

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

如果 3080 落在列出的某个区间内，执行下面的修复。

**修复** — 为 dsh 永久预留 3080 端口（一次性操作，重启后依然有效）。以**管理员身份**打开 PowerShell 或 CMD，运行：

```powershell
net stop winnat
netsh int ipv4 add excludedportrange protocol=tcp startport=3080 numberofports=1
net start winnat
```

运行后 `dsh web` 和桌面快捷方式即可恢复正常，且重启电脑后不会再出现此问题。

## 关于 DeepSeek Harness

DeepSeek Harness 是由 DeepSeek AI 开发的开源智能体框架，采用"一切皆插件"架构，由 Cordis 驱动。

- **仓库地址**：https://github.com/deepseek-ai/deepseek-harness
- **许可证**：MIT
- **状态**：开发者预览阶段（0.1.0-rc.x）

## 许可证

MIT — 详见 [LICENSE](LICENSE)
