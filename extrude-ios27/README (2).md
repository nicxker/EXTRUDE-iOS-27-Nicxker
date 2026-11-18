# Extrude — Process Manager for iOS 27.2

A powerful process manager for jailbroken iOS devices. View, search, pause, resume, and kill running processes and daemons.

> Inspired by [Extrude](https://havoc.app/package/extrude) by hans32.

## Features

- 📋 **Full process list** with PID, name, path, and memory usage
- 🔍 **Search** by name, PID, or executable path
- 🏷️ **Filters**: All · User · System · Apps · Daemons
- 📊 **Sort** by name, PID, memory, or CPU
- ⏸️ **Pause/Resume** processes (SIGSTOP/SIGCONT)
- ❌ **Kill** with confirmation (SIGKILL or SIGTERM)
- 📋 **Copy** name, PID, or path to clipboard
- 📂 **Open in Filza** directly
- 🔄 **Auto-refresh** every 3 seconds
- 📱 **Detailed view** with memory, threads, Mach IPC, timing info
- 🌙 **Dark theme** native UI

## Requirements

- iOS/iPadOS 15.0+ (tested on iOS 27.2)
- Rootless jailbreak (Dopamine, palera1n, etc.)
- Package manager (Sileo, Zebra)

## Installation

### From Releases
1. Download the latest `.deb` from [Releases](../../releases)
2. Install via your package manager or `dpkg -i`

### Build from source
```bash
# Requires Theos
make package THEOS_PACKAGE_SCHEME=rootless
make install THEOS_DEVICE_IP=<your-device-ip>
```

## ⚠️ Warning

Killing system processes (SpringBoard, backboardd, etc.) may cause device instability or reboot. Use with caution.

## License

MIT
