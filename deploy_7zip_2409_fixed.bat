@echo off
setlocal enabledelayedexpansion

REM ========================================
REM 7-Zip 24.09 一键部署脚本（官方推荐文件关联方式）
REM 包含：强制管理员权限 + 安装 + 官方推荐文件关联 + 图标缓存更新
REM 使用方法：右键"以管理员身份运行"
REM ========================================

title 7-Zip 24.09 一键部署

REM ========================================
REM 第一部分：强制管理员权限检查
REM ========================================

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
echo   7-Zip 24.09 一键部署脚本
echo   管理员权限已确认 [OK]
echo ========================================
echo.

REM ========================================
REM 第二部分：检查安装包
REM ========================================

set "SCRIPT_DIR=%~dp0"
set "INSTALLER=%SCRIPT_DIR%7z2409-x64.exe"
set VERSION=24.09
set "SevenZipPath=C:\Program Files\7-Zip"
set "SevenZipFM=%SevenZipPath%\7zFM.exe"
set "SevenZipDLL=%SevenZipPath%\7z.dll"

echo [1/5] 检查安装包...
if exist "%INSTALLER%" (
    echo   [OK] 安装包存在
) else (
    echo.
    echo   ========================================
    echo   错误：安装包不存在！
    echo   ========================================
    echo.
    echo   请下载 7z2409-x64.exe 到：
    echo   %SCRIPT_DIR%
    echo.
    echo   下载地址：https://www.7-zip.org/download.html
    echo.
    pause >nul
    exit /b 1
)

REM ========================================
REM 第三部分：安装 7-Zip
REM ========================================

echo.
echo [2/5] 安装 7-Zip %VERSION%...
echo   安装目录：%SevenZipPath%

"%INSTALLER%" /S /D="%SevenZipPath%"

if errorlevel 1 (
    echo.
    echo   [ERROR] 安装失败！错误代码：%errorlevel%
    pause >nul
    exit /b 1
) else (
    echo   [OK] 安装成功
)

REM 等待安装完成
timeout /t 3 /nobreak >nul

REM ========================================
REM 第四部分：官方推荐方式配置文件关联
REM ========================================

echo.
echo [3/5] 配置文件关联和上下文菜单...

REM 检查 7-Zip 是否安装成功
if not exist "%SevenZipFM%" (
    echo   [ERROR] 7-Zip 未正确安装
    echo   预期路径：%SevenZipFM%
    pause >nul
    exit /b 1
)

REM 注册 7-Zip DLL（Shell 扩展）
echo   注册 7-Zip Shell 扩展...
regsvr32 /s "%SevenZipDLL%"

REM 设置变量
set "SevenZipCLSID={23170F69-40C1-278A-1000-000100020000}"

REM ========================================
REM 为每个格式创建标准的 7-Zip.{ext} ProgID
REM 这是 7-Zip 官方推荐的文件关联方式
REM ========================================

echo   创建文件类型关联...

REM --- 7z 格式 ---
reg add "HKCR\.7z" /ve /d "7-Zip.7z" /f >nul 2>&1
reg add "HKCR\7-Zip.7z" /ve /d "7z Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.7z\DefaultIcon" /ve /d "%SevenZipDLL%,0" /f >nul 2>&1
reg add "HKCR\7-Zip.7z\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- zip 格式 ---
reg add "HKCR\.zip" /ve /d "7-Zip.zip" /f >nul 2>&1
reg add "HKCR\7-Zip.zip" /ve /d "zip Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.zip\DefaultIcon" /ve /d "%SevenZipDLL%,1" /f >nul 2>&1
reg add "HKCR\7-Zip.zip\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- tar 格式 ---
reg add "HKCR\.tar" /ve /d "7-Zip.tar" /f >nul 2>&1
reg add "HKCR\7-Zip.tar" /ve /d "tar Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.tar\DefaultIcon" /ve /d "%SevenZipDLL%,13" /f >nul 2>&1
reg add "HKCR\7-Zip.tar\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- gz 格式 ---
reg add "HKCR\.gz" /ve /d "7-Zip.gz" /f >nul 2>&1
reg add "HKCR\7-Zip.gz" /ve /d "gz Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.gz\DefaultIcon" /ve /d "%SevenZipDLL%,14" /f >nul 2>&1
reg add "HKCR\7-Zip.gz\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- bz2 格式 ---
reg add "HKCR\.bz2" /ve /d "7-Zip.bz2" /f >nul 2>&1
reg add "HKCR\7-Zip.bz2" /ve /d "bz2 Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.bz2\DefaultIcon" /ve /d "%SevenZipDLL%,2" /f >nul 2>&1
reg add "HKCR\7-Zip.bz2\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- xz 格式 ---
reg add "HKCR\.xz" /ve /d "7-Zip.xz" /f >nul 2>&1
reg add "HKCR\7-Zip.xz" /ve /d "xz Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.xz\DefaultIcon" /ve /d "%SevenZipDLL%,23" /f >nul 2>&1
reg add "HKCR\7-Zip.xz\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- tar.gz 格式 ---
reg add "HKCR\.tgz" /ve /d "7-Zip.tgz" /f >nul 2>&1
reg add "HKCR\7-Zip.tgz" /ve /d "tar.gz Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.tgz\DefaultIcon" /ve /d "%SevenZipDLL%,14" /f >nul 2>&1
reg add "HKCR\7-Zip.tgz\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- tar.bz2 格式 ---
reg add "HKCR\.tbz2" /ve /d "7-Zip.tbz2" /f >nul 2>&1
reg add "HKCR\7-Zip.tbz2" /ve /d "tar.bz2 Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.tbz2\DefaultIcon" /ve /d "%SevenZipDLL%,2" /f >nul 2>&1
reg add "HKCR\7-Zip.tbz2\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- wim 格式 ---
reg add "HKCR\.wim" /ve /d "7-Zip.wim" /f >nul 2>&1
reg add "HKCR\7-Zip.wim" /ve /d "wim Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.wim\DefaultIcon" /ve /d "%SevenZipDLL%,15" /f >nul 2>&1
reg add "HKCR\7-Zip.wim\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- 001 格式 ---
reg add "HKCR\.001" /ve /d "7-Zip.001" /f >nul 2>&1
reg add "HKCR\7-Zip.001" /ve /d "001 Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.001\DefaultIcon" /ve /d "%SevenZipDLL%,9" /f >nul 2>&1
reg add "HKCR\7-Zip.001\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

