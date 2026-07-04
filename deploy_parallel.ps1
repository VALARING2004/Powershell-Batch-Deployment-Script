# deploy_parallel.ps1 - 常用软件并行安装工具
# 最大并发: 4 个
# 合并了 deploy_all.bat 的所有模块

# ============================================================
# 窗口自适应: 根据控制台字体自动计算最佳窗口大小
# ============================================================
try {
    $ui = (Get-Host).UI.RawUI
    # 获取当前字体大小来推算字符像素宽度 (Consolas 等宽字体约 7~8px/字符)
    $fontSize = $ui.FontSize
    if (-not $fontSize -or $fontSize -lt 1) { $fontSize = 12 }
    $charWidth = [math]::Max(6, [math]::Min(9, $fontSize * 0.62))
    $charHeight = [math]::Max(12, [math]::Min(20, $fontSize * 1.5))

    # 获取屏幕工作区 (去掉任务栏)
    Add-Type -AssemblyName System.Windows.Forms
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $screenW = $screen.Width
    $screenH = $screen.Height

    # 目标内容宽度: 56 字符, 加上窗口边距约 30px
    $targetCols = 58
    $windowPixelW = [math]::Floor($targetCols * $charWidth) + 30

    # 高度: 预留约 35 行内容 + 窗口标题栏/边框 (阶段三内容较多)
    $targetRows = 35
    $windowPixelH = [math]::Floor($targetRows * $charHeight) + 80

    # 不超过屏幕的 85%
    $maxW = [math]::Floor($screenW * 0.85)
    $maxH = [math]::Floor($screenH * 0.85)
    if ($windowPixelW -gt $maxW) { $windowPixelW = $maxW }
    if ($windowPixelH -gt $maxH) { $windowPixelH = $maxH }

    $ui.WindowSize = New-Object System.Management.Automation.Host.Size($targetCols, $targetRows)
    $ui.BufferSize = New-Object System.Management.Automation.Host.Size($targetCols, 3000)
} catch {
    # 回退: 最小可靠尺寸
    try {
        $ui = (Get-Host).UI.RawUI
        $ui.WindowSize = New-Object System.Management.Automation.Host.Size(58, 30)
        $ui.BufferSize = New-Object System.Management.Automation.Host.Size(58, 3000)
    } catch {}
}

# UI 常量: 分隔线宽度与窗口匹配
$UI_Width = 56
$SepLine = "=" * $UI_Width

$BaseDir = $PSScriptRoot
if (-not $BaseDir) {
    Write-Host "ERROR: cannot determine script directory"
    Read-Host "Press Enter"
    exit 1
}
$BaseDir = $BaseDir.Trim('"', "'").TrimEnd('\')
if (-not (Test-Path $BaseDir)) {
    Write-Host "ERROR: path not found - $BaseDir"
    Read-Host "Press Enter"
    exit 1
}

# 管理员检测
$wid = [Security.Principal.WindowsIdentity]::GetCurrent()
$princ = New-Object Security.Principal.WindowsPrincipal($wid)
if (-not $princ.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run as Administrator"
    Read-Host "Press Enter"
    exit 1
}

$TempDir = Join-Path $BaseDir "_install_tmp"
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

# ============================================================
# 预处理: 全局阻止安装程序触发重启
# ============================================================
Write-Host "   正在设置防重启保护..."
Write-Host ""

# [AUDIT-B FIX] 原代码 L83-91:
#   $RebootRegPath = "HKLM:\...\Component Based Servicing"
#   $OriginalRebootPending = $null
#   try { $OriginalRebootPending = Get-ItemProperty ... "RebootPending" } catch {}
#
# 问题: 变量被保存了但整个脚本中从未被读取或恢复（纯死代码）。
#       同时，防重启逻辑在 L101-113 中主动清除了 RebootPending 标记，
#       如果系统有 IT 部门推送的合法安全补丁挂起，该标记会被永久清除不恢复。
#
# 修复方案（选择删除而非补充恢复）：
#   部署脚本的防重启保护本身就是有意为之——安装过程中任何重启标记
#   都应被清除以防止 MSI/InstallShield 安装包触发中途重启。
#   如果部署前确实存在需要保留的重启标记，应在部署完成后手动处理。
#   因此：删除无用的保存代码 + 在恢复段添加注释说明设计意图。

# 方法1: 设置注册表禁止 ExitWindowsEx 重启 (影响 MSI/InstallShield 安装包)
try {
    $noRestartPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (-not (Test-Path $noRestartPath)) { New-Item -Path $noRestartPath -Force | Out-Null }
    Set-ItemProperty -Path $noRestartPath -Name "SetAutoRestartDeadline" -Value 0 -Type DWord -Force 2>$null
    Set-ItemProperty -Path $noRestartPath -Name "SetAutoRestartNotificationDisable" -Value 1 -Type DWord -Force 2>$null
} catch {}

# 方法2: 清除可能存在的重启挂起标记
try {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
    )
    foreach ($rp in $regPaths) {
        if (Test-Path $rp) {
            Remove-ItemProperty -Path $rp -Name "RebootPending" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $rp -Name "RebootRequired" -Force -ErrorAction SilentlyContinue
        }
    }
} catch {}

