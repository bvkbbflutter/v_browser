# Vortex Browser

<p align="center">
  <img src="assets/icon/app_icon.png" width="128" height="128" alt="Vortex Browser Logo" />
</p>

<p align="center">
  <strong>Fast · Private · Secure</strong><br>
  A modern, feature-packed mobile web browser built with Flutter, Provider, Hive, Flutter InAppWebView, and native Android Kotlin integrations.
</p>

---

## 🌟 Key Features

### 🌐 High-Performance Web Browsing
- **Full InAppWebView Engine**: Fast web navigation, modern JavaScript execution, smooth pinch-to-zoom, and responsive page rendering.
- **Incognito & Private Browsing**: Isolated session with zero cache persistence and private history isolation.
- **Desktop / Mobile User-Agent Toggle**: Instantly switch between mobile and desktop site modes.
- **Find in Page**: In-page search with real-time ordinal match highlighting and active counter navigation.
- **Custom Search Engines**: Quick engine selection across Google, DuckDuckGo, Bing, Brave Search, and Yahoo.
- **Tab & Tab Group Management**: Grid overview of active tabs, incognito indicators, tab counters, and quick close/open actions.
- **Local Persistence via Hive**: Persistent offline storage for Bookmarks, Browsing History, Shortcuts, and Settings.

---

### 📥 Advanced Download Manager
- **Identifiable Public Storage Directory**:
  - Automatically saves all downloaded files (audio, video, documents, archives, images) into a dedicated folder inside the device's default Downloads directory: **`Downloads/Vortex/`** (`/storage/emulated/0/Download/Vortex`).
  - Automatically creates the directory recursively if it doesn't already exist.
  - Indexed via Android's native **`MediaScannerConnection`**, making files immediately visible in native Files/File Manager, Gallery, and Music apps.
- **Safe Duplicate Filename Handling**:
  - Preserves original filenames and extensions.
  - Safely appends incremental counters when duplicate names exist (e.g., `document.pdf` → `document (1).pdf` → `document (2).pdf`), preventing accidental file clobbering.
- **Real-Time Transfer Metrics**:
  - Live progress bar with percentage, downloaded vs total size, and real-time transfer speed (`KB/s` and `MB/s`).
- **HTTP Range Support (Pause & Resume)**:
  - Pause and resume downloads without restarting from scratch when the server supports HTTP Range headers.
  - Full retry support for network errors.
- **Session Cookie & Anti-Hotlink Forwarding**:
  - Forwards session cookies and `Referer` headers from the active web session to support protected downloads and bypass anti-hotlinking restrictions.
- **Action Notifications**:
  - Dedicated Android high-importance notification channel (`vortex_downloads_v3`).
  - **Downloading**: Live progress bar with **Pause** and **Cancel** action buttons.
  - **Paused**: Notification with **Resume** and **Cancel** actions.
  - **Completed**: Notification with direct **Open** and **Share** action buttons.
  - **Failed**: Clear, user-friendly error messages with **Retry** action button.

---

### 🎵 Intelligent Media Sniffing & Floating Audio Player
- **Intelligent URL & MIME Sniffing**:
  - Automatically detects media streams and direct files (`.mp3`, `.m4a`, `.aac`, `.wav`, `.ogg`, `.flac`, `.opus`, `.mp4`, `.webm`, `.mkv`, etc.).
  - Decoupled playback from download: Tapping media links presents a clean modal choice (**Play in Browser** vs **Download to Device**).
- **Draggable Floating Audio Player**:
  - Overlay remains accessible across browser tabs, downloads, and bookmarks without interrupting audio.
  - **Minimized Bubble Mode**: Collapses into a compact 54×54 neon disc that automatically snaps to the nearest left or right screen edge upon drag release.
  - **Expanded Mode**: Full controls including timeline scrubber, play/pause, seek ±10s, speed multiplier (0.5x – 2.0x), and loop modes.
- **Android MediaSession & Foreground Service**:
  - Powered by **`audio_service`** and native Android `MediaSessionCompat`.
  - Runs an official foreground service with `FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK`.
  - Persistent lock screen and notification shade media player widget.
  - Responds to hardware media buttons, Bluetooth headphones, and smartwatch controls.
  - Notification cannot be accidentally dismissed while audio is actively playing.
  - Automatically releases MediaSession and dismisses notification upon player closure.

---

### 🎬 Dedicated In-Browser Video Player
- Custom fullscreen video screen supporting portrait and landscape orientations.
- Gesture-friendly controls overlay with auto-hide timer.
- Timeline progress slider, remaining time indicators, and playback speed adjustments.

---

## 🏗️ Architecture & Technology Stack

| Component | Technology |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.5.3, Flutter 3.24.3+) |
| **State Management** | Provider |
| **Persistence / Database** | Hive & Hive Flutter (NoSQL Key-Value Storage) |
| **WebView Engine** | `flutter_inappwebview` |
| **Audio Playback** | `just_audio` |
| **Background Media & Notifications** | `audio_service` (Android MediaSession & Foreground Service) |
| **Download Notifications** | `flutter_local_notifications` |
| **Video Playback** | `video_player` |
| **Native Android Platform Layer** | Kotlin (`AudioServiceActivity`, `MediaScannerConnection`, `MediaButtonReceiver`) |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/           # URL normalization, default search engines, user agents
│   ├── database/            # Hive database initialization & boxes
│   ├── models/              # Tab, Bookmark, History, Download & Settings models
│   ├── services/            # MediaDetector (Intelligent URL/MIME sniffing)
│   └── theme/               # Dark & Light Material 3 theme configurations
├── features/
│   ├── audio/               # Audio models, Floating player, VAudioHandler, Provider
│   ├── bookmarks/           # Bookmark folders, search & management screens
│   ├── browser/             # MainBrowserScreen, URL bar, Find in Page, Bottom navigation
│   ├── dashboard/           # Start page with speed-dial shortcuts & search bar
│   ├── downloads/           # DownloadsScreen, DownloadService, DownloadStorageService
│   ├── history/             # History list grouped by date, clear & search
│   ├── settings/            # Search engine, JavaScript, Desktop mode preferences
│   ├── splash/              # Animated dark splash screen
│   ├── tabs/                # Tab grid overview & tab switcher
│   └── video/               # VideoPlayerScreen with fullscreen controls
├── services/
│   └── local_notification_service.dart   # Download channels & action button dispatcher
└── main.dart                # App entry point, MultiProvider & service initialization
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.24.0`)
- Android SDK (API Level 21+)
- Java 17 / Gradle 8+

### Setup & Run

1. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd v_browser
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code analysis**:
   ```bash
   flutter analyze
   ```

4. **Execute unit tests**:
   ```bash
   flutter test
   ```

5. **Run the application**:
   ```bash
   flutter run
   ```

6. **Build release/debug APK**:
   ```bash
   flutter build apk --debug
   # or for production release
   flutter build apk --release
   ```

---

## 📄 License
This project is open-source under the [MIT License](LICENSE).
