@echo off

REM 设置代码页为UTF-8
chcp 65001 > nul

REM 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 需要管理员权限来修改系统环境变量
    echo 请右键点击此文件，选择"以管理员身份运行"
    pause
    exit /b 1
)

REM 获取当前脚本所在目录
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo 当前脚本目录: %SCRIPT_DIR%
echo.

REM 检查必要目录是否存在
if not exist "%SCRIPT_DIR%\node" (
    echo 错误: node目录不存在，请确保node目录在当前目录下
    pause
    exit /b 1
)

if not exist "%SCRIPT_DIR%\git" (
    echo 错误: git目录不存在，请确保git目录在当前目录下
    pause
    exit /b 1
)

if not exist "%SCRIPT_DIR%\clawpanel.exe" (
    echo 错误: clawpanel.exe不存在，请确保clawpanel.exe在当前目录下
    pause
    exit /b 1
)

REM 设置路径变量
set "NODE_PATH=%SCRIPT_DIR%\node"
set "GIT_PATH=%SCRIPT_DIR%\git"
set "GIT_BIN=%GIT_PATH%\bin"
set "GIT_CMD=%GIT_PATH%\cmd"

REM 检查关键文件是否存在
if not exist "%NODE_PATH%\node.exe" (
    echo 错误: node.exe不存在，请确保node目录结构正确
    pause
    exit /b 1
)

if not exist "%NODE_PATH%\npm.cmd" (
    echo 错误: npm.cmd不存在，请确保node目录结构正确
    pause
    exit /b 1
)

if not exist "%GIT_BIN%\git.exe" (
    echo 错误: git.exe不存在，请确保git目录结构正确
    pause
    exit /b 1
)
echo [完成] 所有必要文件检查通过
echo.

REM ========================================
echo [1/6] 读取当前系统环境变量PATH...
REM ========================================
set "SYSTEM_PATH="
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do (
    if "%%a"=="PATH" set "SYSTEM_PATH=%%b"
)

if not defined SYSTEM_PATH (
    echo [警告] 无法读取系统PATH，尝试创建新的PATH
    set "SYSTEM_PATH="
) else (
    echo [信息] 当前系统PATH长度: %SYSTEM_PATH:~0,100%...
)
echo [完成] 当前系统PATH已读取
echo.

REM ========================================
echo [2/6] 清理PATH中的重复项和旧路径...
REM ========================================
echo [信息] 使用PowerShell清理PATH...

REM 使用PowerShell来清理PATH（更可靠）
powershell -Command "$originalPath = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine'); $paths = $originalPath -split ';'; $uniquePaths = @(); $seen = @{}; foreach ($p in $paths) { $p = $p.Trim(); if ($p -ne '' -and -not $seen.ContainsKey($p.ToLower())) { $nodePath = '%NODE_PATH%'.Replace('\', '\\'); $gitBin = '%GIT_BIN%'.Replace('\', '\\'); $gitCmd = '%GIT_CMD%'.Replace('\', '\\'); if ($p -ne $nodePath -and $p -ne $gitBin -and $p -ne $gitCmd) { $seen[$p.ToLower()] = $true; $uniquePaths += $p; } } }; $cleanedPath = $uniquePaths -join ';'; Set-Content -Path '%TEMP%\cleaned_path.txt' -Value $cleanedPath -NoNewline"

REM 读取清理后的PATH
set "CLEANED_PATH="
if exist "%TEMP%\cleaned_path.txt" (
    set /p CLEANED_PATH=<"%TEMP%\cleaned_path.txt"
    del "%TEMP%\cleaned_path.txt"
    echo [完成] PATH清理成功
) else (
    echo [警告] PowerShell清理失败，跳过清理步骤
)
echo.

REM ========================================
echo [3/6] 构建新的PATH...
REM ========================================
set "NEW_PATH=%NODE_PATH%;%GIT_BIN%;%GIT_CMD%"
if defined CLEANED_PATH (
    set "NEW_PATH=%NEW_PATH%;%CLEANED_PATH%"
)

echo [信息] 新PATH开头: %NEW_PATH:~0,150%...
echo [信息] 新PATH长度: %NEW_PATH:~0,100%...
echo.

REM ========================================
echo [4/6] 更新系统环境变量...
REM ========================================
REM 使用setx设置用户环境变量（更可靠）
echo [信息] 设置用户环境变量...
setx PATH "%NEW_PATH%"
echo [完成] 用户环境变量设置完成

REM 同时更新系统环境变量（注册表）
echo [信息] 更新系统环境变量注册表...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "%NEW_PATH%" /f
echo [完成] 系统环境变量更新完成
echo.

REM ========================================
echo [5/6] 测试环境变量（当前会话）...
REM ========================================
REM 将路径添加到当前会话的PATH中，以便立即生效进行测试
set "PATH=%NODE_PATH%;%GIT_BIN%;%GIT_CMD%;%PATH%"
echo [信息] 当前会话PATH已更新
echo [信息] 当前会话PATH开头: %PATH:~0,150%...
echo.

