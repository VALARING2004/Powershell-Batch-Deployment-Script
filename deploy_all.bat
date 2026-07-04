@echo off
setlocal enabledelayedexpansion

REM ========================================
REM Windows 10 一键部署工具 - 整合版
REM 包含以下功能模块：
REM   1. 安装 7-Zip 24.09（含文件关联）
REM   2. 任务栏设置（搜索图标+关闭资讯兴趣）
REM   3. 卸载 OneDrive
REM   4. 禁用 Cortana
REM 使用方法：右键"以管理员身份运行"
REM ========================================

title Windows 10 一键部署工具

REM 窗口设置
mode con cols=60 lines=40

REM 全局变量
set "TOTAL_STEPS=23"
set "BAR_WIDTH=40"
set "P_CUR_MODULE=0"

REM ========================================
REM 检查管理员权限
REM ========================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  ==========================================
    echo    错误：需要管理员权限！
    echo  ==========================================
    echo.
    echo  请右键点击此脚本，选择"以管理员身份运行"。
    echo.
    pause
    exit /b 1
)

REM ========================================
REM 显示主界面
REM ========================================

echo.
echo  ==========================================
echo     Windows 10 一键部署工具 v1.0
echo  ==========================================
echo.
echo  即将执行以下操作：
echo.
echo    [1] 安装 7-Zip 24.09（含文件关联+图标）
echo    [2] 任务栏设置（搜索图标+关闭资讯兴趣）
echo    [3] 卸载 OneDrive
echo    [4] 禁用 Cortana
echo.
echo  注意：安装 7-Zip 需要安装包 7z2409-x64.exe
echo       与本脚本在同一目录下。
echo.
echo  按任意键开始部署...
pause >nul

REM ========================================
REM 模块1: 安装 7-Zip 24.09
REM ========================================

set "P_STEP=0"
set "P_CUR_MODULE=0"
set "P_DESC=准备中..."
set "P_SUB="
call :draw_progress

set "SCRIPT_DIR=%~dp0"
set "INSTALLER=%SCRIPT_DIR%7z2409-x64.exe"
set VERSION=24.09
set "SevenZipPath=C:\Program Files\7-Zip"
set "SevenZipFM=%SevenZipPath%\7zFM.exe"
set "SevenZipDLL=%SevenZipPath%\7z.dll"

REM 检查安装包
if exist "%INSTALLER%" (
    set "P_STEP=1"
    set "P_SUB=[OK] 找到 7z2409-x64.exe"
    call :draw_progress
) else (
    cls
    echo.
    echo  ==========================================
    echo  错误：安装包不存在！
    echo  ==========================================
    echo.
    echo  请下载 7z2409-x64.exe 到：
    echo  %SCRIPT_DIR%
    echo.
    echo  下载地址：https://www.7-zip.org/download.html
    echo.
    echo  按 N 跳过此步骤，按其他任意键退出...
    choice /c NY /n /m "请选择 [N]跳过 [Y]退出: "
    if !errorlevel! equ 1 goto :module_7zip_done
    if !errorlevel! equ 2 exit /b 1
)

REM 安装 7-Zip
set "P_STEP=2"
set "P_DESC=安装 7-Zip..."
set "P_SUB=正在执行安装程序..."
call :draw_progress
"%INSTALLER%" /S /D="%SevenZipPath%"

if errorlevel 1 (
    cls
    echo  [ERROR] 7-Zip 安装失败！错误代码：!errorlevel!
    echo  按 N 跳过，按其他任意键退出...
    choice /c NY /n /m "请选择 [N]跳过 [Y]退出: "
    if !errorlevel! equ 1 goto :module_7zip_done
    if !errorlevel! equ 2 exit /b 1
)

timeout /t 2 /nobreak >nul

REM 配置文件关联
if not exist "%SevenZipFM%" (
    set "P_STEP=3"
    set "P_SUB=[ERROR] 7-Zip 未正确安装，跳过配置"
    set "P_DESC=配置 7-Zip..."
    call :draw_progress
    timeout /t 2 /nobreak >nul
    goto :module_7zip_done
)

set "P_STEP=4"
set "P_DESC=注册 Shell 扩展..."
set "P_SUB="
call :draw_progress
regsvr32 /s "%SevenZipDLL%"

set "SevenZipCLSID={23170F69-40C1-278A-1000-000100020000}"

