# CodexCount

macOS menu bar widget that tracks token consumption from the [Codex CLI](https://github.com/openai/codex) in real-time.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Daily view** — tokens consumed today
- **Weekly view** — tokens for the current week (Monday to Sunday)
- **Monthly view** — tokens for the current month
- **Period filter** — select start and end dates
- **Detailed sessions** — list of sessions of the day with time, project, and total tokens
- **Rate limits** — current usage of rate limits (input/output tokens per minute)
- **Auto-refresh** — automatic update every 15 minutes
- **Configurable** — customizable visible sections + logs path

## Requirements

- macOS 13 (Ventura) or higher
- Swift 5.9+ (Xcode Command Line Tools)
- [Codex CLI](https://github.com/openai/codex) installed (saves logs in `~/.codex/sessions/`)

## Installation

```bash
git clone https://github.com/Renzo-Tognella/CodexCount.git
cd CodexCount
./install.sh
```

The script compiles in release mode and installs the app at `~/Applications/CodexCount.app`.

To start manually:

```bash
open ~/Applications/CodexCount.app
```

### Start at login

Go to **System Settings → General → Login Items** and add `CodexCount.app`.

## Manual build

```bash
swift build -c release
```

The binary will be generated at `.build/release/CodexCount`.

## Configuration

On the first run, the app uses the default path `~/.codex/sessions/`. To change it:

1. Click the icon in the menu bar
2. Go to **Settings** (gear icon)
3. Select the Codex sessions folder
4. Enable/disable the sections you want to view

## How it works

The Codex CLI saves logs of each session in `.jsonl` files organized by date:

```
~/.codex/sessions/
  └── 2025/
      └── 06/
          └── 15/
              ├── rollout-2025-06-15T10-30-00-uuid.jsonl
              └── rollout-2025-06-15T14-45-00-uuid.jsonl
```

Each file contains `token_count` events with cumulative usage. CodexCount reads the last event of each session and aggregates the totals by period.

### Token details

| Field | Description |
|-------|-------------|
| Input | Total input tokens |
| Cached | Cached input tokens (subset of input) |
| Output | Total output tokens |
| Reasoning | Reasoning tokens (subset of output) |
| Total | Sum of input + output |

## Project structure

```
codex_count/
├── Package.swift
├── Info.plist
├── install.sh
└── Sources/CodexCount/
    ├── CodexCountApp.swift          # Entry point
    ├── Models/
    │   └── TokenUsage.swift         # Data models
    ├── Services/
    │   ├── LogParser.swift          # .jsonl files parser
    │   ├── SessionFinder.swift      # Search files by period
    │   └── SettingsManager.swift    # Settings persistence
    ├── ViewModels/
    │   └── TokenViewModel.swift     # Business logic
    ├── Views/
    │   ├── ContentView.swift        # Main interface
    │   └── SettingsView.swift       # Settings screen
    └── Helpers/
        └── TokenFormatter.swift     # Number formatting
```

## License

MIT
