---
name: flutter-app-size
description: Measure, analyze, and optimize Flutter app binary size (APK, App Bundle, IPA) using `--analyze-size`, tree shaking, ProGuard/R8, asset compression, ABI splitting, and font pruning.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Sun, 01 Sep 2026 08:55:00 GMT
---
# Measuring and Optimizing Flutter Application Size

## Contents
- [App Size Measurement Guidelines](#app-size-measurement-guidelines)
- [Size Analysis Workflows](#size-analysis-workflows)
- [Optimization Techniques](#optimization-techniques)
  - [1. Split APKs by Target ABI](#1-split-apks-by-target-abi)
  - [2. Code Shrinking & Obfuscation (R8/ProGuard)](#2-code-shrinking--obfuscation-r8proguard)
  - [3. Font & Icon Tree Shaking](#3-font--icon-tree-shaking)
  - [4. Asset & Image Optimization](#4-asset--image-optimization)
  - [5. Unused Dependency Pruning](#5-unused-dependency-pruning)
  - [6. Deferred & Dynamic Loading](#6-deferred--dynamic-loading)
- [Step-by-Step Optimization Workflow](#step-by-step-optimization-workflow)

---

## App Size Measurement Guidelines

Always measure the release build when assessing app size, never the debug build.
- **Debug builds (`debug.apk`)** include JIT compilation, full debugging symbols, and observatory/developer tools, which make the binary 3-5x larger than actual production.
- **Release builds (`app-release.apk` / `app-release.aab`)** use AOT (Ahead-of-Time) compilation, dead code elimination, and code shrinking.

### Key Metrics:
- **Download Size:** The compressed size transferred over the network when a user downloads the app from Google Play / App Store.
- **Install Size:** The unpacked size of the application on the user's storage device.

---

## Size Analysis Workflows

### 1. Generating a Size Breakdown JSON
Run the Flutter build command with the `--analyze-size` flag:

```bash
# For Android APK
flutter build apk --release --analyze-size

# For Android App Bundle (Recommended for Google Play)
flutter build appbundle --release --analyze-size

# For Split Per ABI (Arm64, Armeabi, x86_64)
flutter build apk --release --split-per-abi --analyze-size
```

This generates a summary table in the terminal and saves a detailed JSON file (e.g. `build/apk-code-size-analysis_01.json`).

### 2. Inspecting in Dart DevTools App Size Tool
Open the DevTools App Size tool to visualize code size:
```bash
flutter pub global run devtools
```
Load the generated `apk-code-size-analysis_XX.json` to inspect treemaps of native libraries, Dart AOT snapshots, and asset contributions.

---

## Optimization Techniques

### 1. Split APKs by Target ABI
By default, `flutter build apk --release` produces a "fat APK" containing native binaries for `armeabi-v7a`, `arm64-v8a`, and `x86_64`.
Splitting by ABI reduces APK size by **~50-60%**:

```bash
flutter build apk --release --split-per-abi
```
Outputs:
- `app-arm64-v8a-release.apk` (modern 64-bit Android phones)
- `app-armeabi-v7a-release.apk` (legacy 32-bit Android phones)
- `app-x86_64-release.apk` (emulators & Chromebooks)

### 2. Code Shrinking & Obfuscation (R8/ProGuard)
Ensure Android R8 code shrinking and resource shrinking are enabled in `android/app/build.gradle`:

```groovy
android {
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

Enable Dart code obfuscation and split debug info:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### 3. Font & Icon Tree Shaking
- Flutter automatically tree-shakes unused icons from icon fonts (like Material Icons) in release mode (`--tree-shake-icons`).
- Do not bundle entire unused `.ttf` font files if using `google_fonts` (Google Fonts downloads on-demand or can be bundled minimally).

### 4. Asset & Image Optimization
- Compress PNG and JPEG images using WebP or tinypng before bundling in `assets/`.
- Use vector SVGs via `flutter_svg` for UI icons rather than large multi-resolution raster bitmaps.
- Avoid bundling unused sample media in production assets.

### 5. Unused Dependency Pruning
- Regularly audit `pubspec.yaml` and remove obsolete packages.
- Avoid heavy binary dependencies when lightweight native MethodChannels can achieve the same goal.

---

## Step-by-Step Optimization Workflow

**Task Progress:**
- [ ] Measure baseline release build size: `flutter build apk --release --analyze-size`.
- [ ] Identify top contributors in code size analysis (AOT Dart snapshot, native `.so` libs, or assets).
- [ ] Apply ABI splitting (`--split-per-abi`) or App Bundle format (`appbundle`).
- [ ] Compress large images in `assets/` into modern WebP format or optimized PNGs.
- [ ] Verify `android/app/build.gradle` has `minifyEnabled true` and `shrinkResources true`.
- [ ] Rebuild and compare final release sizes.
