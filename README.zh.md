# DeepSeek Harness 安装器

[English](README.md) | 中文

[DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（`dsh`）一键安装工具 —— 由 DeepSeek AI 开发的开源智能体框架。

本工具自动完成：
- 全局安装 `@deepseek-ai/dsh` npm 包
- 生成自定义鲸鱼主题桌面图标
- 创建一键快捷方式，点击即启动服务并打开浏览器

## 图标预览

快捷方式图标为蓝色渐变背景上的白色鲸鱼（DeepSeek 品牌标志）：

![dsh-icon](assets/dsh-icon.svg)

## 前置要求

- **Node.js** v18+ — 从 https://nodejs.org/ 下载

## 快速开始

### Windows

```powershell
git clone https://github.com/plkiouyhh-max/deepseek-harness-installer.git
cd deepseek-harness-installer
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
git clone https://github.com/plkiouyhh-max/deepseek-harness-installer.git
cd deepseek-harness-installer
chmod +x scripts/install.sh
./scripts/install.sh
```

## 安装过程说明

| 步骤 | Windows | macOS / Linux |
|------|---------|---------------|
| 1. 检查 Node.js | `node --version` | `node --version` |
| 2. 安装 dsh | `npm install -g @deepseek-ai/dsh` | `sudo npm install -g @deepseek-ai/dsh` |
| 3. 生成图标 | 官方 DeepSeek Logo（.ico，离线时自动回退自绘图标） | 复制 SVG 图标 |
| 4. 创建快捷方式 | PowerShell 启动脚本 + `.lnk` 快捷方式 | `.command`（macOS）/ `.desktop`（Linux） |

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
deepseek-harness-installer/
├── README.md              # 英文文档
├── README.zh.md           # 中文文档
├── SKILL.md               # AI Agent 技能定义
├── LICENSE                # MIT 许可证
├── assets/
│   └── dsh-icon.svg       # 图标源文件（SVG）
└── scripts/
    ├── install.ps1        # Windows 安装脚本
    └── install.sh         # macOS / Linux 安装脚本
```

## 兼容的 AI Agent

本项目包含 `SKILL.md` 文件，内含结构化的分步指令，任何 AI 编程助手都能读取并执行。以下是各主流 Agent 的使用方式：

### TRAE

将 `SKILL.md` 复制到 `.trae/skills/` 目录：

```bash
mkdir -p .trae/skills/deepseek-harness-installer
cp SKILL.md .trae/skills/deepseek-harness-installer/
```

然后对 Agent 说：*"安装 DeepSeek Harness 并创建桌面快捷方式"*

### Claude Code

```bash
claude "Read SKILL.md from https://github.com/plkiouyhh-max/deepseek-harness-installer and execute the installation"
```

或将 `SKILL.md` 保存为项目根目录的 `CLAUDE.md`，然后让 Claude Code 执行。

### Cursor

将 `SKILL.md` 内容添加到项目的 `.cursorrules` 文件：

```bash
curl -o .cursorrules https://raw.githubusercontent.com/plkiouyhh-max/deepseek-harness-installer/main/SKILL.md
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
Read and execute the instructions from https://github.com/plkiouyhh-max/deepseek-harness-installer/blob/main/SKILL.md
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
Clone https://github.com/plkiouyhh-max/deepseek-harness-installer and run the installation script for my OS.
```

### 其他 Agent

`SKILL.md` 包含通用的分步指令。只需将你的 Agent 指向[本仓库](https://github.com/plkiouyhh-max/deepseek-harness-installer)，让它按照指南执行安装即可。

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
| 图标不显示（Windows） | 按 F5 刷新桌面 |
| npm 权限错误（Linux/macOS）| 使用 `sudo npm install -g @deepseek-ai/dsh` |

## 关于 DeepSeek Harness

DeepSeek Harness 是由 DeepSeek AI 开发的开源智能体框架，采用"一切皆插件"架构，由 Cordis 驱动。

- **仓库地址**：https://github.com/deepseek-ai/deepseek-harness
- **许可证**：MIT
- **状态**：开发者预览阶段（0.1.0-rc.x）

## 许可证

MIT — 详见 [LICENSE](LICENSE)
