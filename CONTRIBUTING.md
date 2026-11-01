# 贡献指南

感谢你愿意改进 MemoSpaceMac。提交前请先阅读以下约定。

## 开发环境

- macOS 14+
- Xcode 15+（含 Swift 6 工具链）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)：`brew install xcodegen`

```bash
xcodegen generate
swift test
```

App 目标在 `MemoSpaceMac.xcodeproj` 中构建；核心逻辑在 `Sources/MemoSpaceKit`，不依赖 UI，可直接用 `swift test` 验证。

## 提交前检查

```bash
swift test
swift build -c release
```

App 相关改动请在 Xcode 中实际运行，确认连接、浏览、上传、下载、预览至少各走通一次。

## 代码风格

- 遵循 [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)。
- 4 空格缩进；不提交格式化噪音。
- 核心逻辑优先写成可单测的纯函数或 actor。
- 新测试使用 Swift Testing（`import Testing`、`@Test`、`#expect`），不要引入 XCTest。
- UI 文案使用中文；代码标识符使用英文。
- 不新增第三方依赖，除非在 PR 中说明必要性与许可证。

## 安全红线

- 禁止把密码、令牌、设备序列号写入日志、UserDefaults、命令行参数或测试快照。
- 密码只能通过 Keychain 或进程内存传递。
- 不要提交 `.env`、证书、私钥或真实设备信息。
- 发现安全问题请按 [SECURITY.md](SECURITY.md) 私下报告，不要开公开 Issue。

## 提交与 PR

- 从 `main` 切出分支：`feat/xxx`、`fix/xxx`、`docs/xxx`。
- 提交信息使用 Conventional Commits：`feat: ...`、`fix: ...`、`docs: ...`、`test: ...`、`chore: ...`。
- 一个 PR 只做一件事；附带复现步骤或截图。
- 提交即表示你同意以 [MIT License](LICENSE) 授权你的贡献。

## 报告 Bug

请使用 [Bug 报告模板](.github/ISSUE_TEMPLATE/bug_report.yml)，并附上：

- macOS 版本、芯片类型
- 设备型号与固件版本（如已知）
- `smbutil statshares -a` 中与 SMB 版本相关的输出（隐去 IP 与账号）
- 复现步骤与预期结果

不要在 Issue 中粘贴密码或完整的内网地址。
