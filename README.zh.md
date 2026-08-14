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
git clone https://github.com/plkiouyhh-max/dsh-installer.git
cd dsh-installer
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

> **自定义桌面路径？** 添加参数 `-DesktopPath "E:\你的桌面"`

### macOS / Linux

```bash
git clone https://github.com/YOUR_USERNAME/dsh-installer.git
cd dsh-installer
chmod +x scripts/install.sh
./scripts/install.sh
```

## 安装过程说明

| 步骤 | Windows | macOS / Linux |
|------|---------|---------------|
| 1. 检查 Node.js | `node --version` | `node --version` |
| 2. 安装 dsh | `npm install -g @deepseek-ai/dsh` | `sudo npm install -g @deepseek-ai/dsh` |
| 3. 生成图标 | System.Drawing 生成 256x256 .ico | 复制 SVG 图标 |
| 4. 创建快捷方式 | `.bat` 启动脚本 + `.lnk` 快捷方式 | `.command`（macOS）/ `.desktop`（Linux） |

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
dsh-installer/
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

## 作为 AI Agent 技能使用

本项目包含 `SKILL.md` 文件，可被任意 AI Agent（TRAE、Claude Code 等）调用以自动完成安装。

### TRAE 用户

将 `SKILL.md` 复制到 `.trae/skills/dsh-installer/` 目录：

```bash
mkdir -p .trae/skills/dsh-installer
cp SKILL.md .trae/skills/dsh-installer/
```

然后直接对 Agent 说：*"安装 DeepSeek Harness 并创建桌面快捷方式"*

### 其他 Agent

`SKILL.md` 包含详细的分步指令，任何 Agent 都可遵循执行。将 Agent 指向本仓库，让其运行安装即可。

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
