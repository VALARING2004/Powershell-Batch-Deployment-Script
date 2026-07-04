# Claw — Windows 企业批量部署自动化工具

<p align="center">
  <strong>并行安装 · 系统优化 · 更新控制 · 一键部署</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell" alt="PowerShell" />
  <img src="https://img.shields.io/badge/Batch-CMD-green" alt="Batch" />
  <img src="https://img.shields.io/badge/Windows-10%2F11-lightgrey?logo=windows" alt="Windows" />
  <img src="https://img.shields.io/badge/license-MIT-orange" alt="License" />
</p>

---

## 项目简介

Claw 是一套 **Windows 企业级软件部署与系统优化自动化方案**，通过 PowerShell + Batch 混合脚本实现 **12 款常用软件的并发静默安装**，同步完成隐私加固、广告屏蔽、性能优化等 22 项系统配置。

**解决的核心痛点**：IT 运维人员在新机初始化或批量装机场景下，需要逐一手动安装软件、调整系统设置、控制 Windows Update 干扰——整个过程耗时 2~4 小时且容易出错。Claw 将其压缩至 **15~25 分钟全自动完成**，无需人工干预。

---

## 功能矩阵

| 模块 | 功能 | 详情 |
|------|------|------|
| 🚀 **并行安装引擎** | 12 软件同时安装 | 受控并发调度（最多 5 个子进程）+ 超时自动杀进程 |
| 🛡️ **Windows Update 控制** | 部署期间冻结更新 | 进程终止 + 服务暂停 + 缓存清除 + 策略注册表修改 |
| 🔒 **隐私加固** | 关闭遥测/广告/数据收集 | 4 组注册表键值覆盖 DiagTrack/AdvertisingInfo/AppContext |
| ⚡ **性能优化** | GameDVR/GameMode/电源计划 | 高性能模式激活 + 后台录制禁用 |
| 🗑️ **OneDrive 卸载** | 七步彻底移除 | 注册表 + 计划任务 + Shell 扩展 + 右键菜单 + 上下文菜单 |
| 🤖 **Cortana 禁用** | 四管齐下 | 搜索注册表 + 权限拒绝 + 策略组 + StartMenu 禁止 |
| 🖥️ **桌面图标配置** | 此电脑/回收站/用户文件/网络 | HideDesktopIcons GUID 精确控制 |
| ⌨️ **小键盘开机启用** | 登录界面 + 当前用户 | HKEY_USERS\.DEFAULT 双重写入 |
| 🔄 **7-Zip 完整集成** | 安装 + Shell 扩展 + 文件关联 | NSIS 静默安装 + regsvr32 + HKCR 四层关联 |
| 📊 **实时进度监控** | 动态进度条 + 状态面板 | Clear-Host 重绘 + 三态文件系统 (.run/.ok/.bad) |

---

## 技术架构

### 整体流程

```
┌─────────────────────────────────────────────────────────────┐
│                  deploy_software_parallel.bat                │
│                    （入口 / 管理员检测）                        │
└──────────────────────┬──────────────────────────────────────┘
                       │ powershell -File
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                     deploy_parallel.ps1                      │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│  │ 阶段一    │  │ 阶段二    │  │ 阶段三    │  │ 阶段四       │ │
│  │ 环境准备  │→│ 并行安装   │→│ 系统优化   │→│ 收尾交互     │ │
│  │          │  │ 引擎      │  │ 22项配置  │  │              │ │
│  │ •路径校验 │  │ •状态机   │  │ •注册表   │  │ •重启确认    │ │
│  │ •管理员   │  │ •超时保护 │  │ •服务控制 │  │ •临时目录清理 │ │
│  │ •防重启   │  │ •错误恢复 │  │ •卸载优化 │  │              │ │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 并行安装引擎 — 核心设计

```
                    ┌─────────────────┐
                    │   Apps 数组定义   │
                    │ (12 个软件条目)   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  主调度循环        │
                    │  while($true)    │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ 启动子进程  │  │ 清理已完成 │  │ 超时检测   │
        │ (≤5并发)  │  │ 的进程    │  │ (10min/个) │
        └─────┬────┘  └──────────┘  └─────┬────┘
              │                           │
              ▼                           ▼
     ┌────────────────┐         ┌────────────────┐
     │ 动态生成 .bat   │         │ Kill + 写 .bad  │
     │ → cmd.exe 执行  │         │ 阻止无限重试     │
     └────────┬───────┘         └────────────────┘
              │
              ▼
     ┌─────────────────────────────────┐
     │         子 bat 内部逻辑           │
     │  ┌───────────┐  ┌──────────────┐ │
     │  │ 静默执行    │→│ CheckPath 检测 │ │
     │  │ 安装程序    │  │ → 写 .ok/.bad │ │
     │  └───────────┘  └──────────────┘ │
     └─────────────────────────────────┘