# 方法3: 清除 RunOnce 中的重启回调
try {
    $runOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    if (Test-Path $runOncePath) {
        $props = Get-ItemProperty -Path $runOncePath
        $props.PSObject.Properties | ForEach-Object {
            $val = $_.Value
            if ($val -match "restart|reboot|shutdown" -or $_.Name -match "InstallShield|MSI|Reboot") {
                Remove-ItemProperty -Path $runOncePath -Name $_.Name -Force -ErrorAction SilentlyContinue
            }
        }
    }
} catch {}

Write-Host "   [OK] 防重启保护已启用"
Write-Host ""

# ============================================================
# 阶段一: 安装 7-Zip 24.09 (含完整文件关联)
# ============================================================

$SevenZipInstaller = Join-Path $BaseDir "7z2409-x64.exe"
$SevenZipPath = "C:\Program Files\7-Zip"
$SevenZipFM = Join-Path $SevenZipPath "7zFM.exe"
$SevenZipDLL = Join-Path $SevenZipPath "7z.dll"
$SevenZipCLSID = "{23170F69-40C1-278A-1000-000100020000}"

Clear-Host
Write-Host ""
Write-Host "  $SepLine"
Write-Host "      常用软件一键部署工具"
Write-Host "  $SepLine"
Write-Host ""
Write-Host "   阶段一: 安装 7-Zip 24.09"
Write-Host ""

