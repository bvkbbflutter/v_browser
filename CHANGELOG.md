# Changelog

All notable changes to the **Vortex Browser** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-11-11

### Added
- **Dedicated Public Download Storage (`Downloads/Vortex/`)**:
  - Automatically saves all downloaded files (audio, video, documents, archives, images) into a dedicated folder inside the device's default Downloads directory (`Downloads/Vortex/`).
  - Automatically creates the directory structure recursively if it does not exist.
  - Added native Android `MediaScannerConnection` platform integration to index files immediately for the device's native Files app, Gallery, and Music players.
  - Implemented safe duplicate filename resolution (`name (1).ext`, `name (2).ext`) preserving original names and extensions.
- **Advanced Download Manager**:
  - Real-time download progress tracking with live transfer speed (`KB/s`, `MB/s`) and byte counters.
  - HTTP Range request support for pausing and resuming downloads from existing bytes.
  - Interactive download notifications with action buttons (**Pause**, **Resume**, **Cancel**, **Open**, **Share**, **Retry**).
  - Forwarding of WebView session cookies and `Referer` headers to support authentication and anti-hotlink protected downloads.
  - User-friendly error diagnostics for dead host lookups, broken links (HTTP 404), forbidden access (HTTP 403), and timeouts.
- **Intelligent Media Detection & Modal Flow**:
  - Sniffs direct audio, video, and downloadable resources from URLs and MIME types.
  - Decoupled media downloading from playback: Tapping media links prompts a modal sheet with clear **Download** vs **Play** actions.
- **Android MediaSession & Background Audio Player**:
  - Integrated `audio_service` with Android `MediaSessionCompat` and foreground playback service (`FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK`).
  - Persistent lock screen and notification panel media card displaying track info and playback controls (Seek -10s, Play/Pause, Seek +10s, Stop).
  - Accidental swipe dismissal prevention while audio is actively playing.
  - Clean resource release and notification dismissal when playback is stopped.
- **Collapsible Floating Audio Player**:
  - Draggable overlay persistent across tabs and browser screens.
  - Added minimize/collapse arrow button that contracts the player into a compact 54×54 neon disc.
  - Automatic screen edge snapping (left or right) upon collapse or drag release.
- **In-Browser Video Player**:
  - Fullscreen video playback with gesture overlays, seek controls, speed selectors (0.5x – 2.0x), and landscape orientation lock.
- **Branding & Visuals**:
  - Renamed and branded as **Vortex Browser** (*Fast · Private · Secure*).
  - Added 3D neon launcher icons across Android mipmap resolutions (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
  - Implemented branded launch background and animated dark splash screen.
- **Unit Testing**:
  - Added 18 unit tests covering URL normalization, intelligent media classification, model serialization, byte formatting, and duplicate filename resolution.

### Changed
- Refactored `main_browser_screen.dart` to prevent WebView download requests from accidentally launching the audio player.
- Replaced manual local notifications with `audio_service` foreground service for all media playback.
- Updated `MainActivity.kt` to inherit from `AudioServiceActivity` and expose `scanFile` platform method.
- Updated `AndroidManifest.xml` with modern foreground service permissions (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `FOREGROUND_SERVICE_DATA_SYNC`, `WAKE_LOCK`) and media button receivers.
