# `D:\ti\TI_IDE` 审查报告

审查日期：2026-10-30（Asia/Shanghai）

## 摘要

原目录共约 102,890 个文件、4.436 GiB。它能运行 TI Arm Clang、GNU Make、SysConfig CLI、OpenOCD 和 GDB，但不是纯净发布包：工具链、用户项目、固件构建产物、实验采集数据、个人配置和临时资料混在同一 Git 工作树中。

## 体积

| 目录 | 文件数 | 大小（MiB） | 结论 |
| --- | ---: | ---: | --- |
| `mspm0_sdk_2_10_00_04` | 88,152 | 2,029.56 | 工具依赖；完整包不宜公开镜像 |
| `ti-cgt-armllvm_4.0.4.LTS` | 2,196 | 1,235.42 | 工具依赖；可本地裁剪到 M0+ 目标 |
| `sysconfig_1.27.0` | 1,335 | 1,042.69 | CLI 与 GUI 可分离 |
| `gpio_software_poll` | 858 | 37.35 | 用户工程，应与工具包分离 |
| `tools` | 454 | 25.26 | 主要是采集数据，不属于工具链 |
| `openocd` | 986 | 19.68 | 调试工具；公开分发需满足 GPL |
| `ti-embedded-debug` | 9 | 17.93 | VS Code 扩展资源，可选 |
| `arm-none-eabi-gdb` | 3 | 15.18 | 调试工具；公开分发需满足 GPL |
| `tmp` | 64 | 3.74 | 临时资料，应排除 |
| `gmake` | 2 | 2.51 | 构建工具；公开分发需满足 GPL |
| `LCD_STM32F103C8T6_SPI` | 79 | 2.30 | 非 MSPM0 项目，应排除 |

## 主要问题

1. 根仓库存在未提交的用户代码修改和大量未跟踪采集文件，不能把当前目录直接重构、清理或重新打包。
2. `gpio_software_poll/build_and_flash.bat` 把根路径写死为 `D:\ti\TI_IDE`，移动目录后立即失效。
3. `gpio_software_poll/tools/*.cmd` 仍包含绝对路径和实验日志路径。
4. 根 `.vscode/launch.json` 的 `executable` 指向 `${workspaceFolder}/ticlang/build/...`，与实际工程目录和产物名不一致。
5. 根 Git 仓库曾跟踪 `__pycache__`、构建日志和大量采集数据，不适合作为工具链发布仓库。
6. MSPM0 SDK 内 `imports.mak` 已被改为与当前目录结构耦合的相对路径。它在现有布局可用，但不应修改供应商文件来实现可移植性；应由外部构建脚本传入路径变量。
7. OpenOCD 显示为 `0.12.0+dev-...-dirty`，现有目录没有明显的对应源码包或书面源码要约，不能直接公开镜像。
8. GDB 和 GNU Make 目录只有少量二进制文件，缺少完整 GPL 随附材料，不能直接公开镜像。

## 已验证能力

- `tiarmclang --version`：4.0.4.LTS。
- `gmake --version`：4.4.1。
- `arm-none-eabi-gdb --version`：15.2.90 / Arm GNU Toolchain 14.2.Rel1。
- `openocd --version`：0.12.0 TI MSPM0 build。
- `sysconfig_cli.bat --help`：可正常启动并识别 SDK product、device、package、script 和 output 参数。
- `Lean` 本地便携目录约 992.75 MiB；其中 SysConfig CLI 589.81 MiB、M0+ TI Arm Clang 287.72 MiB、裁剪 SDK 77.85 MiB，其余调试/构建工具约 37.37 MiB。
- 裁剪包在新的绝对路径完成 SysConfig 生成、编译和链接，产生 `gpio_toggle_output.out`。
- 工具包经带空格和中文的入口路径测试；构建脚本自动使用无空格 junction 别名后通过同一冒烟测试。

## 推荐边界

### GitHub 应包含

- 相对路径构建、SysConfig、验证和本地组包脚本；
- 工具版本清单、官方来源、SHA-256 和许可证说明；
- 不含 TI 代码的示例配置；
- 使用说明和故障排查。

### GitHub/网盘不应直接包含

- 整个 `mspm0_sdk_2_10_00_04`；
- 缺少 GPL 对应源码/源码要约的 OpenOCD、GDB、GNU Make 二进制；
- 用户固件、实验数据、临时 PDF/OCR、日志和缓存；
- `.git` 历史、个人 IDE/代理配置；
- 未逐项核验许可的 TI 工具二进制。

本报告是工程许可风险筛查，不是法律意见。公开发布前应由发布者依据随附许可证和组织政策做最终确认。