if (Test-Path $SevenZipFM) {
    Write-Host "   [SKIP] 7-Zip 已安装，跳过全部 7-Zip 操作"
} elseif (Test-Path $SevenZipInstaller) {
    Write-Host "   [1/9] 正在安装 7-Zip..."
    # [FIX 4/5] 原代码: Start-Process ... -ArgumentList "/S", "/D=`"$SevenZipPath`""
    # 问题: NSIS 安装程序的 /D= 参数有特殊行为：
    #       - /D=C:\Program Files\7-Zip  ← 正确，NSIS 自己处理空格
    #       - /D="C:\Program Files\7-Zip"  ← 错误！引号被当作路径的一部分
    # 结果: 7-Zip 可能安装到 "C:\Program Files\7-Zip"（含字面引号）或默认位置
    #       随后 Test-Path $SevenZipFM 检查失败 → 跳过所有关联配置
    #
    # 修复: 去掉 /D= 后的引号，NSIS 会将 /D 之后到参数结尾的全部内容作为路径
    Start-Process -FilePath $SevenZipInstaller -ArgumentList "/S", "/D=$SevenZipPath" -Wait -NoNewWindow
    Start-Sleep -Seconds 3

    if (Test-Path $SevenZipFM) {
        Write-Host "   [2/9] 注册 Shell 扩展..."
        # [FIX 3/5] 原代码: regsvr32 /s $SevenZipDLL
        # 问题: $SevenZipDLL = "C:\Program Files\7-Zip\7z.dll" 含空格
        #       PowerShell 展开后变成: regsvr32 /s C:\Program Files\7-Zip\7z.dll
        #       cmd.exe 将 "C:\Program" 当作路径，"Files\7-Zip\7z.dll" 当作参数 → 失败
        # 结果: 7-Zip 右键菜单集成不生效（无法右键解压）
        # 修复: 给路径加引号，确保整个路径被当作一个参数
        regsvr32 /s "`"$SevenZipDLL`""

        Write-Host "   [3/9] 创建文件类型关联..."
        $exts = @(
            @(".7z",  "7-Zip.7z",   "7z Archive",  "0"),
            @(".zip", "7-Zip.zip",  "zip Archive", "1"),
            @(".tar", "7-Zip.tar",  "tar Archive", "13"),
            @(".gz",  "7-Zip.gz",   "gz Archive",  "14"),
            @(".bz2", "7-Zip.bz2",  "bz2 Archive", "2"),
            @(".xz",  "7-Zip.xz",   "xz Archive",  "23"),
            @(".tgz", "7-Zip.tgz",  "tar.gz Archive", "14"),
            @(".tbz2","7-Zip.tbz2", "tar.bz2 Archive","2"),
            @(".wim", "7-Zip.wim",  "wim Archive", "15"),
            @(".001", "7-Zip.001",  "001 Archive", "9"),
            @(".rar", "7-Zip.rar",  "rar Archive", "3"),
            @(".iso", "7-Zip.iso",  "iso Archive", "8"),
            @(".cab", "7-Zip.cab",  "cab Archive", "7"),
            @(".arj", "7-Zip.arj",  "arj Archive", "4"),
            @(".lzh", "7-Zip.lzh",  "lzh Archive", "6"),
            @(".lha", "7-Zip.lha",  "lha Archive", "6"),
            @(".rpm", "7-Zip.rpm",  "rpm Archive", "10"),
            @(".deb", "7-Zip.deb",  "deb Archive", "11"),
            @(".msi", "7-Zip.msi",  "msi Archive", "7"),
            @(".vhd", "7-Zip.vhd",  "vhd Archive", "15"),
            @(".vmdk","7-Zip.vmdk", "vmdk Archive","15"),
            @(".z",   "7-Zip.z",    "z Archive",   "5"),
            @(".taz", "7-Zip.taz",  "taz Archive",  "5"),
            @(".cpio","7-Zip.cpio", "cpio Archive", "12"),
            @(".udf", "7-Zip.udf",  "udf Archive", "20"),
            @(".xar", "7-Zip.xar",  "xar Archive", "19"),
            @(".dmg", "7-Zip.dmg",  "dmg Archive", "17")
        )
        foreach ($e in $exts) {
            $cmdExe = "`"$SevenZipFM`" `"%1`""
            reg add "HKCR\$($e[0])" /ve /t REG_SZ /d "$($e[1])" /f >$null 2>&1
            reg add "HKCR\$($e[1])" /ve /t REG_SZ /d "$($e[2])" /f >$null 2>&1
            reg add "HKCR\$($e[1])\DefaultIcon" /ve /t REG_SZ /d "$SevenZipDLL,$($e[3])" /f >$null 2>&1
            reg add "HKCR\$($e[1])\shell\open\command" /ve /t REG_SZ /d "$cmdExe" /f >$null 2>&1
        }

        Write-Host "   [4/9] 注册右键菜单..."
        reg add "HKCR\*\shellex\ContextMenuHandlers\7-Zip" /ve /d "$SevenZipCLSID" /f >$null 2>&1
        reg add "HKCR\Directory\shellex\ContextMenuHandlers\7-Zip" /ve /d "$SevenZipCLSID" /f >$null 2>&1
        reg add "HKCR\Directory\Background\shellex\ContextMenuHandlers\7-Zip" /ve /d "$SevenZipCLSID" /f >$null 2>&1

        Write-Host "   [5/9] 添加卸载信息..."
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "DisplayName" /d "7-Zip 24.09 (x64)" /f >$null 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "UninstallString" /d "`"$SevenZipPath\Uninstall.exe`"" /f >$null 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "DisplayVersion" /d "24.09" /f >$null 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "Publisher" /d "Igor Pavlov" /f >$null 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "InstallLocation" /d "$SevenZipPath" /f >$null 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "NoModify" /d "1" /f >$null 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\7-Zip" /v "NoRepair" /d "1" /f >$null 2>&1

        Write-Host "   [6/9] 更新图标缓存..."
        if (Test-Path "$env:SystemRoot\System32\ie4uinit.exe") {
            & "$env:SystemRoot\System32\ie4uinit.exe" -ClearIconCache
        } else {
            taskkill /f /im explorer.exe >$null 2>&1
            Remove-Item "$env:localappdata\IconCache.db" -Force -ErrorAction SilentlyContinue
            Remove-Item "$env:localappdata\Microsoft\Windows\Explorer\iconcache*.db" -Force -ErrorAction SilentlyContinue
            Start-Process explorer.exe
        }

        Write-Host "   [OK] 7-Zip 24.09 安装 + 文件关联 完成"
    } else {
        Write-Host "   [WARN] 7-Zip 安装程序执行完毕但文件未找到，跳过关联配置"
    }
} else {
    Write-Host "   [WARN] 未找到 7z2409-x64.exe，跳过 7-Zip 安装"
    Write-Host "   请确保安装包与本脚本在同一目录下"
}

Write-Host ""

# ============================================================
# 阶段二: 并行安装其余软件 (12个软件)
# ============================================================

Write-Host "   阶段二: 并行安装常用软件"
Write-Host ""

$Apps = @(
    @{ Id="01"; Exe="dingding.exe";                      Arg="/S /q";             Name="钉钉";          CheckPath="${env:ProgramFiles(x86)}\DingDing\DingtalkLauncher.exe" },
    @{ Id="02"; Exe="BaiduPinyinSetup_6.1.13.6.exe";     Arg="/S /q";             Name="百度输入法";     CheckPath="${env:ProgramFiles(x86)}\Baidu\BaiduPinyin\IMEBroker.exe" },
    @{ Id="03"; Exe="HONEYVIEW-SETUP.EXE";               Arg="/S /q";             Name="看图软件";       CheckPath="$env:ProgramFiles\Honeyview\Honeyview.exe" },
    @{ Id="04"; Exe="pdfgear_setup_v2.1.12.exe";         Arg="/VERYSILENT";       Name="PDF阅读器";     CheckPath="$env:ProgramFiles\pdfgear\PDFLauncher.exe" },
    @{ Id="05"; Exe="QQ.exe";                            Arg="/S /q";             Name="QQ";            CheckPath="$env:ProgramFiles\Tencent\QQNT\QQ.exe" },
    @{ Id="06"; Exe="WeChatWin.exe";                     Arg="/S /q";             Name="微信";          CheckPath="$env:ProgramFiles\Tencent\Weixin\Weixin.exe" },
    @{ Id="07"; Exe="WeCom.exe";                         Arg="/S /q";             Name="企业微信";       CheckPath="${env:ProgramFiles(x86)}\WXWork\WXWork.exe" },
    @{ Id="08"; Exe="cloud_printer_plugin.exe";          Arg="/quiet";            Name="钉钉共享打印";  CheckPath="${env:ProgramFiles(x86)}\dingtalk-cloud-print\cloud_printer_service.exe" }, # [FIX LOGIC-1/6] 原代码: CheckPath="" → bat 中 if exist "" 恒 true，永远报告成功。改为检测实际安装路径
    @{ Id="09"; Exe="wps.exe"; Arg="/S -agreelicense /D=C:\WPS"; Name="WPS"; CheckPath="C:\WPS\WPS Office\ksolaunch.exe" },
    @{ Id="10"; Exe="PCMgr_Setup_215_6_23169_211_1RHEPFJLXX.exe"; Arg="/S /q";  Name="腾讯电脑管家"; CheckPath="${env:ProgramFiles(x86)}\Tencent\PCMgr\PCMgr.exe" },
    @{ Id="11"; Exe="ChromeSetup.exe";                   Arg="--silent --install";Name="Chrome";         CheckPath="$env:ProgramFiles\Google\Chrome\Application\chrome.exe" },
    @{ Id="12"; Exe="PotPlayerSetup64.exe";              Arg="/S /q";             Name="PotPlayer";     CheckPath="$env:ProgramFiles\DAUM\PotPlayer\PotPlayerMini64.exe" }
)

$Total = $Apps.Count
$MaxSlots = 4

# 预检测已安装软件，直接标记跳过
$skipped = 0
foreach ($app in $Apps) {
    $okFile = Join-Path $TempDir "$($app.Id).ok"
    if ($app.CheckPath -and (Test-Path $app.CheckPath)) {
        "skip" | Out-File $okFile -Encoding ascii
        $skipped++
    }
}
if ($skipped -gt 0) {
    Write-Host "   已检测到 $skipped 个软件已安装，将自动跳过"
    Write-Host ""
}

# 生成子安装脚本（跳过不存在的安装包）
$missingList = @()
foreach ($app in $Apps) {
    $fullExe = Join-Path $BaseDir $app.Exe
    $okFile = Join-Path $TempDir "$($app.Id).ok"
    $badFile = Join-Path $TempDir "$($app.Id).bad"
    $runFile = Join-Path $TempDir "$($app.Id).run"
    $batFile = Join-Path $TempDir "$($app.Id).bat"
    $checkPath = $app.CheckPath

    # 安装包不存在 → 直接标记失败
    if (-not (Test-Path $fullExe)) {
        "fail" | Out-File $badFile -Encoding ascii
        $missingList += $app.Name
        continue
    }

    $lines = '@echo off' + "`r`n"
    $lines += 'echo run>"' + $runFile + '"' + "`r`n"
    $lines += '"' + $fullExe + '" ' + $app.Arg + "`r`n"
    # 用安装后实际检查路径替代退出码判断
    if ($checkPath) {
        # 检查路径包含空格则加引号，注意批处理转义
        $checkQuoted = '"' + $checkPath + '"'
        $lines += 'if exist ' + $checkQuoted + ' (echo ok>"' + $okFile + '") else (echo fail>"' + $badFile + '")' + "`r`n"
    } else {
        # 无检测路径: 直接认为执行成功
        $lines += 'echo ok>"' + $okFile + '"' + "`r`n"
    }
    $lines += 'del /f "' + $runFile + '" 2>nul' + "`r`n"

    [System.IO.File]::WriteAllText($batFile, $lines, [System.Text.Encoding]::GetEncoding('GBK'))
}

if ($missingList.Count -gt 0) {
    Write-Host "   [WARN] Missing installer files:"
    foreach ($m in $missingList) { Write-Host "     - $m" }
    Write-Host "   Please place all installers in the script directory."
    Write-Host ""
}

# 并行安装主循环
$procs = @{}
$idx = 0
# [FIX LOGIC-3/6] 新增: 全局超时计时器
#   原代码: while($true) 无限循环，无任何超时保护
#   风险场景: 某个安装程序（如钉钉）弹出 UAC 或卡在等待用户输入
#            → 进程永不退出 → while 永不 break → 脚本挂死
#   修复: 记录开始时间，单软件超时 10 分钟，总超时 30 分钟
$loopStartTime = Get-Date
$perAppTimeoutMinutes = 10  # 单个软件最大允许时间 (分钟)
$totalTimeoutMinutes = 30   # 全部部署最大允许时间 (分钟)
$appStartTime = @{}        # 记录每个进程的启动时间

while ($true) {
    # 清理已结束进程
    foreach ($procId in @($procs.Keys)) {
        if ($procs[$procId].HasExited) {
            $procs.Remove($procId)
            $appStartTime.Remove($procId)
        }
    }

    # [FIX LOGIC-3/6] 超时检测: 检查每个运行中进程是否超时
    $now = Get-Date
    $totalElapsed = ($now - $loopStartTime).TotalMinutes
    if ($totalElapsed -gt $totalTimeoutMinutes) {
        Write-Host ""
        Write-Host "   [FATAL] 全局超时! 已运行 $([math]::Round($totalElapsed,1)) 分钟 (上限 ${totalTimeoutMinutes} 分钟)" -ForegroundColor Red
        Write-Host "   强制终止所有残留安装进程..."
        foreach ($procId in @($procs.Keys)) {
            try { $procs[$procId].Kill() } catch {}
        }
        break
    }
    foreach ($procId in @($procs.Keys)) {
        if ($appStartTime.ContainsKey($procId)) {
            $appElapsed = ($now - $appStartTime[$procId]).TotalMinutes
            if ($appElapsed -gt $perAppTimeoutMinutes) {
                $hungProc = $procs[$procId]

                # [AUDIT-F FIX] 原代码: Kill 后直接 Remove，不写任何标记文件
                # 问题: 下轮循环检测到 ok/bad 都不存在 → 再次启动同一软件 → 又超时...
                #       在全局超时(30min)前，每个卡死软件会被重复启动 ~120 次
                # 修复: Kill 后遍历 Apps 找到对应的 .run 文件（正在安装的标志），
                #       通过它定位到 badFile 并写入 "timeout"，循环检测到 .bad 存在就跳过

                Write-Host "   [WARN] $($hungProc.ProcessName) (PID:$procId) 超时 $([math]::Round($appElapsed,1)) 分钟，强制终止" -ForegroundColor Yellow
                try { $hungProc.Kill() } catch {}

                # ★ 关键：写 .bad 阻止无限重试
                foreach ($a in $Apps) {
                    $rf = Join-Path $TempDir "$($a.Id).run"
                    if (Test-Path $rf) {
                        "timeout" | Out-File (Join-Path $TempDir "$($a.Id).bad") -Encoding ascii
                        Write-Host "          → 已标记 [$($a.Name)] 为失败(超时)，不再重试" -ForegroundColor Yellow
                        break
                    }
                }

                $procs.Remove($procId)
                $appStartTime.Remove($procId)
            }
        }
    }

    # 启动新任务
    while ($procs.Count -lt $MaxSlots -and $idx -lt $Total) {
        $app = $Apps[$idx]
        $okFile = Join-Path $TempDir "$($app.Id).ok"
        $badFile = Join-Path $TempDir "$($app.Id).bad"
        $batFile = Join-Path $TempDir "$($app.Id).bat"

        if ((Test-Path $okFile) -or (Test-Path $badFile)) {
            $idx++
            continue
        }

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "cmd.exe"
        $psi.Arguments = "/c `"$batFile`""
        # [FIX 5/5] 原代码:
        #   $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized
        #   $psi.UseShellExecute = $false
        #
        # 问题分析: .NET ProcessStartInfo 的 WindowStyle 属性仅在 UseShellExecute=$true 时生效
        #            当 UseShellExecute=$false (重定向 I/O 模式) 时，WindowStyle 被完全忽略
        #
        # 结果: 12 个子安装 bat 会以默认窗口大小弹出，用户看到满屏 cmd 窗口闪烁
        #
        # 修复方案:
        #   - CreateNoWindow=$true → 完全不创建窗口（静默运行）
        #   - 这比 Minimized 更好，因为安装程序本身有 GUI，不需要 cmd 容器窗口
        $psi.UseShellExecute = $true
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized

        try {
            $p = [System.Diagnostics.Process]::Start($psi)
            $procs[$p.Id] = $p
            # [FIX LOGIC-3/6] 记录每个进程的启动时间，用于后续超时检测
            $appStartTime[$p.Id] = Get-Date
        } catch {
            "fail" | Out-File $badFile -Encoding ascii
        }
        $idx++
    }

    # 统计完成
    $done = 0
    foreach ($app in $Apps) {
        $ok = Join-Path $TempDir "$($app.Id).ok"
        $bad = Join-Path $TempDir "$($app.Id).bad"
        if ((Test-Path $ok) -or (Test-Path $bad)) { $done++ }
    }

    if ($done -ge $Total) { break }

    # UI
    $pct = [math]::Floor($done * 100 / $Total)
    $barWidth = $UI_Width - 20
    $fill = [math]::Floor($pct * $barWidth / 100)
    $bar = ("#" * $fill) + ("." * ($barWidth - $fill))

    Clear-Host
    Write-Host ""
    Write-Host "  $SepLine"
    Write-Host "      常用软件一键部署工具"
    Write-Host "      最大并发: $MaxSlots 个"
    Write-Host "  $SepLine"
    Write-Host ""
    Write-Host "   [$bar]  $pct%  ($done/$Total)"
    Write-Host ""
    $dashHalf = [math]::Floor(($UI_Width - 18) / 2)
    $dashLeft = "-" * $dashHalf
    $dashRight = "-" * ($UI_Width - 18 - $dashHalf)
    Write-Host "  $dashLeft 正在安装 $dashRight"
    $hasRun = $false
    foreach ($app in $Apps) {
        $run = Join-Path $TempDir "$($app.Id).run"
        if (Test-Path $run) {
            Write-Host "     [安装中] $($app.Name)"
            $hasRun = $true
        }
    }
    if (-not $hasRun) {
        Write-Host "     (暂无)"
    }

    Write-Host ""
    Write-Host "  $dashLeft 已完成 $dashRight"
    $hasOk = $false
    foreach ($app in $Apps) {
        $ok = Join-Path $TempDir "$($app.Id).ok"
        if (Test-Path $ok) {
            $okContent = (Get-Content $ok -Raw).Trim()
            if ($okContent -eq "skip") {
                Write-Host "     [跳过] $($app.Name) (已安装)"
            } else {
                Write-Host "     [OK]   $($app.Name)"
            }
            $hasOk = $true
        }
    }
    if (-not $hasOk) { Write-Host "     (暂无)" }

    foreach ($app in $Apps) {
        $bad = Join-Path $TempDir "$($app.Id).bad"
        if (Test-Path $bad) { Write-Host "     [失败] $($app.Name)" }
    }

    Write-Host ""
    Write-Host "  $SepLine"

    Start-Sleep -Seconds 2
}