echo [测试] Node.js路径: %NODE_PATH%
echo [测试] 测试node...
try (
    node --version
) catch (
    echo [警告] node测试失败，但继续执行
    echo [信息] 尝试使用完整路径...
    "%NODE_PATH%\node.exe" --version
)
echo.

echo [测试] npm路径: %NODE_PATH%\npm.cmd
echo [测试] 测试npm...
echo [命令] npm --version
REM 使用call命令执行，避免闪退
call :test_npm
echo.

echo [测试] Git路径: %GIT_BIN%;%GIT_CMD%"
echo [测试] 测试git...
try (
    git --version
) catch (
    echo [警告] git测试失败，但继续执行
    echo [信息] 尝试使用完整路径...
    "%GIT_BIN%\git.exe" --version
)
echo.

REM ========================================
echo [6/6] 检测和安装openclaw...
REM ========================================
echo [信息] 检测openclaw是否已安装...

REM 检测openclaw是否安装（使用where命令更可靠）
echo [信息] 执行 where openclaw 命令...
try (
    where openclaw >nul 2>&1
    if %errorlevel% equ 0 (
        echo [成功] 检测到openclaw已安装
    ) else (
        echo [信息] 未检测到openclaw，开始安装...
        echo [信息] 清理npm缓存...
        "%NODE_PATH%\npm.cmd" cache clean --force
        echo [完成] npm缓存清理完成
        echo.
        echo [信息] 安装openclaw-zh...
        echo [命令] npm install -g @qingchencloud/openclaw-zh@2026.4.9-zh.2 --registry https://registry.npmmirror.com
        echo [信息] 正在安装，请耐心等待...
        echo [信息] 显示详细安装进度和下载信息...
        echo [信息] 您将看到：
        echo [信息] - 下载的包文件
        echo [信息] - 下载进度条
        echo [信息] - 依赖项解析过程
        echo [信息] - 安装状态
        echo [信息] 开始安装...
        "%NODE_PATH%\npm.cmd" config set loglevel verbose
        "%NODE_PATH%\npm.cmd" install -g @qingchencloud/openclaw-zh@2026.4.9-zh.2 --registry https://registry.npmmirror.com  -ddd
        if %errorlevel% equ 0 (
            echo [完成] openclaw-zh安装成功
        ) else (
            echo [警告] openclaw-zh安装失败，但继续执行
        )
        echo.
        echo [信息] 验证openclaw安装...
        where openclaw >nul 2>&1
        if %errorlevel% equ 0 (
            echo [成功] openclaw安装验证通过
        ) else (
            echo [警告] openclaw安装验证失败，但继续执行
        )
    )
) catch (
    echo [警告] openclaw检测失败，但继续执行
)
echo.

REM ========================================
echo [7/7] 启动clawpanel...
REM ========================================
echo [信息] 启动clawpanel...
echo [信息] clawpanel路径: %SCRIPT_DIR%\clawpanel.exe
echo [信息] 正在启动，请稍候...

REM 使用start命令启动
start "ClawPanel" "%SCRIPT_DIR%\clawpanel.exe"

REM 等待2秒让程序启动
echo [信息] 等待程序启动...
timeout /t 2 >nul

echo [完成] clawpanel已启动

echo [信息] 检查是否启动成功...

REM 检查clawpanel进程是否存在
try (
    powershell -Command "$process = Get-Process 'clawpanel' -ErrorAction SilentlyContinue; if ($process) { echo '[成功] clawpanel进程正在运行' } else { echo '[警告] 未检测到clawpanel进程' }"
) catch (
    echo [警告] 进程检查失败，但继续执行
)
echo.

REM ========================================
echo ========================================
echo 安装脚本执行完成！
echo ========================================
echo.
echo [重要提示]
echo 1. 环境变量已设置，但新打开的CMD窗口才能生效
echo 2. 请关闭当前窗口，重新打开一个新的CMD窗口测试
echo 3. 在新窗口中运行: node -v, npm -v, git -v 验证
echo 4. 面板程序应该已经启动
echo 5. 如果面板没有启动，请检查是否有错误提示
echo.
echo 按任意键退出...
pause
goto :eof

:test_npm
REM 测试npm的函数，使用更安全的方式
setlocal
set "npm_test=0"

echo 尝试执行: npm --version
timeout /t 1 >nul

REM 使用cmd /c来执行，避免直接执行导致的闪退
cmd /c "npm --version" >nul 2>&1
if %errorlevel% equ 0 (
    echo [成功] npm测试通过
    npm --version
    set "npm_test=1"
) else (
    echo [警告] npm测试失败，尝试使用完整路径...
    echo 尝试执行: "%NODE_PATH%\npm.cmd" --version
    timeout /t 1 >nul
    "%NODE_PATH%\npm.cmd" --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [成功] npm使用完整路径测试通过
        "%NODE_PATH%\npm.cmd" --version
        set "npm_test=1"
    ) else (
        echo [警告] npm完整路径测试也失败，但继续执行
    )
)
endlocal
goto :eof

:try
REM 简单的try-catch模拟
%*
goto :eof

:catch
REM 空的catch块，用于忽略错误
goto :eof
