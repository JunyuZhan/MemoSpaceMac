# MemoSpaceMac

[![CI](https://github.com/JunyuZhan/MemoSpaceMac/actions/workflows/ci.yml/badge.svg)](https://github.com/JunyuZhan/MemoSpaceMac/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue.svg)](#系统要求)
[![Swift](https://img.shields.io/badge/swift-5.9%2B-orange.svg)](#开发)

华为家庭存储（MemoSpace）的**非官方** macOS 局域网客户端：通过设备自带的 SMB 共享，用 Finder 式界面浏览、上传、下载和预览文件。原生 SwiftUI，仅供自用。

> 本项目与华为无任何关联，也未获得华为官方支持。请自行评估使用风险。

## 功能

- Bonjour / NetBIOS / 手动 IP 发现设备
- 浏览「家庭共享」「个人共享」等 SMB 共享
- 网格 / 列表视图、排序、当前目录搜索
- 上传文件与文件夹（含空目录）、下载、重命名、删除、新建文件夹
- 图片 / PDF / 文本 / 音视频预览（先下载到缓存）
- 传输队列（并发 2、取消、重试、同名冲突策略）
- 密码存 Keychain，配置存 UserDefaults

## 不做

- 外网 / P2P 远程访问
- 相册时间线、AI 分类
- 双向同步、离线缓存
- 拖出到 Finder、多窗口

## 系统要求

- macOS 14 或更高版本
- 设备与 Mac 在同一局域网，并已在华为家庭存储 App 中开启「网络邻居」

## 构建

需要 Xcode（Swift 6 工具链）与 [XcodeGen](https://github.com/yonaskolb/XcodeGen)：

```bash
brew install xcodegen
xcodegen generate
open MemoSpaceMac.xcodeproj
```

在 Xcode 中选择本地开发签名（ad-hoc 或 Apple Development）后运行。App 非沙盒。

只编译和测试核心库：

```bash
swift test
swift build -c release
```

## 使用

1. 在华为家庭存储 App 中开启「网络邻居」共享。
2. 启动 MemoSpaceMac，等待自动发现，或手动填写设备 IP。
3. 共享名默认 `家庭共享`，按需切换到 `个人共享`。
4. 游客登录无需密码；需要权限时填写设备上配置的账号。

## 排障

```bash
ping -c 3 <设备IP>
nc -vz <设备IP> 445
smbutil view -N //<设备IP>          # 游客模式列共享
smbutil view -U <用户名> //<设备IP>  # 会交互式提示密码
```

若 `smbutil` 无法列出共享，检查设备是否只允许 SMB1；本项目依赖 libsmb2（SMB2/3）。SMB1-only 时请改用系统 `mount_smbfs` 方案。

## 真机联调清单

先执行：

```bash
ping -c 3 <IP>
nc -vz <IP> 445
smbutil view -N //<IP>
smbutil statshares -a
```

再在 App 内逐项验证：

- [ ] 游客登录成功；密码登录成功
- [ ] 自动发现出现设备；手动 IP 可连接
- [ ] 两个共享可切换，多级目录前进/后退正确
- [ ] 中文、emoji、超长文件名显示正常
- [ ] 上传单文件、整个文件夹（含空目录）
- [ ] 下载 1 GB 文件，进度平滑，内存稳定
- [ ] 图片、PDF 预览；视频播放；音频播放
- [ ] 重命名、删除、新建文件夹
- [ ] 同名冲突：覆盖 / 跳过 / 保留两者 / 取消本批
- [ ] 断网 30 秒再恢复：提示断开，队列可重试
- [ ] 重启 App 后记住密码可自动填充

## 开发

```bash
swift test          # 运行 MemoSpaceKit 单元测试
swift build         # 编译 Kit
swift build -c release
```

项目结构：

- `Sources/MemoSpaceKit/`：模型、SMB 传输、设备发现、缓存、传输队列（无 UI，可单测）
- `Tests/MemoSpaceKitTests/`：Swift Testing 单元测试
- `App/`：SwiftUI 界面与 `AppModel`
- `project.yml`：XcodeGen 工程定义

提交前请确保 `swift test` 全绿。详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 安全

- 密码只写入 Keychain（service `com.local.memospacemac`）与进程内存。
- 不使用 `smbutil //user:pass@host`，避免密码出现在命令行参数。
- 日志不得输出密码；错误信息只保留可读描述。
- 发现安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。

## 已知限制

- 搜索仅当前已加载目录（SMB 无服务端搜索）。
- 缩略图需要先下载源文件；超过 50 MB 的图片/PDF 不生成缩略图。
- 大文件预览需完整下载；超过 2 GB 会二次确认。
- 退出 App 不续传。
- 设备若只支持 SMB1，本项目无法连接。

## 许可证

本项目源码以 [MIT License](LICENSE) 发布。第三方组件许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 免责声明

本项目为个人自用的非官方客户端，与华为技术有限公司无关。使用本项目产生的任何数据丢失、设备故障或账号风险，由使用者自行承担。
