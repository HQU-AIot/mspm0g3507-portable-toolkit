# 第三方组件与来源

本仓库不分发下列组件，只记录经过本地验证的版本和官方下载入口。

| 组件 | 本地版本 | 许可证/风险摘要 | 官方来源 |
| --- | --- | --- | --- |
| MSPM0 SDK | 2.10.00.04 | 混合许可；顶层协议包含 TI Commercial 内容和 Software Tools 内部使用限制。不可假定整包可公开再分发。 | [TI MSPM0 SDK](https://www.ti.com/tool/download/MSPM0-SDK) |
| TI Arm Clang | 4.0.4.LTS | 混合 Apache/LLVM/BSD/TI Text File；二进制再分发需保留许可且仅用于 TI Devices。 | [TI ARM-CGT-CLANG](https://www.ti.com/tool/ARM-CGT) |
| SysConfig | 1.27.0 | TI Text File；允许未修改二进制再分发，但必须保留许可且仅用于 TI Devices。 | [TI SysConfig](https://www.ti.com/tool/SYSCONFIG) |
| OpenOCD | 0.12.0 TI build | GPL-2.0；分发二进制时必须满足对应源码义务。现有目录标记为 `dirty`，需特别谨慎。 | [OpenOCD](https://openocd.org/) |
| Arm GNU GDB | 15.2.90 | GPL-3.0-or-later；分发二进制时必须满足对应源码义务。 | [Arm GNU Toolchain](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads) |
| GNU Make | 4.4.1 | GPL-3.0-or-later；分发二进制时必须满足对应源码义务。 | [GNU Make](https://www.gnu.org/software/make/) |

本地生成便携包时，应原样保留各工具自带的许可证、manifest/SPDX、版权声明和版本文件。不要使用本仓库的 MIT 许可证覆盖第三方组件。
