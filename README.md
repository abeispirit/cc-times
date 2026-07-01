# macostimes · Multi-Timezone Desktop Clock for macOS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-12.0%2B-blue.svg)](https://www.apple.com/macos/)

A lightweight desktop clock that stays on your macOS desktop and shows the time
in multiple world cities at a glance. Transparent, borderless, draggable, and
quietly out of the way.

> 一个常驻 macOS 桌面的多时区时钟。透明无边框窗口悬浮在桌面顶部,一眼看清全球多个城市的时间。

---

## Features | 特性

- 🕐 **Multi-timezone at a glance** — each clock shows an analog face + city name + digital time
- 🌍 **Add / remove time zones** — curated list of 14 world cities via right-click
- 📏 **Two display modes** — full (analog + digits) or compact (digits + city only)
- 🌐 **Bilingual UI** — switch between **English** and **中文** at runtime
- 🪟 **Transparent floating window** — borderless, dark translucent, won't block your view
- ✋ **Draggable** — drag anywhere, across main and external displays
- 🎚️ **Adjustable opacity** — 100% / 80% / 60% / 45% / 30%
- 📌 **Always-on-top toggle** — float over windows or behave like a normal one
- 💾 **Settings persist** — your clocks, language, and preferences survive restarts
- ⏱️ **DST-aware** — daylight saving handled automatically by the system time zone database

## Screenshots | 截图

```
Full mode
┌──────────────────────────────────────────────┐
│   ╭────────╮   ╭────────╮   ╭────────╮        │
│   │   🕐   │   │   🕒   │   │   🕔   │        │
│   │Beijing │   │ Tokyo  │   │New York│        │
│   │ 14:30  │   │ 15:30  │   │ 02:30  │        │
│   ╰────────╯   ╰────────╯   ╰────────╯        │
└──────────────────────────────────────────────┘

Compact mode
┌─────────────────────────────────────┐
│  Beijing 22:30   New York 09:30     │
└─────────────────────────────────────┘
```

## Requirements | 环境要求

| Requirement | |
|-------------|-|
| macOS | 12.0 (Monterey) or later |
| Build  | Swift Command Line Tools — **no Xcode required** |

## Quick Start | 快速开始

```bash
make start    # build + launch (runs in the background)
```

The clock appears at the top-center of your main display.

## Commands | 命令

| Command | Action |
|---------|--------|
| `make start` | Build + launch |
| `make stop` | Stop the running clock |
| `make restart` | Rebuild + restart |
| `make build` | Build only |
| `make clean` | Remove build artifacts and logs |

## Right-Click Menu | 右键菜单

Right-click the clock window to:

```
Remove Time Zone   ▶  pick a city to remove
Add Time Zone      ▶  Beijing / Tokyo / London / ... (14 cities)
Window Opacity     ▶  100% / 80% / 60% / 45% / 30%
Language           ▶  中文 / English
✓ Always on Top       toggle floating / normal window level
✓ Compact (digits only)   toggle full / compact mode
─────────
Quit
```

## Configuration | 配置

Clocks and settings are persisted to:

```
~/.config/mtimes/clocks.json      # time zone list
~/.config/mtimes/settings.json    # display mode, opacity, always-on-top
```

The chosen language is stored in `~/Library/Preferences` via `UserDefaults`.

## Tech Stack | 技术栈

- **SwiftUI** + **AppKit** — pure native, **zero third-party dependencies**
- `TimelineView` + `Canvas` for the analog face (macOS 12+)
- `Foundation.TimeZone` for zone-accurate time and automatic DST
- A borderless `NSWindow` (`.floating` level, `isMovableByWindowBackground`) for the transparent, draggable overlay
- In-memory string tables for instant, bundle-free language switching

## Project Structure | 项目结构

```
Sources/
├── ClockApp.swift          # entry point + AppDelegate
├── WindowManager.swift     # window setup + context menu + window metrics
├── ClockStore.swift        # clock list + persisted settings
├── L10n.swift              # i18n: languages, string tables, runtime switch
├── CityRegistry.swift      # curated city list + localized city names
├── AnalogClockView.swift   # Canvas-drawn analog face
├── ClockCardView.swift     # single clock card (full / compact)
└── ClockRowView.swift      # horizontal row of clocks, per-second refresh
```

## Known Limitations | 已知限制

- **The desktop wallpaper level (`.desktop`) cannot be interacted with** — macOS does not deliver mouse events to windows at that level, so the clock uses the floating level instead. Use the opacity and always-on-top options to tune how intrusive it feels.

## License

This project is licensed under the [MIT License](LICENSE).

## Contributing

This project is open source under the MIT License — you are free to read, use,
fork, and modify the code for your own purposes.

However, this is a personal project and is **not accepting external
contributions at this time**. Pull requests, feature requests, and issues are
disabled and will not be reviewed. If you find the code useful, you're welcome
to fork it and build your own version. Thank you for understanding!

---

> **贡献说明**  
> 本项目以 MIT 协议开源,欢迎阅读、使用、复刻(Fork)并基于此修改自己的版本。  
> 但这是一个个人项目,**目前暂不接受外部贡献**。Pull Request、功能建议和 Issue 提交均已关闭,恕不一一回复。如果你觉得代码有用,欢迎自行 Fork 后做自己的版本,感谢理解!
