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

- [ ] Side-by-side split panels for simultaneous browsing
- [ ] Address bar with direct path input
- [ ] File table with sortable columns (name, size, date)
- [ ] Context menu (copy, cut, paste, rename, delete, new folder)
- [ ] Keyboard shortcuts (Cmd+C, Cmd+V, Cmd+Delete, etc.)

### 2. Supported Cloud Services

- [ ] Supports all 70+ cloud storage services that rclone supports

> Google Drive, OneDrive, Dropbox, Box, Mega, pCloud, Amazon S3, Azure Blob, Backblaze B2, Wasabi, DigitalOcean Spaces, Nextcloud, Owncloud, FTP, SFTP, WebDAV, and more

### 3. File Management

- [ ] Copy / Move / Delete / Rename
- [ ] Create folder
- [ ] Right-click context menu

### 4. Transfer

- [ ] Transfer queue with progress tracking
- [ ] Transfer history (completed / failed tabs)
- [ ] Cancel active transfers

### 5. Account Management

- [ ] Add / Delete cloud accounts
- [ ] Multiple accounts per service
- [ ] Provider type selection

### 6. Localization

- [ ] Korean / English

## Tech Stack

- **Language**: Swift
- **UI**: SwiftUI + AppKit
- **State Management**: @Observable (macOS 14+)
- **rclone Integration**: librclone (C shared library via FFI)
- **Project Structure**: Swift Package Manager
- **Minimum OS**: macOS 14 (Sonoma)

## Getting Started

```bash
# Build librclone
./scripts/build-librclone.sh

# Open in Xcode
open RcloneGUI/RcloneGUI.xcodeproj

# Build and run
# Cmd+R in Xcode

# Run package tests
cd Packages/RcloneKit && swift test
cd Packages/FileBrowser && swift test
cd Packages/TransferEngine && swift test
```

## License

MIT License