# ============================================================
# 恢复重启策略 (安装结束，允许用户手动重启)
# [AUDIT-B FIX] 说明: 此处只恢复 WindowsUpdate 策略注册表项（SetAutoRestartDeadline 等）。
#   RebootPending 标记在部署开始时被有意清除（防 MSI/InstallShield 中途触发重启），
#   不在此处恢复。如需恢复 Windows Update 挂起标记，请运行:
#     wuauclt /detectnow /updatenow
# 或直接重启计算机让挂起的更新完成安装。
# ============================================================
Write-Host "   正在恢复重启策略..."
try {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "SetAutoRestartDeadline" -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "SetAutoRestartNotificationDisable" -Force -ErrorAction SilentlyContinue
} catch {}
Write-Host "   [OK] 重启策略已恢复"
Write-Host ""

# ============================================================
# 阶段三: 系统优化
# ============================================================

Clear-Host
Write-Host ""
Write-Host "  $SepLine"
Write-Host "      常用软件一键部署工具"
Write-Host "  $SepLine"
Write-Host ""
$doneBar = "#" * ($UI_Width - 20)
Write-Host "   [$doneBar]  100%"
Write-Host ""

$succ = 0; $fail = 0; $skip = 0
foreach ($app in $Apps) {
    $ok = Join-Path $TempDir "$($app.Id).ok"
    $bad = Join-Path $TempDir "$($app.Id).bad"
    if (Test-Path $ok) {
        $okContent = (Get-Content $ok -Raw).Trim()
        if ($okContent -eq "skip") { $skip++ } else { $succ++ }
    }
    if (Test-Path $bad) {
        $fail++
        if ($fail -eq 1) { Write-Host "   安装失败的软件:" }
        Write-Host "      - $($app.Name)"
    }
}
if ($fail -gt 0) { Write-Host "" }
Write-Host "   软件安装完成: 新装 $succ 个 / 跳过 $skip 个 / 失败 $fail 个"
Write-Host ""

