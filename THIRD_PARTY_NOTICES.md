# 第三方组件

本项目源码以 MIT License 发布，但构建产物包含以下第三方组件。分发二进制时请保留本文件与相应许可证。

## AMSMB2

- 版本：4.0.3
- 用途：Swift 封装的 SMB2/3 客户端
- 仓库：https://github.com/amosavian/AMSMB2
- 许可证：AMSMB2 自身源码为 MIT；由于静态链接 libsmb2，其整体按 **LGPL-2.1** 分发
- 说明：本项目通过 SPM 以动态库形式链接 AMSMB2，便于替换/重新链接 LGPL 组件

## libsmb2

- 用途：SMB2/3 协议实现（由 AMSMB2 内置）
- 仓库：https://github.com/sahlberg/libsmb2
- 许可证：
  - `lib/` 与 `include/`：**LGPL-2.1**（或更高版本）
  - `examples/`：2-Clause BSD
- 说明：本项目不修改 libsmb2；如需替换，请使用兼容的 LGPL-2.1 构建

## Swift Atomics

- 用途：AMSMB2 的原子操作依赖
- 仓库：https://github.com/apple/swift-atomics
- 许可证：Apache-2.0（含 Runtime Library Exception）

## 合规提示

若你分发编译好的 `.app`，请同时提供：

1. 本文件与上述组件的许可证文本；
2. libsmb2 与 AMSMB2 的对应源码获取方式（仓库链接即可）；
3. 允许用户替换动态库 `libAMSMB2.dylib` 的方式（本项目未启用 Hardened Runtime 的库验证限制）。