set "P_STEP=5"
set "P_DESC=创建文件类型关联..."
set "P_SUB=正在注册 25+ 种压缩格式..."
call :draw_progress

reg add "HKCR\.7z" /ve /d "7-Zip.7z" /f >nul 2>&1
reg add "HKCR\7-Zip.7z" /ve /d "7z Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.7z\DefaultIcon" /ve /d "%SevenZipDLL%,0" /f >nul 2>&1
reg add "HKCR\7-Zip.7z\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.zip" /ve /d "7-Zip.zip" /f >nul 2>&1
reg add "HKCR\7-Zip.zip" /ve /d "zip Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.zip\DefaultIcon" /ve /d "%SevenZipDLL%,1" /f >nul 2>&1
reg add "HKCR\7-Zip.zip\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.tar" /ve /d "7-Zip.tar" /f >nul 2>&1
reg add "HKCR\7-Zip.tar" /ve /d "tar Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.tar\DefaultIcon" /ve /d "%SevenZipDLL%,13" /f >nul 2>&1
reg add "HKCR\7-Zip.tar\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.gz" /ve /d "7-Zip.gz" /f >nul 2>&1
reg add "HKCR\7-Zip.gz" /ve /d "gz Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.gz\DefaultIcon" /ve /d "%SevenZipDLL%,14" /f >nul 2>&1
reg add "HKCR\7-Zip.gz\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.bz2" /ve /d "7-Zip.bz2" /f >nul 2>&1
reg add "HKCR\7-Zip.bz2" /ve /d "bz2 Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.bz2\DefaultIcon" /ve /d "%SevenZipDLL%,2" /f >nul 2>&1
reg add "HKCR\7-Zip.bz2\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.xz" /ve /d "7-Zip.xz" /f >nul 2>&1
reg add "HKCR\7-Zip.xz" /ve /d "xz Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.xz\DefaultIcon" /ve /d "%SevenZipDLL%,23" /f >nul 2>&1
reg add "HKCR\7-Zip.xz\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.tgz" /ve /d "7-Zip.tgz" /f >nul 2>&1
reg add "HKCR\7-Zip.tgz" /ve /d "tar.gz Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.tgz\DefaultIcon" /ve /d "%SevenZipDLL%,14" /f >nul 2>&1
reg add "HKCR\7-Zip.tgz\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.tbz2" /ve /d "7-Zip.tbz2" /f >nul 2>&1
reg add "HKCR\7-Zip.tbz2" /ve /d "tar.bz2 Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.tbz2\DefaultIcon" /ve /d "%SevenZipDLL%,2" /f >nul 2>&1
reg add "HKCR\7-Zip.tbz2\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.wim" /ve /d "7-Zip.wim" /f >nul 2>&1
reg add "HKCR\7-Zip.wim" /ve /d "wim Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.wim\DefaultIcon" /ve /d "%SevenZipDLL%,15" /f >nul 2>&1
reg add "HKCR\7-Zip.wim\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.001" /ve /d "7-Zip.001" /f >nul 2>&1
reg add "HKCR\7-Zip.001" /ve /d "001 Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.001\DefaultIcon" /ve /d "%SevenZipDLL%,9" /f >nul 2>&1
reg add "HKCR\7-Zip.001\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.rar" /ve /d "7-Zip.rar" /f >nul 2>&1
reg add "HKCR\7-Zip.rar" /ve /d "rar Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.rar\DefaultIcon" /ve /d "%SevenZipDLL%,3" /f >nul 2>&1
reg add "HKCR\7-Zip.rar\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.iso" /ve /d "7-Zip.iso" /f >nul 2>&1
reg add "HKCR\7-Zip.iso" /ve /d "iso Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.iso\DefaultIcon" /ve /d "%SevenZipDLL%,8" /f >nul 2>&1
reg add "HKCR\7-Zip.iso\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.cab" /ve /d "7-Zip.cab" /f >nul 2>&1
reg add "HKCR\7-Zip.cab" /ve /d "cab Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.cab\DefaultIcon" /ve /d "%SevenZipDLL%,7" /f >nul 2>&1
reg add "HKCR\7-Zip.cab\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.arj" /ve /d "7-Zip.arj" /f >nul 2>&1
reg add "HKCR\7-Zip.arj" /ve /d "arj Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.arj\DefaultIcon" /ve /d "%SevenZipDLL%,4" /f >nul 2>&1
reg add "HKCR\7-Zip.arj\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.lzh" /ve /d "7-Zip.lzh" /f >nul 2>&1
reg add "HKCR\7-Zip.lzh" /ve /d "lzh Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.lzh\DefaultIcon" /ve /d "%SevenZipDLL%,6" /f >nul 2>&1
reg add "HKCR\7-Zip.lzh\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.lha" /ve /d "7-Zip.lha" /f >nul 2>&1
reg add "HKCR\7-Zip.lha" /ve /d "lha Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.lha\DefaultIcon" /ve /d "%SevenZipDLL%,6" /f >nul 2>&1
reg add "HKCR\7-Zip.lha\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.rpm" /ve /d "7-Zip.rpm" /f >nul 2>&1
reg add "HKCR\7-Zip.rpm" /ve /d "rpm Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.rpm\DefaultIcon" /ve /d "%SevenZipDLL%,10" /f >nul 2>&1
reg add "HKCR\7-Zip.rpm\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.deb" /ve /d "7-Zip.deb" /f >nul 2>&1
reg add "HKCR\7-Zip.deb" /ve /d "deb Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.deb\DefaultIcon" /ve /d "%SevenZipDLL%,11" /f >nul 2>&1
reg add "HKCR\7-Zip.deb\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.msi" /ve /d "7-Zip.msi" /f >nul 2>&1
reg add "HKCR\7-Zip.msi" /ve /d "msi Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.msi\DefaultIcon" /ve /d "%SevenZipDLL%,7" /f >nul 2>&1
reg add "HKCR\7-Zip.msi\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.vhd" /ve /d "7-Zip.vhd" /f >nul 2>&1
reg add "HKCR\7-Zip.vhd" /ve /d "vhd Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.vhd\DefaultIcon" /ve /d "%SevenZipDLL%,15" /f >nul 2>&1
reg add "HKCR\7-Zip.vhd\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.vmdk" /ve /d "7-Zip.vmdk" /f >nul 2>&1
reg add "HKCR\7-Zip.vmdk" /ve /d "vmdk Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.vmdk\DefaultIcon" /ve /d "%SevenZipDLL%,15" /f >nul 2>&1
reg add "HKCR\7-Zip.vmdk\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.z" /ve /d "7-Zip.z" /f >nul 2>&1
reg add "HKCR\7-Zip.z" /ve /d "z Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.z\DefaultIcon" /ve /d "%SevenZipDLL%,5" /f >nul 2>&1
reg add "HKCR\7-Zip.z\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.taz" /ve /d "7-Zip.taz" /f >nul 2>&1
reg add "HKCR\7-Zip.taz" /ve /d "taz Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.taz\DefaultIcon" /ve /d "%SevenZipDLL%,5" /f >nul 2>&1
reg add "HKCR\7-Zip.taz\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.cpio" /ve /d "7-Zip.cpio" /f >nul 2>&1
reg add "HKCR\7-Zip.cpio" /ve /d "cpio Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.cpio\DefaultIcon" /ve /d "%SevenZipDLL%,12" /f >nul 2>&1
reg add "HKCR\7-Zip.cpio\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.udf" /ve /d "7-Zip.udf" /f >nul 2>&1
reg add "HKCR\7-Zip.udf" /ve /d "udf Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.udf\DefaultIcon" /ve /d "%SevenZipDLL%,20" /f >nul 2>&1
reg add "HKCR\7-Zip.udf\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.xar" /ve /d "7-Zip.xar" /f >nul 2>&1
reg add "HKCR\7-Zip.xar" /ve /d "xar Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.xar\DefaultIcon" /ve /d "%SevenZipDLL%,19" /f >nul 2>&1
reg add "HKCR\7-Zip.xar\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

