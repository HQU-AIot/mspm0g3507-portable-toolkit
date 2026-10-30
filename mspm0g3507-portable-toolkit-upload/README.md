# MSPM0G3507 Portable Toolkit

一个面向 Windows x64 的 MSPM0G3507 命令行开发环境封装层。它使用相对路径组织 TI Arm Clang、MSPM0 SDK、SysConfig、GNU Make、OpenOCD 和 GDB，使工具目录移动到其他磁盘或文件夹后仍可生成配置、编译和调试。

本仓库只包含脚本、配置和说明，不包含 TI 或 GPL 工具二进制。请从官方渠道取得工具，或在自己的电脑上从现有安装生成仅供本人/组织内部使用的离线便携目录。

## 已验证版本

| 组件 | 版本 |
| --- | --- |
| MSPM0 SDK | 2.10.00.04 |
| TI Arm Clang | 4.0.4.LTS |
| SysConfig | 1.27.0 |
| GNU Make | 4.4.1 |
| OpenOCD | 0.12.0 TI MSPM0 build（目录版本 1.3.1.50） |
| Arm GNU GDB | 15.2.90 / Arm GNU Toolchain 14.2.Rel1 |

工具的官方入口和许可注意事项见 [THIRD_PARTY.md](THIRD_PARTY.md)。原始目录审查结论见 [AUDIT.md](AUDIT.md)。

## 目录布局

```text
mspm0g3507-portable-toolkit/
├─ scripts/
├─ vendor/                         # 本地生成，不提交 Git
│  ├─ mspm0_sdk_2_10_00_04/
│  ├─ ti-cgt-armllvm_4.0.4.LTS/
│  ├─ sysconfig_1.27.0/
│  ├─ gmake/
│  ├─ openocd/1.3.1.50/
│  └─ arm-none-eabi-gdb/14.2.rel1.1/
└─ projects/                       # 用户工程，不提交 Git
```

所有脚本都从自身位置计算工具包根目录，不依赖 `D:\ti\TI_IDE` 或盘符。若实际路径包含空格，构建脚本会在 `%LOCALAPPDATA%\mspm0-portable-toolkit` 自动创建指向工具包的无空格 junction，以规避 TI SDK makefile 的路径拆分问题。

## 从现有目录生成本地便携包

在 PowerShell 7 或 Windows PowerShell 5.1 中运行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
./scripts/New-LocalBundle.ps1 -SourceRoot 'D:\ti\TI_IDE' -Profile Lean
./scripts/Test-Toolkit.ps1 -SmokeTest
```

`Lean` 只复制 MSPM0G3507 编译和 SysConfig CLI 所需的主要内容；若需要 SysConfig 图形界面，加上 `-IncludeSysConfigGui`。`Full` 会复制原目录中的完整工具组件，体积约 4.4 GiB，仅建议本地离线使用。

该脚本不会复制以下内容：

- `gpio_software_poll` 等用户工程；
- `tmp`、采集数据、日志、缓存、`__pycache__`；
- `.git`、个人 `.vscode` 和 `.claude` 配置；
- STM32 工程和与 MSPM0G3507 无关的资料。

## 使用

验证工具：

```powershell
./scripts/Test-Toolkit.ps1
```

验证会检查必需文件、关键文件 SHA-256 和工具版本；`components.lock.json` 中的哈希来自本次已验证的本地组件，只用于确认复制前后一致，不代替 TI/上游发布者的数字签名。

生成 SysConfig 文件：

```powershell
./scripts/Invoke-SysConfig.ps1 `
  -SysCfgFile 'D:\project\example.syscfg' `
  -OutputDirectory 'D:\project\generated'
```

编译包含 `ticlang/makefile` 的工程：

```powershell
./scripts/Build-Project.ps1 -ProjectPath 'D:\project\my-project' -Clean
```

打开 SysConfig GUI（本地包生成时必须使用 `-IncludeSysConfigGui`）：

```powershell
./scripts/Open-SysConfig.ps1 -SysCfgFile 'D:\project\example.syscfg'
```

VS Code 可直接打开仓库目录并使用 `MSPM0: Verify Toolkit`、`MSPM0: Build Project` 和 `MSPM0: Clean Project` 任务。调试需要 Cortex-Debug 扩展，并在启动时输入实际 ELF/OUT 文件路径。

## 发布原则

- GitHub 仓库只发布本仓库中的开源脚本、配置与文档。
- 不要把 `vendor/`、用户工程、实验数据或本地生成的压缩包提交到 Git。
- 不要把当前 MSPM0 SDK 整包上传百度网盘；其中部分内容受 TI 商业许可限制。
- 现有 OpenOCD、GDB 和 GNU Make 目录缺少对应源码/书面源码要约，不应直接作为公开二进制镜像重新分发。
- 如需离线共享，先由项目负责人逐组件完成许可审查，并随包保留原始许可证、清单、校验值和必要源码或源码要约。

## 限制

- 当前脚本面向 Windows x64。
- 烧录前必须确认实际调试器是 XDS110 还是 CMSIS-DAP/DAPLink；本仓库不会自动选择并烧录。
- 未连接开发板时，冒烟测试只验证 SysConfig 和编译链，不证明硬件运行正确。
