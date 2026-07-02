# 更新日志 / Changelog

本文件记录 cc-times 每个版本的变更。发布产物(DMG)见 GitHub Releases。

All notable changes to cc-times are documented here. Release artifacts (DMG)
are attached to GitHub Releases.

格式遵循 [Keep a Changelog](https://keepachangelog.com/),版本号遵循
[语义化版本](https://semver.org/lang/zh-CN/)。

---

## [1.0.0] - 2026-07-02

首个公开发布版本。/ First public release.

### 新增 / Added
- 多时区桌面时钟:每个时钟 = 模拟表盘 + 城市名 + 数字时间
- 24 个精选城市,覆盖每个整点 UTC 偏移(UTC-11 ~ UTC+12),菜单带实时偏移标注
- 两种显示模式:完整(表盘+数字)/ 简版(仅数字+城市)
- 6 套配色主题:Midnight / Slate / Sand(实色)+ Neon Black / Aurora / Sunset(霓虹渐变)
- 每个时区可单独设主题(或跟随全局)
- 中英双语 UI,运行时即时切换
- 透明悬浮窗,可拖动,支持主屏/副屏
- 窗口透明度调节(100% / 80% / 60% / 45% / 30%)+ 常驻置顶开关
- 配置持久化(时区/语言/主题/设置)
- 自动夏令时(系统时区库内置)
- 应用图标(三轨多时区概念,CoreGraphics 生成)
- Universal DMG(Apple Silicon + Intel 通用,未签名)
- 命令行构建(Makefile:build/start/stop/restart/icon/shots/bundle/dmg),无需 Xcode

### 已知限制 / Known Limitations
- 壁纸层(.desktop)无法交互(macOS 限制),故默认用悬浮层(.floating)
- DMG 未签名(个人开源项目),首次打开需右键确认或执行 `xattr -d com.apple.quarantine`

---

## 版本号规则 / Versioning

- `主版本.次版本.修订号`(如 1.0.0)
  - 主版本:不兼容的改动
  - 次版本:向下兼容的新功能
  - 修订号:向下兼容的修复

## 链接 / Links

- [Keep a Changelog 规范](https://keepachangelog.com/zh-CN/1.1.0/)
- [语义化版本](https://semver.org/lang/zh-CN/)