reg add "HKCR\.dmg" /ve /d "7-Zip.dmg" /f >nul 2>&1
reg add "HKCR\7-Zip.dmg" /ve /d "dmg Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.dmg\DefaultIcon" /ve /d "%SevenZipDLL%,17" /f >nul 2>&1
reg add "HKCR\7-Zip.dmg\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

set "P_STEP=6"
set "P_DESC=注册右键菜单..."
set "P_SUB="
call :draw_progress
reg add "HKCR\*\shellex\ContextMenuHandlers\7-Zip" /ve /d "%SevenZipCLSID%" /f >nul 2>&1
reg add "HKCR\Directory\shellex\ContextMenuHandlers\7-Zip" /ve /d "%SevenZipCLSID%" /f >nul 2>&1
reg add "HKCR\Directory\Background\shellex\ContextMenuHandlers\7-Zip" /ve /d "%SevenZipCLSID%" /f >nul 2>&1

set "P_STEP=7"
set "P_DESC=添加卸载信息..."
call :draw_progress
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "DisplayName" /d "7-Zip 24.09 (x64)" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "UninstallString" /d "\"%SevenZipPath%\Uninstall.exe\"" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "DisplayVersion" /d "24.09" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "Publisher" /d "Igor Pavlov" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "InstallLocation" /d "%SevenZipPath%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "NoModify" /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "NoRepair" /d "1" /f >nul 2>&1