echo   关联解压格式...

REM --- rar 格式 ---
reg add "HKCR\.rar" /ve /d "7-Zip.rar" /f >nul 2>&1
reg add "HKCR\7-Zip.rar" /ve /d "rar Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.rar\DefaultIcon" /ve /d "%SevenZipDLL%,3" /f >nul 2>&1
reg add "HKCR\7-Zip.rar\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- iso 格式 ---
reg add "HKCR\.iso" /ve /d "7-Zip.iso" /f >nul 2>&1
reg add "HKCR\7-Zip.iso" /ve /d "iso Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.iso\DefaultIcon" /ve /d "%SevenZipDLL%,8" /f >nul 2>&1
reg add "HKCR\7-Zip.iso\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- cab 格式 ---
reg add "HKCR\.cab" /ve /d "7-Zip.cab" /f >nul 2>&1
reg add "HKCR\7-Zip.cab" /ve /d "cab Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.cab\DefaultIcon" /ve /d "%SevenZipDLL%,7" /f >nul 2>&1
reg add "HKCR\7-Zip.cab\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- arj 格式 ---
reg add "HKCR\.arj" /ve /d "7-Zip.arj" /f >nul 2>&1
reg add "HKCR\7-Zip.arj" /ve /d "arj Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.arj\DefaultIcon" /ve /d "%SevenZipDLL%,4" /f >nul 2>&1
reg add "HKCR\7-Zip.arj\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- lzh 格式 ---
reg add "HKCR\.lzh" /ve /d "7-Zip.lzh" /f >nul 2>&1
reg add "HKCR\7-Zip.lzh" /ve /d "lzh Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.lzh\DefaultIcon" /ve /d "%SevenZipDLL%,6" /f >nul 2>&1
reg add "HKCR\7-Zip.lzh\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- lha 格式 ---
reg add "HKCR\.lha" /ve /d "7-Zip.lha" /f >nul 2>&1
reg add "HKCR\7-Zip.lha" /ve /d "lha Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.lha\DefaultIcon" /ve /d "%SevenZipDLL%,6" /f >nul 2>&1
reg add "HKCR\7-Zip.lha\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- rpm 格式 ---
reg add "HKCR\.rpm" /ve /d "7-Zip.rpm" /f >nul 2>&1
reg add "HKCR\7-Zip.rpm" /ve /d "rpm Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.rpm\DefaultIcon" /ve /d "%SevenZipDLL%,10" /f >nul 2>&1
reg add "HKCR\7-Zip.rpm\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- deb 格式 ---
reg add "HKCR\.deb" /ve /d "7-Zip.deb" /f >nul 2>&1
reg add "HKCR\7-Zip.deb" /ve /d "deb Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.deb\DefaultIcon" /ve /d "%SevenZipDLL%,11" /f >nul 2>&1
reg add "HKCR\7-Zip.deb\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- msi 格式 ---
reg add "HKCR\.msi" /ve /d "7-Zip.msi" /f >nul 2>&1
reg add "HKCR\7-Zip.msi" /ve /d "msi Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.msi\DefaultIcon" /ve /d "%SevenZipDLL%,7" /f >nul 2>&1
reg add "HKCR\7-Zip.msi\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- vhd 格式 ---
reg add "HKCR\.vhd" /ve /d "7-Zip.vhd" /f >nul 2>&1
reg add "HKCR\7-Zip.vhd" /ve /d "vhd Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.vhd\DefaultIcon" /ve /d "%SevenZipDLL%,15" /f >nul 2>&1
reg add "HKCR\7-Zip.vhd\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- vmdk 格式 ---
reg add "HKCR\.vmdk" /ve /d "7-Zip.vmdk" /f >nul 2>&1
reg add "HKCR\7-Zip.vmdk" /ve /d "vmdk Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.vmdk\DefaultIcon" /ve /d "%SevenZipDLL%,15" /f >nul 2>&1
reg add "HKCR\7-Zip.vmdk\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- z 格式 ---
reg add "HKCR\.z" /ve /d "7-Zip.z" /f >nul 2>&1
reg add "HKCR\7-Zip.z" /ve /d "z Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.z\DefaultIcon" /ve /d "%SevenZipDLL%,5" /f >nul 2>&1
reg add "HKCR\7-Zip.z\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- taz (tar.Z) 格式 ---
reg add "HKCR\.taz" /ve /d "7-Zip.taz" /f >nul 2>&1
reg add "HKCR\7-Zip.taz" /ve /d "taz Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.taz\DefaultIcon" /ve /d "%SevenZipDLL%,5" /f >nul 2>&1
reg add "HKCR\7-Zip.taz\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- cpio 格式 ---
reg add "HKCR\.cpio" /ve /d "7-Zip.cpio" /f >nul 2>&1
reg add "HKCR\7-Zip.cpio" /ve /d "cpio Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.cpio\DefaultIcon" /ve /d "%SevenZipDLL%,12" /f >nul 2>&1
reg add "HKCR\7-Zip.cpio\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- udf 格式 ---
reg add "HKCR\.udf" /ve /d "7-Zip.udf" /f >nul 2>&1
reg add "HKCR\7-Zip.udf" /ve /d "udf Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.udf\DefaultIcon" /ve /d "%SevenZipDLL%,20" /f >nul 2>&1
reg add "HKCR\7-Zip.udf\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- xar 格式 ---
reg add "HKCR\.xar" /ve /d "7-Zip.xar" /f >nul 2>&1
reg add "HKCR\7-Zip.xar" /ve /d "xar Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.xar\DefaultIcon" /ve /d "%SevenZipDLL%,19" /f >nul 2>&1
reg add "HKCR\7-Zip.xar\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM --- dmg 格式 ---
reg add "HKCR\.dmg" /ve /d "7-Zip.dmg" /f >nul 2>&1
reg add "HKCR\7-Zip.dmg" /ve /d "dmg Archive" /f >nul 2>&1
reg add "HKCR\7-Zip.dmg\DefaultIcon" /ve /d "%SevenZipDLL%,17" /f >nul 2>&1
reg add "HKCR\7-Zip.dmg\shell\open\command" /ve /d "\"%SevenZipFM%\" \"%%1\"" /f >nul 2>&1

