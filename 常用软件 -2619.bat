chcp 65001

@echo off 

echo 开始安装常用软件，请勿关闭此程序窗口！！！

echo 开始安装常用软件，请勿关闭此程序窗口！！！

echo 开始安装常用软件，请勿关闭此程序窗口！！！

echo 1/13安装钉钉
start /wait %cd%\7.8.10-Release.250728001.exe /S /q

echo 2/13安装7z
start /wait %cd%\7z2301-x64.exe /S

echo 3/13安装百度输入法
start /wait %cd%\BaiduPinyinSetup_6.1.13.6.exe /S /q

echo 4/13安装看图软件
start /wait %cd%\HONEYVIEW-SETUP.EXE /S /q

echo 5/13安装PDF
start /wait %cd%\pdfgear_setup_v2.1.12.exe /VERYSILENT

echo 6/13安装QQ
start /wait %cd%\QQ_9.9.20_250724_x64_01.exe /S /q

echo 7/13安装微信
start /wait %cd%\WeChatWin.exe /S /q

echo 8/13安装企业微信
start /wait %cd%\WeCom_4.1.41.6006.exe /S /q

echo 9/13安装钉钉共享打印驱动
start /wait %cd%\cloud_printer_plugin.exe /quiet

echo 10/13 WPS
start /wait %cd%\WPS_Setup_24034.exe /S /q

echo 11/13 腾讯电脑管家
start /wait %cd%\PCMgr_Setup_215_6_23169_211_1RHEPFJLXX.exe /S /q

echo 12/13 Chrome
start /wait %cd%\ChromeSetup.exe --silent --install

echo 13/13 PotPlayer
start /wait %cd%\PotPlayerSetup64.exe /S /q

echo [1] 关闭：允许应用使用广告ID
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f

echo [2] 关闭：允许网站访问语言列表
reg add "HKCU\Control Panel\International\User Profile" /v "HttpAcceptLanguageOptOut" /t REG_DWORD /d 1 /f

echo [3] 关闭：允许Windows跟踪应用启动
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f

echo [4] 关闭：在设置中显示建议内容
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f

echo [5] 传递优化 - 关闭
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization /v DODownloadMode /t REG_DWORD /d 0 /f >nul & sc config DoSvc start= disabled >nul & net stop DoSvc >nul

echo [6] 后台应用 - 关闭
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f

echo [7] 禁用Game Bar
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f

echo [8] 禁用游戏模式
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\System\GameConfigStore" /v GameMode /t REG_DWORD /d 0 /f

echo [9] 桌面图标
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWORD /d 0 /f

echo[10] 电源高性能
rem 激活高性能电源计划
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
echo 当前活动电源计划：
powercfg /getactivescheme

echo[11] 关闭资讯和兴趣
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d 0 /f >nul

echo[12] 小键盘
reg add "HKEY_USERS\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f

echo ================================
echo           操作选择
echo ================================
echo.
echo   1. 重启计算机
echo   2. 退出程序
echo.
echo ================================

choice /c 12 /n /m "请选择操作 (1或2): "

if %errorlevel% equ 1 (
    echo 正在重启计算机...
    shutdown /r /t 0
) else if %errorlevel% equ 2 (
    echo 正在退出程序...
    exit
)

pause


软件类型	                  静默参数	                                                  说明
大部分安装程序	/S 或 /silent	                                标准静默安装
Chrome	               --silent --install                                          谷歌浏览器
微软安装包	/quiet /norestart	                                 MSI安装包
Inno Setup	/VERYSILENT /SUPPRESSMSGBOXES	Inno打包工具
NSIS安装包	/S	                                                Nullsoft安装包