set "P_STEP=8"
set "P_DESC=更新图标缓存..."
call :draw_progress
if exist "%SystemRoot%\System32\ie4uinit.exe" (
    "%SystemRoot%\System32\ie4uinit.exe" -ClearIconCache
) else (
    taskkill /f /im explorer.exe >nul 2>&1
    del /f /q "%localappdata%\IconCache.db" >nul 2>&1
    del /f /q "%localappdata%\Microsoft\Windows\Explorer\iconcache*.db" >nul 2>&1
    start explorer.exe
)

set "P_STEP=9"
set "P_DESC=安装 7-Zip 24.09"
set "P_SUB=[OK] 安装 + 文件关联 + 图标缓存"
call :draw_progress
timeout /t 2 /nobreak >nul

:module_7zip_done

REM ========================================
REM 模块2: 任务栏设置
REM ========================================

set "P_STEP=10"
set "P_CUR_MODULE=1"
set "P_DESC=任务栏设置..."
set "P_SUB=正在配置搜索框..."
call :draw_progress
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d "1" /f >nul 2>&1

set "P_STEP=11"
set "P_SUB=正在关闭资讯和兴趣..."
call :draw_progress
reg add "HKCU\Software\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v "ShellFeedsTaskbarViewMode" /t REG_DWORD /d "2" /f >nul 2>&1

set "P_STEP=12"
set "P_SUB=正在隐藏任务视图按钮..."
call :draw_progress
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d "0" /f >nul 2>&1

set "P_STEP=13"
set "P_DESC=任务栏设置"
set "P_SUB=[OK] 搜索图标 + 关闭资讯兴趣 + 隐藏任务视图"
call :draw_progress
timeout /t 2 /nobreak >nul

REM ========================================
REM 模块3: 卸载 OneDrive
REM ========================================

set "P_STEP=13"
set "P_CUR_MODULE=2"
set "P_DESC=卸载 OneDrive..."
set "P_SUB=正在停止 OneDrive 进程..."
call :draw_progress
taskkill /f /im OneDrive.exe >nul 2>&1

set "P_STEP=14"
set "P_SUB=正在卸载 OneDrive 程序..."
call :draw_progress
if exist "%SystemRoot%\SysWOW64\OneDriveSetup.exe" (
    "%SystemRoot%\SysWOW64\OneDriveSetup.exe" /uninstall >nul 2>&1
) else if exist "%SystemRoot%\System32\OneDriveSetup.exe" (
    "%SystemRoot%\System32\OneDriveSetup.exe" /uninstall >nul 2>&1
)

timeout /t 3 /nobreak >nul

set "P_STEP=15"
set "P_SUB=正在删除残留文件..."
call :draw_progress
if exist "%UserProfile%\OneDrive" rd "%UserProfile%\OneDrive" /s /q >nul 2>&1
if exist "%LocalAppData%\Microsoft\OneDrive" rd "%LocalAppData%\Microsoft\OneDrive" /s /q >nul 2>&1
if exist "%ProgramData%\Microsoft OneDrive" rd "%ProgramData%\Microsoft OneDrive" /s /q >nul 2>&1
if exist "C:\OneDriveTemp" rd "C:\OneDriveTemp" /s /q >nul 2>&1
del "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
del "%USERPROFILE%\Desktop\OneDrive.lnk" /f /q >nul 2>&1
del "%Public%\Desktop\OneDrive.lnk" /f /q >nul 2>&1

set "P_STEP=16"
set "P_SUB=正在清理注册表..."
call :draw_progress
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d "1" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1

set "P_STEP=17"
set "P_SUB=正在禁用计划任务..."
call :draw_progress
schtasks /change /tn "\Microsoft\Windows\OneDrive Reporting Task" /disable >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\OneDrive Reporting Task-S-1-5-21*" /disable >nul 2>&1

