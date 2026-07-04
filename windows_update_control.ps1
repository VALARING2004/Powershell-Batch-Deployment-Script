# windows_update_control.ps1 - Windows 更新管理工具
# 功能:
#   - stop       强制中断挂起的 Windows 更新（杀进程+停服务+清缓存）
#   - pause      暂停 Windows 更新至 2030 年（仅 Win10，Win11 跳过）
#   - resume     恢复 Windows 更新服务
#   - full       完整执行: 先中断挂起更新，再暂停（部署脚本使用）
# 用法: 以管理员身份运行
#   .\windows_update_control.ps1 stop
#   .\windows_update_control.ps1 pause
#   .\windows_update_control.ps1 resume
#   .\windows_update_control.ps1 full

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("stop", "pause", "resume", "full")]
    [string]$Action = "full"
)

# 管理员检测
$wid = [Security.Principal.WindowsIdentity]::GetCurrent()
$princ = New-Object Security.Principal.WindowsPrincipal($wid)
if (-not $princ.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: 请以管理员身份运行此脚本" -ForegroundColor Red
    Read-Host "按 Enter 退出"
    exit 1
}

function Stop-PendingUpdate {
    Write-Host ""
    Write-Host "   正在检查并中断挂起的 Windows 更新..."
    Write-Host ""

    $updateProcesses = @("wuauclt.exe","usoclient.exe","UpdateOrchestrator.exe","MusNotification.exe","MusNotificationUx.exe","SetupHost.exe","TiWorker.exe")
    foreach ($proc in $updateProcesses) { taskkill /f /im $proc >$null 2>&1 }

    Start-Sleep -Seconds 2

    foreach ($svc in @("wuauserv","UsoSvc","bits")) {
        $running = Get-Service -Name $svc -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
        if ($running) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            $waited = 0
            while ($waited -lt 10) {
                $st = (Get-Service -Name $svc -ErrorAction SilentlyContinue).Status
                if ($st -ne "Running") { break }
                Start-Sleep -Seconds 1
                $waited++
            }
            if ($waited -ge 10) {
                Write-Host "   [WARN] Service $svc timeout, forcibly terminated" -ForegroundColor Yellow
            }
        }
    }

    $sdDownload = "$env:SystemRoot\SoftwareDistribution\Download"
    if (Test-Path $sdDownload) { Remove-Item "$sdDownload\*" -Recurse -Force -ErrorAction SilentlyContinue }

    Write-Host "   [OK] 挂起的更新操作已清理" -ForegroundColor Green
}

function Pause-WindowsUpdate {
    $build = [Environment]::OSVersion.Version.Build
    if ([Environment]::OSVersion.Version.Major -eq 10 -and $build -lt 22000) {
        Write-Host ""
        Write-Host "   检测到 Win10，暂停 Windows 更新至 2030 年..."
        Write-Host ""

        $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
        Set-ItemProperty -Path $auPath -Name "NoAutoUpdate" -Value 1 -Type DWord -Force 2>$null

        taskkill /f /im wuauclt.exe >$null 2>&1
        taskkill /f /im usoclient.exe >$null 2>&1
        taskkill /f /im UpdateOrchestrator.exe >$null 2>&1

        Start-Sleep -Seconds 2

        foreach ($svc in @("wuauserv","UsoSvc")) {
            $running = Get-Service -Name $svc -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Running" }
            if ($running) {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                $waited = 0
                while ($waited -lt 10) {
                    $st = (Get-Service -Name $svc -ErrorAction SilentlyContinue).Status
                    if ($st -ne "Running") { break }
                    Start-Sleep -Seconds 1
                    $waited++
                }
            }
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        }

        Write-Host "   [OK] Windows 更新已暂停至 2030 年" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "   检测到 Win11，跳过暂停更新 (Win11 有内置暂停功能)" -ForegroundColor Yellow
        Write-Host ""
    }
}

function Resume-WindowsUpdate {
    Write-Host ""
    Write-Host "   正在恢复 Windows 更新服务..."
    Write-Host ""

    $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (Test-Path $auPath) { Remove-ItemProperty -Path $auPath -Name "NoAutoUpdate" -Force -ErrorAction SilentlyContinue }

    try { Set-Service -Name wuauserv -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name wuauserv -ErrorAction SilentlyContinue } catch {}
    try { Set-Service -Name UsoSvc -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name UsoSvc -ErrorAction SilentlyContinue } catch {}
    try { Set-Service -Name bits -StartupType Manual -ErrorAction SilentlyContinue; Start-Service -Name bits -ErrorAction SilentlyContinue } catch {}

    Write-Host "   [OK] Windows 更新服务已恢复" -ForegroundColor Green
}

Write-Host ""
$sep = "=" * 50
Write-Host "  $sep"
Write-Host "      Windows 更新管理工具"
Write-Host "  $sep"

switch ($Action) {
    "stop"   { Stop-PendingUpdate }
    "pause"  { Pause-WindowsUpdate }
    "resume" { Resume-WindowsUpdate }
    "full"   { Stop-PendingUpdate; Pause-WindowsUpdate }
}

Write-Host ""
Write-Host "  $sep"
Write-Host "   操作完成"
Write-Host "  $sep"
Write-Host ""
