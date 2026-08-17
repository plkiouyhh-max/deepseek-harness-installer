# DeepSeek Harness 安装器

[English](README.md) | 中文

[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（`dsh`）一键安装工具 —— 由 DeepSeek AI 开发的开源智能体框架。

本工具自动完成：
- 全局安装 `@deepseek-ai/dsh` npm 包
- 安装插件（默认装 `dshmarket` -- 把 [awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin) 全部 341 个社区插件目录装进 Web UI，可浏览/搜索/一键安装；另附 `dsh-better-sidebar` 侧边栏、`dsh-usage-stats` 用量看板、`@deepseek-ai/dsh-persona` 预设提示词引擎与 `dsh-minimal-banner` 可见横幅）
- 校验极简模式（minimal）系统提示词包含 `You are a helpful software engineer assistant.`，缺失时自动回写，并把该行同时注入为**会话顶部可见的上下文消息**（见[下方「极简模式与『最强形态』提示词」](#极简模式与最强形态提示词)）
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
| 3. 校验极简模式提示词 | 检查/回写 minimal 预设的 persona 行 | 相同 |
| 4. 安装插件 | 缺 pnpm 时自动安装；为本地横幅插件准备依赖；然后 `dsh plugin --profile web add <包名>` | 相同 |
| 5. 生成图标 | 官方 DeepSeek Logo（.ico，离线时自动回退自绘图标） | 复制 SVG 图标 |
| 6. 创建快捷方式 | PowerShell 启动脚本 + `.lnk` 快捷方式 | `.command`（macOS）/ `.desktop`（Linux） |

## 内置插件

安装器默认安装四个插件：

| 插件 | 说明 |
|------|------|
| `dshmarket` | [awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin) 官方配套市场：把全部 341 个社区插件目录装进 Web UI，浏览、搜索、看 star、一键安装/更新/卸载，多数插件免重启生效。目录数据直连 `awesome-dsh-plugin.com`（国内可直连），失败自动回退包内快照，无需代理 |
| `dsh-better-sidebar` | VSCode 风格侧边栏（资源管理器 / 终端 / Git / 浏览器） |
| `dsh-usage-stats` | GitHub 风格用量热力图看板：按工作区统计使用次数与 Token 花费（含缓存命中率）、DeepSeek 账户余额查询 |
| `@deepseek-ai/dsh-persona` | 预设提示词引擎：极简/标准模式的系统提示词（含极简模式那行 `You are a helpful software engineer assistant.`）由它注入。**Web profile 默认不带**，缺了它极简模式就没有系统提示词 |
| `dsh-minimal-banner`（本地插件） | 极简模式可见横幅：每个极简会话开头把这行提示词以**上下文消息**形式显示在会话顶部（系统提示词本体仍是不可见的），随安装器分发、自动挂入极简预设 |

> 旧默认市场 `dsh-web-plugin-manager`（只管理已装插件）仍可手动安装：`dsh plugin --profile web add dsh-web-plugin-manager`

**自定义要安装的插件：**

```powershell
# Windows - 自定义插件集
powershell -ExecutionPolicy Bypass -File scripts/install.ps1 -Plugins "dshmarket","dsh-better-sidebar"

# Windows - 只装核心，不装插件
powershell -ExecutionPolicy Bypass -File scripts/install.ps1 -NoPlugins
```

```bash
# macOS / Linux - 自定义插件集
PLUGINS="dshmarket dsh-better-sidebar" ./scripts/install.sh

# macOS / Linux - 只装核心，不装插件
PLUGINS="" ./scripts/install.sh
```

**随时安装更多插件：**

```bash
dsh plugin --profile web add <包名>
```

热门社区插件（更多可在 [npm](https://www.npmjs.com/search?q=dsh) 搜索或 [awesome 列表](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin/blob/main/README.zh.md) 浏览）：

| 插件 | 说明 |
|------|------|
| `dshmarket` | Web UI 内的 awesome 插件市场（341 个目录） |
| `dsh-better-sidebar` | VSCode 风格侧边栏（资源管理器 / 终端 / Git / 浏览器） |
| `dsh-pocket` | 手机访问电脑上的 DSH（局域网 + 公网） |
| `@linxin666/dsh-pet` | 会响应模型活动的浮动桌宠 |

> 说明：安装插件需要 `pnpm`，安装器会在缺失时自动安装。插件在下次 `dsh web` 启动时加载。
>
> pnpm 11 起默认拦截依赖的 postinstall 构建脚本（安全特性），会导致 `dsh plugin add` 报 `ERR_PNPM_IGNORED_BUILDS`。安装器检测到该错误时会自动放行 `node-pty`（dsh Web 终端的原生模块，等价于 `pnpm approve-builds node-pty`）并重试一次；也可自行在 `~/.dsh/profiles/web` 目录执行该命令放行。

## 极简模式与「最强形态」提示词

DSH 内置「极简模式」（minimal 预设）：仅提供持久 bash 与 `str_replace_editor` 双工具的编码 Agent，其**完整系统提示词只有一行**：

```text
You are a helpful software engineer assistant.
```

安装器每次运行都会校验这行提示词仍然存在（上游 dsh 更新导致缺失时会自动回写），随装 `@deepseek-ai/dsh-persona` 注入引擎（Web profile 默认不带），并把 `dsh-minimal-banner` 挂入极简预设--**每次打开极简模式，会话顶部都会出现这行字（以上下文消息形式显示）**。

> 说明：这行字有两条通道--① `dsh-persona` 注入的系统提示词（发给模型，界面不可见，这是「最强形态」的本体）；② `dsh-minimal-banner` 注入的可见上下文消息（会话顶部显示，也会随请求发给模型，仅多耗约 10 token）。不想要可见横幅时，用 `dsh plugin --profile web remove dsh-minimal-banner` 卸载即可，系统提示词不受影响。

**网传「最强形态」**：社区流传（Reddit r/DeepSeek、X 及韩文社区等地的实测帖）DeepSeek 4 Pro 可能对 DSH 极简模式这类环境过拟合，`极简模式 + Thinking Max` 组合在连续编码任务中表现最佳；无法使用 DSH 极简模式的场景（如普通聊天客户端），也可以把这句贴在自定义提示词的最前面来近似模拟。

> ⚠️ **免责声明**：以上为网传经验与社区小样本测试结论，**并非 DeepSeek 官方说法**。实际效果因模型版本、任务类型、提示词其余部分而异，请务必自行测试验证后再决定是否采用。本安装器只负责保证该提示词行存在，**不对其效果做任何形式的保证**。

## 使用快捷方式

1. **双击**桌面上的 "DeepSeek Harness" 快捷方式
2. 快捷方式会自动：
   - 检测 `dsh web` 是否已运行（端口 3080）
   - 若未运行则自动启动服务
   - 等待服务就绪（每 2 秒检测一次）
   - 打开浏览器访问 `http://127.0.0.1:3080`
3. 首次使用需配置模型：
   - 进入 **Settings -> Models**
   - 输入你的 DeepSeek API Key
   - 保存
4. 选择会话预设（标准 / 代码 / 极简模式--见[「极简模式与『最强形态』提示词」](#极简模式与最强形态提示词)）
5. 选择工作区目录
6. 创建会话，开始使用！

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