set "P_STEP=18"
set "P_DESC=卸载 OneDrive"
set "P_SUB=[OK] 进程终止 + 程序卸载 + 残留清理"
call :draw_progress
timeout /t 2 /nobreak >nul

REM ========================================
REM 模块4: 禁用 Cortana
REM ========================================

set "P_STEP=18"
set "P_CUR_MODULE=3"
set "P_DESC=禁用 Cortana..."
set "P_SUB=正在设置注册表策略..."
call :draw_progress
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul

set "P_STEP=19"
set "P_SUB=正在卸载 Cortana 应用包..."
call :draw_progress
powershell -Command "Get-AppxPackage *Cortana* | Remove-AppxPackage -ErrorAction SilentlyContinue"
powershell -Command "Get-AppxPackage -allusers Microsoft.549981C3F5F10 | Remove-AppxPackage -ErrorAction SilentlyContinue"

set "P_STEP=20"
set "P_SUB=正在终止相关进程..."
call :draw_progress
taskkill /f /im SearchApp.exe >nul 2>&1
taskkill /f /im Cortana.exe >nul 2>&1
taskkill /f /im SearchHost.exe >nul 2>&1

set "P_STEP=21"
set "P_SUB=正在禁用启动项..."
call :draw_progress
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "Cortana" /t REG_BINARY /d "030000000000000000000000" /f >nul 2>&1

set "P_STEP=22"
set "P_DESC=禁用 Cortana"
set "P_SUB=[OK] 注册表 + 应用卸载 + 进程终止"
call :draw_progress
timeout /t 2 /nobreak >nul

REM ========================================
REM 最后：重启资源管理器 + 显示完成
REM ========================================

set "P_STEP=23"
set "P_DESC=正在重启资源管理器..."
set "P_SUB=使所有更改生效..."
call :draw_progress
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul

REM 显示完成界面 100%
cls
echo.
echo  ==========================================
echo     Windows 10 一键部署工具 v1.0
echo  ==========================================
echo.
echo  所有部署任务已完成！
echo.
echo  [████████████████████████████████████████████] 100%%
echo.
echo  ------------------------------------------
echo  部署结果汇总：
echo  ------------------------------------------
echo.
echo    [1] [OK] 7-Zip 24.09 安装 + 文件关联
echo    [2] [OK] 任务栏设置（搜索图标+关闭资讯+隐藏任务视图）
echo    [3] [OK] OneDrive 卸载
echo    [4] [OK] Cortana 禁用
echo.
echo  ------------------------------------------
echo  建议重启计算机使所有更改完全生效。
echo  ------------------------------------------
echo.
echo  按任意键退出...
pause >nul
exit /b 0

REM ========================================
REM 进度条绘制子程序
REM 使用全局变量: P_STEP, P_DESC, P_SUB
REM ========================================

:draw_progress
set /a "P_PERCENT=(P_STEP * 100) / TOTAL_STEPS"
if !P_PERCENT! gtr 100 set "P_PERCENT=100"
set /a "P_FILLED=(P_PERCENT * BAR_WIDTH) / 100"
set /a "P_EMPTY=BAR_WIDTH - P_FILLED"

set "P_BAR="
for /L %%i in (1,1,!P_FILLED!) do set "P_BAR=!P_BAR!█"
set "P_SPC="
for /L %%i in (1,1,!P_EMPTY!) do set "P_SPC=!P_SPC!?"

if !P_PERCENT! lss 10 set "P_PCT=  !P_PERCENT!"
if !P_PERCENT! geq 10 if !P_PERCENT! lss 100 set "P_PCT= !P_PERCENT!"
if !P_PERCENT! geq 100 set "P_PCT=!P_PERCENT!"

cls
echo.
echo  ==========================================
echo     Windows 10 一键部署工具 v1.0
echo  ==========================================
echo.
echo  [!P_STEP!/!TOTAL_STEPS!] 模块!P_CUR_MODULE! !P_DESC!
if not "!P_SUB!"=="" echo    !P_SUB!
echo.
echo  [!P_BAR!!P_SPC!] !P_PCT!%%
echo.
echo  ------------------------------------------
echo    [1] 安装 7-Zip 24.09
echo    [2] 任务栏设置
echo    [3] 卸载 OneDrive
echo    [4] 禁用 Cortana
echo  ------------------------------------------
goto :eof
