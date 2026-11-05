# TraceTask

> **Keyboard-driven task tracker for fast context switchers.**  
> Capture in one hotkey, organize effortlessly into logical workdays, and let tasks surface when they need attention. Built natively for **Ubuntu Linux, macOS, and Windows** with a single unified Flutter codebase.

---

## ⚡ Global Hotkey

- **Linux & Windows**: `Alt + Space`
- **macOS**: `⌥ + Space` (Option + Space)

Press from anywhere to summon the floating quick-capture panel without switching away from your current work.

---

## ⌨️ Everyday Keyboard Shortcuts

| Shortcut (Linux / Windows) | Shortcut (macOS) | Action |
|---|---|---|
| `type + Enter` | `type + ↩` | Add task and close panel |
| `type + Shift + Enter` | `type + ⇧↩` | Add task and stay open |
| `↑` `↓` | `↑` `↓` | Select previous / next task |
| `Ctrl + Enter` | `⌘↩` | Mark selected task as Done |
| `Ctrl + 1` / `2` / `3` | `⌘1` / `⌘2` / `⌘3` | Move / filter to Today / Week / Month |
| `Ctrl + D` | `⌘D` | Open inline date and time picker |
| `Ctrl + E` | `⌘E` | Edit selected task |
| `Ctrl + P` | `⌘P` | Pin task to system tray / menu bar |
| `Ctrl + S` | `⌘S` | Snooze timed alert (+15 mins) |
| `Ctrl + Backspace` | `⌘⌫` | Delete selected task |
| `Ctrl + Z` | `⌘Z` | Undo last action (up to 50 steps) |
| `Ctrl + /` | `⌘/` | Toggle keyboard shortcuts cheat sheet |
| `Esc` | `Esc` | Clear draft, cancel editing, or close panel |

---

## 📅 Natural Language Date & Time Parsing

Type natural date words at the end of your task. A live preview appears beneath the input before you save:

```
call bank 3pm        send invoice fri     tax docs nov 12     pay rent tmr
ping sam in 2h       renew domain month   review roadmap week meet fri 3pm
call bank at 3pm     call on fri          tax docs 12th nov   pay rent 11/12
ping in 2 hours      send next fri        plan next week      party next month
```

- **Trailing dot (`.`)**: Turn off parsing and keep words literal: `call mon.`
- **Logical 03:00 AM Rollover**: A workday runs from 03:00 to 03:00. At 1:00 AM, "today" still refers to your active workday, and `tmr` is the day you wake up to.

---

## 🎨 Themes

TraceTask has two hand-crafted appearances:
- **Index Card (Light)**: Warm stationery paper with highlighter selection and ruled line dividers.
- **Native Glass (Dark)**: Sleek, translucent dark glass with glowing accents.

Switch anytime via the sun/moon icon, tray menu, or system preference matching.

---

## 📂 Data Storage & Safety

All task data is saved locally in standard cross-platform locations:
- **Linux**: `~/.local/share/tracetask/tasks.json`
- **macOS**: `~/Library/Application Support/tracetask/tasks.json`
- **Windows**: `%APPDATA%\tracetask\tasks.json`

Safety features:
- **Atomic Writes**: Writes via temporary files to eliminate corruption risks.
- **Automatic Backups**: Daily rolling backups kept for 14 days in `backups/`.
- **Auto-Recovery**: If a file is ever corrupted, the newest clean backup is automatically restored and the damaged file is preserved.
- **Pruning**: Completed tasks are retained for 90 days before pruning.

---

## 🚀 Running & Developing Locally

```bash
# Run on Linux desktop
flutter run -d linux

# Run tests
flutter test test/core_test.dart

# Build release bundle
flutter build linux --release
```

---

## 📦 Multi-Platform CI/CD

TraceTask includes a [GitHub Actions workflow](.github/workflows/build.yml) that automatically builds installers on every release:
- **Linux**: `tracetask-linux-x64.tar.gz`
- **macOS**: `tracetask-macos.zip` (`TraceTask.app`)
- **Windows**: `tracetask-windows-x64.zip` (`.exe`)

