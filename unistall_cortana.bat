@echo off
chcp 65001 >nul
title 禁用Windows 10 Cortana任务栏图标
echo ============================================
echo     正在执行Cortana禁用操作...
echo     请确保以管理员身份运行此脚本！
echo ============================================
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 错误：请以管理员身份运行此脚本！
    echo 右键点击脚本文件，选择“以管理员身份运行”。
    pause
    exit /b 1
)

echo [步骤1/5] 通过注册表永久禁用Cortana核心服务[1](@ref)[2](@ref)[3](@ref)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul
if %errorLevel% equ 0 (
    echo   √ 注册表策略已设置 (AllowCortana=0)
) else (
    echo   × 注册表设置失败，跳过此步骤
)

echo.
echo [步骤2/5] 通过PowerShell卸载Cortana应用包[1](@ref)[2](@ref)[3](@ref)
powershell -Command "Get-AppxPackage *Cortana* | Remove-AppxPackage -ErrorAction SilentlyContinue"
powershell -Command "Get-AppxPackage -allusers Microsoft.549981C3F5F10 | Remove-AppxPackage -ErrorAction SilentlyContinue"
echo   √ 已尝试卸载Cortana应用包

echo.
echo [步骤3/5] 终止Cortana相关进程[5](@ref)
taskkill /f /im SearchApp.exe >nul 2>&1
taskkill /f /im Cortana.exe >nul 2>&1
taskkill /f /im SearchHost.exe >nul 2>&1
echo   √ 已终止Cortana相关进程

echo.
echo [步骤4/5] 禁用Cortana启动项[5](@ref)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "Cortana" /t REG_BINARY /d "030000000000000000000000" /f >nul 2>&1
echo   √ 已尝试禁用Cortana启动项

echo.
echo [步骤5/5] 重命名Cortana系统文件夹（可选，高级操作）[5](@ref)
set "cortanaPath=C:\Windows\SystemApps\Microsoft.Windows.Cortana_*"
if exist "%cortanaPath%" (
    echo   警告：此操作将重命名Cortana系统文件夹，可能导致搜索功能异常。
    echo   是否继续？(Y/N)
    set /p choice=
    if /i "%choice%"=="Y" (
        for /d %%i in ("%cortanaPath%") do (
            if exist "%%i" (
                ren "%%i" "%%~ni.disabled" >nul 2>&1
                if %errorLevel% equ 0 (
                    echo   √ 已重命名文件夹: %%~ni -> %%~ni.disabled
                ) else (
                    echo   × 文件夹重命名失败（可能权限不足）
                )
            )
        )
    ) else (
        echo   × 跳过文件夹重命名操作
    )
) else (
    echo   √ Cortana系统文件夹未找到或已被处理
)

echo.
echo ============================================
echo     操作完成！
echo     建议重启计算机以使所有更改完全生效。
echo.
echo     重启后检查：
echo     1. 任务栏Cortana图标应已消失
echo     2. 搜索功能将退化为纯本地文本检索[1](@ref)[2](@ref)
echo ============================================
echo.
pause