REM ========================================
REM 注册右键上下文菜单
REM ========================================

echo   注册右键菜单...

REM 文件右键菜单
reg add "HKCR\*\shellex\ContextMenuHandlers\7-Zip" /ve /d "%SevenZipCLSID%" /f >nul 2>&1

REM 目录右键菜单
reg add "HKCR\Directory\shellex\ContextMenuHandlers\7-Zip" /ve /d "%SevenZipCLSID%" /f >nul 2>&1

REM 目录背景右键菜单
reg add "HKCR\Directory\Background\shellex\ContextMenuHandlers\7-Zip" /ve /d "%SevenZipCLSID%" /f >nul 2>&1

REM ========================================
REM 添加卸载信息
REM ========================================

echo   添加卸载信息...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "DisplayName" /d "7-Zip 24.09 (x64)" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "UninstallString" /d "\"%SevenZipPath%\Uninstall.exe\"" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "DisplayVersion" /d "24.09" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "Publisher" /d "Igor Pavlov" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "InstallLocation" /d "%SevenZipPath%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "NoModify" /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "NoRepair" /d "1" /f >nul 2>&1

echo   [OK] 文件关联和上下文菜单配置完成

REM ========================================
REM 第五部分：更新图标缓存
REM ========================================

echo.
echo [4/5] 更新图标缓存...

if exist "%SystemRoot%\System32\ie4uinit.exe" (
    echo   使用 ie4uinit.exe 清除图标缓存...
    "%SystemRoot%\System32\ie4uinit.exe" -ClearIconCache
    echo   [OK] 图标缓存已清除
) else (
    echo   重启资源管理器刷新图标...
    taskkill /f /im explorer.exe >nul 2>&1
    del /f /q "%localappdata%\IconCache.db" >nul 2>&1
    del /f /q "%localappdata%\Microsoft\Windows\Explorer\iconcache*.db" >nul 2>&1
    start explorer.exe
    echo   [OK] 资源管理器已重启
)

timeout /t 2 /nobreak >nul

REM ========================================
REM 完成
REM ========================================

echo.
echo [5/5] 部署完成！
echo.
echo ========================================
echo   7-Zip %VERSION% 部署成功！
echo ========================================
echo.
echo 已完成：
echo   [OK] 7-Zip 安装（系统级）
echo   [OK] 文件关联配置（25+ 格式）
echo   [OK] 右键菜单配置
echo   [OK] 图标缓存更新
echo.
echo 安装目录：%SevenZipPath%
echo.
echo 按任意键退出...
pause >nul