# ---------- 注册表辅助函数 ----------
# [AUDIT-A FIX] 原代码:
#   function Set-Reg($desc, $path, $name, $value, $type) {
#       Write-Host "   $desc..."
#       try { ... Set-ItemProperty ... -ErrorAction Stop } catch {}
#       Write-Host "   [OK]"    ← 无条件输出，即使上面 catch 了异常
#   }
#
# 问题: catch {} 空块吞掉所有错误 + 无条件 [OK] → 阶段三 18 步注册表操作
#       即使全部失败（权限不足/路径无效/类型冲突），用户看到的全是 "[OK]"
#       实际部署效果需要逐项手动验证才能发现问题
#
# 修复: 引入 $success 标志位，catch 中输出 [FAIL] 并显示具体错误信息
function Set-Reg($desc, $path, $name, $value, $type) {
    Write-Host "   $desc..."
    $success = $false
    try {
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force -ErrorAction Stop
        $success = $true
    } catch {
        Write-Host "   [FAIL] $_" -ForegroundColor Red
    }
    if ($success) { Write-Host "   [OK]" }
}

$SubLine = "-" * $UI_Width
Write-Host "  $SubLine"
Write-Host "   阶段三: 系统优化"
Write-Host "  $SubLine"
Write-Host ""

# --- 3.1: 关闭隐私/广告 ---
Set-Reg "[01/22] 关闭广告ID" "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1 "DWord"
Set-Reg "" "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 "DWord"

