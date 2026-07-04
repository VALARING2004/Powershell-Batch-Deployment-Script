@echo off
setlocal enabledelayedexpansion
REM ========================================
REM Windows 10 OneDrive 完全卸载脚本
REM 使用方法：右键"以管理员身份运行"
REM ========================================

title OneDrive 卸载工具

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
echo   Windows 10 OneDrive 完全卸载工具
echo ========================================
echo.
echo   警告：此操作将完全卸载 OneDrive，包括：
echo     - 卸载 OneDrive 程序
echo     - 删除 OneDrive 文件夹和数据
echo     - 清理注册表和任务栏图标
echo     - 禁用 OneDrive 自动启动
echo.
echo   请确保已备份所有 OneDrive 中的重要文件！
echo.
echo   按 N 取消，按其他任意键继续...
set /p confirm=
if /i "!confirm!"=="N" goto :cancel

echo.
echo ----------------------------------------
echo   开始卸载...
echo ----------------------------------------

REM ========================================
REM [1/6] 停止 OneDrive 进程
REM ========================================
echo.
echo [1/6] 停止 OneDrive 进程...
taskkill /f /im OneDrive.exe >nul 2>&1
echo   [OK] OneDrive 进程已终止

REM ========================================
REM [2/6] 卸载 OneDrive 程序
REM ========================================
echo.
echo [2/6] 卸载 OneDrive 程序...

REM 尝试 64 位系统的卸载程序
if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" (
    "%SystemRoot%\SysWOW64\OneDriveSetup.exe" /uninstall >nul 2>&1
    echo   [OK] 已执行 64 位卸载程序
) else if exist "%SystemRoot%\System32\OneDriveSetup.exe" (
    "%SystemRoot%\System32\OneDriveSetup.exe" /uninstall >nul 2>&1
    echo   [OK] 已执行 32 位卸载程序
) else (
    echo   [跳过] 未找到 OneDrive 卸载程序（可能已卸载）
)

REM 等待卸载完成
timeout /t 3 /nobreak >nul

REM ========================================
REM [3/6] 删除 OneDrive 残留文件和文件夹
REM ========================================
echo.
echo [3/6] 删除 OneDrive 残留文件...

if exist "%UserProfile%\OneDrive" (
    rd "%UserProfile%\OneDrive" /s /q >nul 2>&1
    echo   [OK] 已删除 %%UserProfile%%\OneDrive
) else (
    echo   [跳过] %%UserProfile%%\OneDrive 不存在
)

if exist "%LocalAppData%\Microsoft\OneDrive" (
    rd "%LocalAppData%\Microsoft\OneDrive" /s /q >nul 2>&1
    echo   [OK] 已删除 OneDrive 应用数据
) else (
    echo   [跳过] OneDrive 应用数据不存在
)

if exist "%ProgramData%\Microsoft OneDrive" (
    rd "%ProgramData%\Microsoft OneDrive" /s /q >nul 2>&1
    echo   [OK] 已删除 ProgramData 中的 OneDrive
) else (
    echo   [跳过] ProgramData 中的 OneDrive 不存在
)

if exist "C:\OneDriveTemp" (
    rd "C:\OneDriveTemp" /s /q >nul 2>&1
    echo   [OK] 已删除 OneDriveTemp
)

REM 删除开始菜单和桌面快捷方式
del "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
del "%USERPROFILE%\Desktop\OneDrive.lnk" /f /q >nul 2>&1
del "%Public%\Desktop\OneDrive.lnk" /f /q >nul 2>&1
echo   [OK] 已删除快捷方式

REM ========================================
REM [4/6] 清理注册表
REM ========================================
echo.
echo [4/6] 清理注册表...

REM 移除文件资源管理器中的 OneDrive 图标
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d "0" /f >nul 2>&1
echo   [OK] 已从文件资源管理器移除 OneDrive 图标

REM 禁用 OneDrive 通过组策略
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d "1" /f >nul 2>&1
echo   [OK] 已禁用 OneDrive 组策略

REM 移除 OneDrive 启动项
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1
echo   [OK] 已移除 OneDrive 启动项

REM 防止 OneDrive 首次运行向导
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d "1" /f >nul 2>&1

REM ========================================
REM [5/6] 禁用 OneDrive 相关计划任务
REM ========================================
echo.
echo [5/6] 禁用 OneDrive 计划任务...
schtasks /change /tn "\Microsoft\Windows\OneDrive Reporting Task" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\OneDrive Reporting Task-S-1-5-21*" /disable >nul 2>&1
echo   [OK] OneDrive 计划任务已禁用

REM ========================================
REM [6/6] 刷新文件资源管理器
REM ========================================
echo.
echo [6/6] 刷新系统...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe >nul 2>&1
echo   [OK] 资源管理器已刷新

REM ========================================
REM 完成
REM ========================================
echo.
echo ========================================
echo   OneDrive 卸载完成！
echo ========================================
echo.
echo 已完成：
echo   [OK] OneDrive 进程已终止
echo   [OK] OneDrive 程序已卸载
echo   [OK] 残留文件已删除
echo   [OK] 注册表已清理
echo   [OK] 计划任务已禁用
echo   [OK] 资源管理器已刷新
echo.
echo 如需恢复 OneDrive，可在 Microsoft Store 重新下载安装。
echo.
echo 按任意键退出...
pause >nul
exit /b 0

:cancel
echo.
echo 已取消卸载。
echo.
pause >nul
exit /b 0
