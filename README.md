

# USB OpenClaw (便携openclaw工具)

## 项目简介

USB OpenClaw 是一款轻量级的便携式 Git 工具，专为 Windows 环境设计。该工具可以直接从 USB 闪存驱动器运行，无需在系统上进行任何安装，真正实现即插即用的便携开发体验。

## 主要特性

- **便携运行**：无需安装，解压即可使用，可在 USB 驱动器上直接运行
- **完整 Git 环境**：内置完整的 Git for Windows 核心组件
- **图形控制面板**：提供 clawpanel.exe 图形化控制面板
- **多种 Shell 支持**：内置 bash、sh 等常用 Unix Shell
- **Git GUI 工具**：集成 git-gui、gitk 等可视化工具
- **凭证管理**：内含 Git Credential Manager 安全存储凭证
- **SSH 支持**：集成完整的 SSH 客户端和配置

## 系统要求

- 操作系统：Windows 10 或更高版本
- 架构：64位 (x64)
- 存储空间：约 500MB 可用空间

## 快速开始

### 基础操作

```bash
# 初始化新的 Git 仓库
git init

# 克隆现有仓库
git clone

## install.bat 使用注意事项

### 重要提示

1. **必须使用管理员权限运行**
   - install.bat 脚本需要修改系统环境变量，因此必须以管理员身份运行
   - 否则会出现 "错误: 需要管理员权限来修改系统环境变量" 的提示

2. **如何使用管理员权限执行**
   - 方法一：右键点击 install.bat 文件，选择 "以管理员身份运行"
   - 方法二：在文件资源管理器中按住 Shift 键，右键点击 install.bat 文件，选择 "以管理员身份运行"

3. **建议操作步骤**
   - **强烈建议**：先将整个 USB OpenClaw 文件夹复制到电脑硬盘中非C盘的其他盘符下
   - 例如：复制到 D:\tools\USB_OpenClaw 或 E:\portable\USB_OpenClaw
   - 然后在复制后的文件夹中运行 install.bat
   - 这样可以避免 USB 驱动器拔出时的路径问题

4. **执行过程**
   - 脚本会自动设置系统环境变量（Node.js 和 Git）
   - 测试环境变量设置是否成功
   - 安装指定版本的 openclaw-zh
   - 启动 clawpanel.exe 图形化控制面板

5. **执行后验证**
   - 安装完成后，建议打开新的命令提示符窗口
   - 运行以下命令验证环境变量设置是否成功：
     ```bash
     node -v
     npm -v
     git --version
     openclaw --version
     ```

6. **故障排除**
   - 如果出现 "找不到命令" 的错误，请关闭当前命令窗口并重新打开
   - 如果安装失败，请检查网络连接和管理员权限
   - 如果面板程序未启动，请检查是否有错误提示信息