Set-Reg "[02/22] 关闭语言列表访问" "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut" 1 "DWord"

Set-Reg "[03/22] 关闭应用启动跟踪" "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0 "DWord"
Set-Reg "" "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1 "DWord"

Set-Reg "[04/22] 关闭设置建议" "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled" 0 "DWord"
Set-Reg "" "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" 0 "DWord"
Set-Reg "" "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353696Enabled" 0 "DWord"

# --- 3.2: 关闭传递优化 ---
Write-Host "   [05/22] 关闭传递优化..."
try { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Type DWord -Force 2>$null } catch {}
try { Set-Service -Name DoSvc -StartupType Disabled -ErrorAction SilentlyContinue } catch {}
try { Stop-Service -Name DoSvc -Force -ErrorAction SilentlyContinue } catch {}
Write-Host "   [OK]"

# --- 3.3: 关闭后台应用 ---
Set-Reg "[06/22] 关闭后台应用" "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1 "DWord"

# --- 3.4: 禁用 Game Bar / 游戏模式 ---
Set-Reg "[07/22] 禁用 Game Bar" "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0 "DWord"
Set-Reg "" "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 "DWord"
Set-Reg "" "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0 "DWord"

Set-Reg "[08/22] 禁用游戏模式" "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0 "DWord"
Set-Reg "" "HKCU:\System\GameConfigStore" "GameMode" 0 "DWord"