```

### 状态机模型 — 无锁进程通信

```
  待执行          运行中            成功             失败
  (初始态)   ←── (.run 创建) ──→   (.ok 存在)     (.bad 存在)

     │                              │                │
     │    ┌─────────────────────────┘                │
     │    │ 主循环每轮扫描:                            │
     │    │   Test-Path *.run ? → 跳过(正在装)        │
     │    │   Test-Path *.ok  ? → 统计成功+1          │
     │    │   Test-Path *.bad ? → 统计失败+1          │
     │    │   都没有?         → 启动新任务(≤5并发)     │
     │    └──────────────────────────────────────────┘
     ▼
  全部完成 → break → 进入阶段三
```

---

## 项目结构

```
Claw/
├── deploy_software_parallel.bat   # 入口脚本（管理员检测 + PS1 调用）
├── deploy_parallel.ps1             # 主脚本（741行，核心引擎：并行安装 + 系统优化）
├── windows_update_control.ps1     # WinUpdate 控制模块（独立可复用）
├── uninstall_onedrive.bat          # OneDrive 七步彻底卸载
├── unistall_cortana.bat            # Cortana 四管齐下禁用
├── .gitignore                      # 排除规则（二进制/临时/IDE文件）
├── LICENSE                         # MIT 开源协议
└── README.md                       # 项目文档
```

---

## 使用方式

### 前置要求

- Windows 10 (21H2+) 或 Windows 11
- **管理员权限**（右键「以管理员身份运行」）
- 安装包放置在脚本同目录的 `softwares/` 子目录下

### 快速开始

```bat
# 1. 将软件安装包放入 softwares/ 目录
#    支持的安装包命名示例：
#    WeChatSetup.exe、QQ.exe、DingTalk.exe、
#    WPSOfficeSetup.exe、7z2409-x64.exe ...

# 2. 以管理员身份运行
deploy_software_parallel.bat

