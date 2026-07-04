@echo off
setlocal enabledelayedexpansion

REM ========================================
REM 隐藏任务栏任务视图按钮
REM 使用方法：右键"以管理员身份运行"
REM ========================================

title 隐藏任务视图按钮

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  需要管理员权限，请右键选择"以管理员身份运行"。
    echo.
    pause
    exit /b 1
)

echo.
echo  正在隐藏任务栏任务视图按钮...

REM 隐藏任务视图按钮 (0=隐藏, 1=显示)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d "0" /f >nul 2>&1

if !errorlevel! equ 0 (
    echo  [OK] 任务视图按钮已隐藏
) else (
    echo  [ERROR] 设置失败
)

echo.
echo  正在重启资源管理器使更改生效...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe >nul 2>&1

echo  [OK] 完成
echo.
echo  恢复方法：运行以下命令后重启资源管理器
echo    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d "1" /f
echo.
pause