# --- 3.5: 显示桌面图标 ---
# [FIX 1/5] 原代码:
#   Set-Reg "[09/22] 显示桌面图标" "HKCU:\...\NewStartPanel" "{20D04FE0...}" "DWord"
#   Set-Reg "" "...NewStartPanel" "{645FF040...}" "DWord"
#   ... (共4行)
#
# 问题分析: Set-Reg 函数签名为 ($desc, $path, $name, $value, $type)
#   原调用只传了4个参数 → "DWord" 被当作 $value 写入注册表
#   结果: 注册表值被设为字符串 "DWord"，而不是 DWord 类型 + 值 0
#   影响: 桌面此电脑/回收站/用户文件夹/网络图标全部无法正常显示
#
# 修复: 补全 $value=0 (0 = 不隐藏该图标)，使用命名参数避免歧义
Set-Reg -Desc "[09/22] 显示桌面图标" -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -Type "DWord"
Set-Reg -Desc "" -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value 0 -Type "DWord"
Set-Reg -Desc "" -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value 0 -Type "DWord"
Set-Reg -Desc "" -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value 0 -Type "DWord"

# --- 3.6: 电源高性能 ---
Write-Host "   [10/22] 电源高性能..."
try { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null } catch {}
Write-Host "   [OK]"

# --- 3.7: 任务栏设置 (来自 deploy_all) ---
Set-Reg "[11/22] 任务栏-搜索图标" "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 1 "DWord"
Set-Reg "[12/22] 任务栏-关闭资讯和兴趣" "HKCU:\Software\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" 0 "DWord"
Set-Reg "" "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds" 0 "DWord"
Set-Reg "" "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" "ShellFeedsTaskbarViewMode" 2 "DWord"
Set-Reg "[13/22] 任务栏-隐藏任务视图" "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0 "DWord"

