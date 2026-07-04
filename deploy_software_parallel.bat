@echo off
cd /d "%~dp0"

:: ============================================================
:: 检查管理员权限
:: ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    color 0C
    echo.
    echo   [ERROR] Please run as Administrator!
    echo.
    pause
    exit /b 1
)

:: ============================================================
:: [FIX LOGIC-2/6] 原代码: 这里手动执行了完整的 Windows Update 控制流程 (L17-61):
::   - taskkill 杀更新进程
::   - net stop 停止服务
::   - del 清除缓存
::   - reg add + sc config 禁用服务
::
:: 问题分析:
::   1. deploy_parallel.ps1 阶段三 (L582) 又调用 windows_update_control.ps1 -Action pause
::      → 同一套操作执行了两次，浪费时间且可能冲突
::   2. bat 版本没有 Win11 检测，在 Win11 上也执行 sc config disable → 不必要
::   3. ps1 的 windows_update_control.ps1 有超时等待机制更健壮（最多等10秒）
::
:: 修复: 删除 bat 中的重复逻辑，统一由 ps1 调用 windows_update_control.ps1 处理。
::       bat 只负责管理员检测 + 启动 ps1，职责清晰。
:: ============================================================

cls
echo.
echo  ==================================================
echo       Starting Software Installation
echo  ==================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy_parallel.ps1"
if %errorlevel% neq 0 pause
