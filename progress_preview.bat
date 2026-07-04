@echo off
setlocal enabledelayedexpansion

title 进度条样式预览

mode con cols=65 lines=42

echo.
echo  ==========================================
echo     进度条样式预览 - 请选择喜欢的样式
echo  ==========================================
echo.

REM ========== 样式1：经典井号 ==========
echo  [样式1] 经典井号进度条
echo.
set "PCT=75"
set /a "F1=(PCT*40)/100"
set /a "E1=40-F1"
set "B1="
set "S1="
for /L %%i in (1,1,!F1!) do set "B1=!B1!#"
for /L %%i in (1,1,!E1!) do set "S1=!S1! "
echo   [!B1!!S1!] !PCT!%%
echo.
echo.

REM ========== 样式2：方块填充 ==========
echo  [样式2] 方块填充进度条
echo.
set "PCT=60"
set /a "F2=(PCT*40)/100"
set /a "E2=40-F2"
set "B2="
set "S2="
for /L %%i in (1,1,!F2!) do set "B2=!B2!█"
for /L %%i in (1,1,!E2!) do set "S2=!S2!?"
echo   [!B2!!S2!] !PCT!%%
echo.
echo.

REM ========== 样式3：箭头进度 ==========
echo  [样式3] 箭头进度条
echo.
set "PCT=50"
set /a "F3=(PCT*40)/100"
set /a "E3=40-F3"
set "B3="
set "S3="
for /L %%i in (1,1,!F3!) do set "B3=!B3!="
set "B3=!B3!>"
for /L %%i in (1,1,!E3!) do set "S3=!S3! "
echo   [!B3!!S3!] !PCT!%%
echo.
echo.

REM ========== 样式4：双线边框 ==========
echo  [样式4] 双线边框进度条
echo.
set "PCT=85"
set /a "F4=(PCT*40)/100"
set /a "E4=40-F4"
set "B4="
set "S4="
for /L %%i in (1,1,!F4!) do set "B4=!B4!■"
for /L %%i in (1,1,!E4!) do set "S4=!S4!□"
echo   ╔════════════════════════════════════════════╗
echo   ║  [!B4!!S4!]  !PCT!%%  ║
echo   ╚════════════════════════════════════════════╝
echo.
echo.

REM ========== 样式5：百分比居中 ==========
echo  [样式5] 百分比居中进度条
echo.
set "PCT=40"
set /a "F5=(PCT*30)/100"
set /a "E5=30-F5"
set "B5="
set "S5="
for /L %%i in (1,1,!F5!) do set "B5=!B5!#"
for /L %%i in (1,1,!E5!) do set "S5=!S5! "
echo     !B5!!S5!
echo      >>>  !PCT!%%  <<<
echo.
echo.

REM ========== 样式6：带步骤信息 ==========
echo  [样式6] 带步骤信息的进度条（当前方案）
echo.
set "PCT=75"
set "CUR=3"
set "TOT=4"
set /a "F6=(PCT*40)/100"
set /a "E6=40-F6"
set "B6="
set "S6="
for /L %%i in (1,1,!F6!) do set "B6=!B6!#"
for /L %%i in (1,1,!E6!) do set "S6=!S6! "
echo   ┌──────────────────────────────────────────┐
echo   │                                          │
echo   │  步骤 [!CUR!/!TOT!] 正在卸载 OneDrive...         │
echo   │    正在删除残留文件...                    │
echo   │                                          │
echo   │  [!B6!!S6!] !PCT!%%             │
echo   │                                          │
echo   │  ─────────────────────────────────────── │
echo   │    [1] 安装 7-Zip 24.09                  │
echo   │    [2] 任务栏设置                         │
echo   │    [3] 卸载 OneDrive                     │
echo   │    [4] 禁用 Cortana                      │
echo   └──────────────────────────────────────────┘
echo.
echo.

REM ========== 样式7：动态旋转（静态展示） ==========
echo  [样式7] 动态旋转指示器（静态展示各阶段）
echo.
set "PCT=30"
set /a "F7=(PCT*35)/100"
set /a "E7=35-F7"
set "B7="
set "S7="
for /L %%i in (1,1,!F7!) do set "B7=!B7!#"
for /L %%i in (1,1,!E7!) do set "S7=!S7! "
echo   [!B7!!S7!] !PCT!%%  [-]
echo   [!B7!!S7!] !PCT!%%  [\]
echo   [!B7!!S7!] !PCT!%%  [|]
echo   [!B7!!S7!] !PCT!%%  [/]
echo.
echo.

REM ========== 样式8：简洁箭头 ==========
echo  [样式8] 简洁箭头进度条
echo.
set "PCT=66"
set /a "F8=(PCT*40)/100"
set /a "E8=40-F8"
set "B8="
set "S8="
for /L %%i in (1,1,!F8!) do set "B8=!B8!>"
for /L %%i in (1,1,!E8!) do set "S8=!S8! "
echo   !B8!!S8! !PCT!%%
echo.

echo  ==========================================
echo  请回复样式编号，我将应用到 deploy_all.bat
echo  ==========================================
echo.
pause