# 3. 观察实时进度面板，等待全部完成
# 4. 根据提示选择是否重启计算机
```

### 自定义配置

编辑 `deploy_parallel.ps1` 中的 `$Apps` 数组即可增减软件：

```powershell
$Apps = @(
    @{ Id="01"; Exe="WeChatSetup.exe"; Arg="/silent"; Name="微信"; CheckPath="..." },
    @{ Id="02"; Exe="7z2409-x64.exe";  Arg="/S";      Name="7-Zip"; CheckPath="..." },
    # ... 添加你自己的软件条目
)
```

---

## 技术亮点

<details>
<summary><strong>🔧 1. PowerShell + Batch 混合架构设计</strong></summary>

PowerShell 处理复杂逻辑（对象操作、注册表、并发调度），Batch 处理子进程隔离执行。
两者通过**三态文件系统**（`.run` / `.ok` / `.bad`）实现跨语言无锁通信，
避免了管道、共享变量、端口监听等复杂 IPC 方案的引入成本。

</details>

<details>
<summary><strong>⚡ 2. 受控并发调度器</strong></summary>

并非简单地将所有任务扔进 `Start-Job` 或 `ForEach-Object -Parallel`，
而是实现了完整的调度循环：
- 最大并发数上限（防止资源耗尽）
- 基于**文件系统的状态检测**（不依赖进程句柄）
- **两级超时保护**（单软件 10 分钟 / 全局 30 分钟）
- 超时后自动写 `.bad` 标记**防止同一任务无限重试**

</details>

<details>
<summary><strong>🛡️ 3. 防重启三层防御机制</strong></summary>

MSI / InstallShield 安装包常触发 Windows Update 中途强制重启，
采用三层策略阻断：
1. **注册表层**：`AutoRestartDeadline` / `RebootRetryTimeout` 设为极大值
2. **挂起标记层**：主动清除 `Component-Based Servicing\RebootPending`
3. **RunOnce 层**：启发式正则过滤 `RunOnce` / `Run` 中的更新相关项

</details>

<details>
<summary><strong>📐 4. 控制台自适应布局算法</strong></summary>

根据当前字体大小动态计算像素 → 字符转换系数，
精确设置 `BufferSize` 和 `WindowSize` 使进度面板在不同 DPI / 字体下均不换行错位：
```powershell
$pixelPerChar = ($rawUI.FontSize.Width * $dpiScale)
$maxWidth = [math]::Floor($screen.WorkingArea.Width / $pixelPerChar)
$rawUI.BufferSize = New-Object Management.Automation.Size($maxWidth, $bufferHeight)
$rawUI.WindowSize = New-Object Management.Automation.Size($maxWidth, $windowHeight)
```

</details>

<details>
<summary><strong>🔒 5. 安全的注册表操作模式</strong></summary>

封装 `Set-Reg()` 辅助函数统一处理：
- 路径不存在时自动 `New-Item -Force`
- `try/catch` 区分 `[OK]` / `[FAIL]` 输出（红色高亮具体错误）
- 支持 `Registry::` 前缀访问非标准 Hive（如 `HKEY_USERS\.DEFAULT`）
- 命名参数调用避免位置参数错位导致类型错误

</details>

<details>
<summary><strong>🧹 6. NSIS 安装器参数处理细节</strong></summary>

NSIS（Nullsoft Scriptable Install System）的 `/D=` 参数有特殊行为：
- `/D=C:\Program Files\App` ✅ 正确（NSIS 自己解析空格）
- `/D="C:\Program Files\App"` ❌ 错误（引号被当作路径字面字符）

这一细节如果忽略会导致安装到含引号的畸形路径，后续所有依赖路径检测的逻辑连锁失败。

</details>

---

## 开发日志

| 版本 | 日期 | 内容 |
|------|------|------|
| v1.0 | 2026-04 | 初始版本，串行安装基础功能 |
| v1.5 | 2026-04 | 新增并行安装引擎、Windows Update 控制 |
| v2.0 | 2026-05 | 重构为状态机模型、添加超时保护、7-Zip 完整集成 |
| **v2.1** | **2026-07** | **全面 Bug 修复 + 代码审计：修复 Set-Reg 参数缺失、HKCU 路径错误、regsvr32 引号、NSIS /D= 参数、超时无限重试等 11 项问题** |

---

## 技术栈

| 类别 | 技术 |
|------|------|
| 脚本语言 | PowerShell 5.1+, Windows Batch (CMD) |
| 并发模型 | System.Diagnostics.Process + 文件件系统状态机 |
| 注册表操作 | Set-ItemProperty / New-ItemProperty (PowerShell Provider) |
| 进程管理 | ProcessStartInfo, taskkill, Get-Process |
| 服务管理 | Stop-Service, sc config, Get-Service |
| 目标平台 | Windows 10 (21H2+), Windows 11 |

---

## License

MIT License &mdash; 可自由使用、修改、分发。

---

<p align="center">
  <sub>Made with ❤️ for IT Ops efficiency. Built for the real-world deployment battle.</sub>
</p>
