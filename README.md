# Rclone GUI — Cloud Explorer

**[한국어](README.ko.md)** | English

A multi-cloud file manager GUI application based on rclone.
An open-source alternative that provides all the features of Air Explorer for free.

## Overview

A native macOS desktop application that lets you manage multiple cloud storage services from a single interface, powered by [rclone](https://rclone.org/) via librclone. Built with Swift and SwiftUI for a true Mac-native experience.

## Installation

### Users

1. Download `RcloneGUI-x.x.x.dmg` from the Releases page
2. Open the `.dmg` and drag the app to your Applications folder
3. Launch — done!

> Requires macOS 14 (Sonoma) or later.

### Developers

- **macOS 14+** (Sonoma)
- **Xcode 15+**
- **Go 1.21+** (for building librclone)

## Architecture

```
┌──────────────────────────────────────────────────┐
│              RcloneGUI.app (.dmg)                 │
│  ┌────────────────────────────────────────────┐  │
│  │        SwiftUI + AppKit Frontend           │  │
│  │  ┌──────────┐      ┌──────────┐           │  │
│  │  │ Left     │      │ Right    │           │  │
│  │  │ Panel    │      │ Panel    │           │  │
│  │  └──────────┘      └──────────┘           │  │
│  │  ┌──────────────────────────────┐         │  │
│  │  │  Transfer Queue / Progress   │         │  │
│  │  └──────────────────────────────┘         │  │
│  └────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────┐  │
│  │         Swift Packages                     │  │
│  │  ┌─────────────┐  ┌───────────────┐       │  │
│  │  │ FileBrowser  │  │ TransferEngine│       │  │
│  │  └──────┬──────┘  └──────┬────────┘       │  │
│  │  ┌──────┴─────────────────┴────────┐       │  │
│  │  │         RcloneKit (FFI)         │       │  │
│  │  └──────────────┬──────────────────┘       │  │
│  └─────────────────┼──────────────────────────┘  │
│  ┌─────────────────┴──────────────────────────┐  │
│  │  Frameworks/librclone.dylib                │  │
│  │  (Go C shared library — direct FFI call)   │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

**Key difference from v0.x:** No more HTTP API server or separate rclone process. librclone is linked directly into the app, calling rclone functions via C FFI for lower latency and simpler deployment.

## Features

### 1. Dual-Panel File Browser

- [x] Side-by-side split panels for simultaneous browsing
- [x] Drag and drop file transfer between panels
- [x] Resizable panel divider
- [x] Address bar with breadcrumb navigation and direct path input
- [x] Multi-tab browsing — work with multiple locations simultaneously
- [x] File table with sortable columns (name, size, date)
- [x] Context menu (copy, cut, paste, rename, delete, new folder, properties, share link)
- [x] Keyboard shortcuts (Cmd+C, Cmd+V, Cmd+X, Cmd+Delete, Cmd+A, Cmd+Shift+N, etc.)
- [x] Drag and drop from Finder (file URL drop support)
- [x] Quick Look preview (spacebar)
- [x] Bookmarks — favorite frequently used paths (Cmd+D)
- [ ] File/folder thumbnail previews (inline)
- [ ] Linked Browsing — synchronized folder navigation across both panels

### 2. Supported Cloud Services

- [x] Supports all 70+ cloud storage services that rclone supports

> Google Drive, OneDrive, Dropbox, Box, Mega, pCloud, Amazon S3, Azure Blob, Backblaze B2, Wasabi, DigitalOcean Spaces, Nextcloud, Owncloud, FTP, SFTP, WebDAV, and more

### 3. File Management

- [x] Copy / Move / Delete / Rename
- [x] Create folder
- [x] Right-click context menu
- [x] Bulk Rename (prefix, suffix, numbering, find/replace with preview)
- [x] Share link generation (copy to clipboard)
- [x] File hash comparison (MD5, SHA1 — select 2 files)
- [ ] Compress and upload files
- [ ] Preserve original dates on transfer
- [ ] Trash management

### 4. Transfer

- [x] Transfer queue with real-time progress tracking (1-second polling)
- [x] Transfer history (Active / Completed / Errors tabs)
- [x] Pause / Resume all transfers (bandwidth throttle)
- [x] Stop / Restart individual and all transfers
- [x] Transfer restart from history (copyOrigins tracking)
- [x] Resizable transfer panel
- [ ] Multi-threaded transfer speed optimization
- [ ] Time-based bandwidth limit scheduling
- [ ] Detailed transfer reports

### 5. Sync & Backup

- [x] Mirror — full replication from source to target (sync/sync)
- [x] Mirror Updated — copy only changed files (sync/copy)
- [x] Bidirectional sync (Bisync)
- [x] Sync profile management (save/load/delete)
- [x] Sync execution logs
- [ ] Custom sync rules
- [ ] Filter rules (extension, file size, date, regex) — stored but not applied yet

### 6. Scheduling & Automation

- [x] Task scheduler (custom interval in minutes)
- [x] Enable/disable individual tasks
- [ ] Background execution (menu bar resident)
- [ ] CLI mode support
- [ ] Schedule logging

### 7. Encryption

- [x] rclone crypt remote setup (password, salt, filename encryption, directory name encryption)
- [x] Encrypted cloud-to-cloud transfer (via crypt remote)

### 8. Search

- [x] BFS streaming search across all connected clouds (concurrent, incremental results)
- [x] Multi-cloud simultaneous search
- [x] Cloud filter toggles (select which remotes to search)
- [x] Filtering: file type, file size range
- [ ] Filtering: date range, path

### 9. Account Management

- [x] Unlimited account connections per service
- [x] Multiple accounts for the same service
- [x] Add account — dynamic provider-specific config fields
- [x] Edit account — rename and edit config values
- [x] Delete account (with confirmation)
- [x] Provider search (filter by name/description)
- [x] Local credential storage (via rclone config)
- [x] Account import/export (JSON config dump)

### 10. Settings

- [x] rclone options GUI (transfers, checkers, multi-thread-streams, buffer-size, etc.)
- [x] Bandwidth limit (bwlimit)
- [x] Persistent settings with auto-save (debounced)
- [x] Restore defaults
- [x] Multi-language support (Korean / English)
- [x] App restart on language change

### 11. Security

- [x] App lock with password (Keychain storage)
- [x] Touch ID unlock
- [x] Lock screen with shake animation on wrong password

### 12. Cloud Mount

- [x] Mount cloud storage as local drive (rclone mount)
- [x] Unmount
- [x] Active mount list

### 13. Storage Pooling

- [x] Union remote creation (pool multiple remotes)
- [x] Storage quota display in status bar

### 14. Additional Features

- [ ] Online media playback (streaming)
- [ ] Cloud storage quota check (per-remote detailed view)

## Tech Stack

- **Language**: Swift
- **UI**: SwiftUI + AppKit
- **State Management**: @Observable (macOS 14+)
- **rclone Integration**: librclone (C shared library via FFI)
- **Project Structure**: Swift Package Manager (RcloneKit, FileBrowser, TransferEngine)
- **Minimum OS**: macOS 14 (Sonoma)
- **Version**: 1.0.0

## Getting Started

```bash
# Build librclone
./scripts/build-librclone.sh

# Open in Xcode
open RcloneGUI.xcodeproj

# Build and run
# Cmd+R in Xcode

# Run automated tests (54 tests)
./scripts/run-tests.sh
```

## License

MIT License