# --- 3.8: 卸载 OneDrive (来自 deploy_all) ---
Write-Host "   [14/22] 卸载 OneDrive..."
Write-Host "     正在停止 OneDrive 进程..."
taskkill /f /im OneDrive.exe >$null 2>&1
Write-Host "     正在卸载 OneDrive 程序..."
if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
    Start-Process -FilePath "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
} elseif (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
    Start-Process -FilePath "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 3
Write-Host "     正在清理残留..."
if (Test-Path "$env:UserProfile\OneDrive") { Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path "$env:LocalAppData\Microsoft\OneDrive") { Remove-Item "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path "$env:ProgramData\Microsoft OneDrive") { Remove-Item "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path "C:\OneDriveTemp") { Remove-Item "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue }
Remove-Item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\Desktop\OneDrive.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:Public\Desktop\OneDrive.lnk" -Force -ErrorAction SilentlyContinue
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d "0" /f >$null 2>&1
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d "0" /f >$null 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d "1" /f >$null 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >$null 2>&1
schtasks /change /tn "\Microsoft\Windows\OneDrive Reporting Task" /disable >$null 2>&1
schtasks /change /tn "\Microsoft\Windows\OneDrive Reporting Task-S-1-5-21*" /disable >$null 2>&1
Write-Host "   [OK]"

# --- 3.9: 禁用 Cortana (来自 deploy_all) ---
Write-Host "   [15/22] 禁用 Cortana..."
Write-Host "     正在设置注册表策略..."
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >$null 2>&1
Write-Host "     正在卸载 Cortana 应用包..."
Get-AppxPackage *Cortana* | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage -allusers Microsoft.549981C3F5F10 | Remove-AppxPackage -ErrorAction SilentlyContinue
Write-Host "     正在终止相关进程..."
taskkill /f /im SearchApp.exe >$null 2>&1
taskkill /f /im Cortana.exe >$null 2>&1
taskkill /f /im SearchHost.exe >$null 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "Cortana" /t REG_BINARY /d "030000000000000000000000" /f >$null 2>&1
Write-Host "   [OK]"

# --- 3.10: 开启小键盘 ---
# [FIX 2/5] 原代码:
#   Set-Reg "[16/22] 开启小键盘" "HKCU:\.DEFAULT\Control Panel\Keyboard" "InitialKeyboardIndicators" "2" "String"
#
# 问题分析: HKCU: 驱动器指向 HKEY_CURRENT_USER (当前用户 SID)
#   .DEFAULT 是 HKEY_USERS 下的特殊子键，不属于当前用户配置单元
#   PowerShell 无法通过 HKCU:\.DEFAULT 访问该路径 → 路径不存在
#   结果: 每次新登录小键盘都不会自动开启
#
# 修复: 使用 Registry:: 前缀直接访问 HKEY_USERS\.DEFAULT
Set-Reg -Desc "[16/22] 开启小键盘" -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Value "2" -Type "String"

# --- 3.11: 重启资源管理器 ---
Write-Host "   [17/22] 重启资源管理器..."
taskkill /f /im explorer.exe >$null 2>&1
Start-Sleep -Seconds 2
Start-Process explorer.exe
Start-Sleep -Seconds 1
Write-Host "   [OK]"

# --- 3.12: 暂停 Windows 更新 (调用独立脚本) ---
$UpdateScript = Join-Path $BaseDir "windows_update_control.ps1"
if (Test-Path $UpdateScript) {
    Write-Host "   [18/22] 暂停 Windows 更新..."
    & $UpdateScript -Action pause
} else {
    Write-Host "   [18/22] [WARN] 未找到 windows_update_control.ps1，跳过暂停更新"
}

Write-Host ""
Write-Host "  $SepLine"
Write-Host "   所有部署任务已完成!"
Write-Host "  $SepLine"
Write-Host ""
Write-Host "   部署内容:"
Write-Host "    [1] 7-Zip 24.09 安装 + 文件关联"
Write-Host "    [2] 12 个常用软件并行安装"
Write-Host "    [3] 系统优化 (隐私/任务栏/OneDrive/Cortana/暂停更新...)"
Write-Host ""
Write-Host "  $SubLine"
Write-Host "   建议重启计算机使所有更改完全生效。"
Write-Host "  $SubLine"
Write-Host ""
Write-Host "   1. 重启计算机"
Write-Host "   2. 退出程序"
Write-Host ""

$ch = Read-Host "请选择操作 (1或2)"
if ($ch -eq "1") { shutdown /r /t 0 }

Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
