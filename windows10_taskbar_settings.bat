@echo off
setlocal enabledelayedexpansion

REM ========================================
REM Windows 10 任务栏搜索和资讯设置
REM 搜索框改为图标 + 关闭资讯和兴趣
REM 使用方法：右键"以管理员身份运行"
REM ========================================

title Windows 10 任务栏设置

REM 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo   错误：需要管理员权限！
    echo ========================================
    echo.
    echo 请右键点击此脚本，选择"以管理员身份运行"。
    echo.
    pause >nul
    exit /b 1
)

echo.
echo ========================================
echo   Windows 10 任务栏设置
echo ========================================
echo.

REM ========================================
REM 第一部分：搜索框改为图标模式
REM ========================================

echo [1/2] 设置搜索框为图标模式...
echo   SearchboxTaskbarMode:
echo     0 = 隐藏, 1 = 仅图标, 2 = 搜索框

REM 设置搜索框样式为仅图标模式
REM 0 = 隐藏, 1 = 仅图标, 2 = 搜索框, 3 = 搜索框+文字
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f >nul 2>&1

echo   [OK] 搜索框已设为仅图标模式

REM ========================================
REM 第二部分：关闭资讯和兴趣
REM ========================================

echo [2/2] 关闭资讯和兴趣...

REM 方法1：用户级策略 - 禁用 Feeds 功能
reg add "HKCU\Software\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d "0" /f >nul 2>&1

REM 方法2：系统级策略 - 对所有用户禁用（需管理员权限）
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d "0" /f >nul 2>&1

REM 方法3：隐藏任务栏上的资讯和兴趣按钮
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d "2" /f >nul 2>&1

echo   [OK] 资讯和兴趣已关闭（已写入策略注册表）

REM ========================================
REM 重启资源管理器使设置立即生效
REM ========================================

echo.
echo [3/3] 重启资源管理器...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe >nul 2>&1
echo   [OK] 资源管理器已重启

REM ========================================
REM 刷新并提示重启
REM ========================================

echo.
echo ========================================
echo   设置完成！
echo ========================================
echo.
echo 已完成：
echo   [OK] 搜索框已改为图标模式
echo   [OK] 资讯和兴趣已关闭
echo.
echo   注意：部分设置需要注销或重启才能完全生效！
echo.
echo 推荐执行以下操作使更改立即生效：
echo   1. 注销当前用户后重新登录
echo   2. 或者重启计算机
echo.
echo 如需恢复默认设置，请运行：
echo   reg delete "HKCU\Software\Policies\Microsoft\Windows\Windows Feeds" /f
echo   reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /f
echo   reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /f
echo.
echo 按任意键退出...
pause >nul