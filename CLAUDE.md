# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

```bash
# Build for simulator (use the UDID from `xcrun simctl list` or any valid iOS 17+ sim)
xcodebuild -scheme Eventide -destination 'platform=iOS Simulator,id=<UDID>' build

# Known-good simulator ID on this machine:
xcodebuild -scheme Eventide -destination 'platform=iOS Simulator,id=839ACD2A-8B16-4887-9D4B-4EC8BA241B93' build
```

No test target exists yet. Open in Xcode with `open Eventide.xcodeproj`, select a simulator, press ⌘R.

**SourceKit false positive**: `No such module 'UIKit'` appears in diagnostics but the compiler succeeds. Ignore it.

## Architecture

iPhone-only, SwiftUI + SwiftData, iOS 17+, no network, no accounts.

**Data flow**: `EventideApp` owns the `ModelContainer`. `HomeView` fetches-or-creates today's `DayReflection` on appear and binds it to `ReflectionEditor`. Past days go through `PastEntriesView` → `DayDetailView` → same `ReflectionEditor`. All saves are implicit (SwiftData auto-saves on change).

**`DayReflection` (`@Model`)** — one instance per calendar day. Two `[String]` arrays of 5 slots each (`didWell`, `rejoiced`). Key computed properties: `filledCount`, `isComplete`, `hasAnyContent`, `didWellFilledCount`, `rejoicedFilledCount`, `previewText`. Static `currentStreak(from:)` counts consecutive days with content ending yesterday.

**`ReflectionEditor`** — the shared editing surface used by both HomeView and DayDetailView. Owns `@FocusState` (private `FieldID` enum) for auto-advancing keyboard through all 10 fields. Has a `@Query` for all reflections to compute streak. Bottom bar (`BottomProgressBadge`) pinned via `.safeAreaInset(edge: .bottom)` — always visible regardless of scroll position, compatible with `.navigationBarTitleDisplayMode(.large)`. The `showsHeader: Bool` parameter controls whether the badge renders (false in DayDetailView).

**`ReflectionSection` enum** — single source of truth for section labels, placeholder strings, colors, and SF Symbol names.

**`Theme`** — all visual constants. `Theme.accent` = indigo (Did Well), `Theme.accentRose` = systemPink (Rejoiced). Date formatting extensions live here (`reflectionHeader`, `reflectionListLabel`).

## Key constraints

- `.safeAreaInset(edge: .top)` conflicts with `.navigationBarTitleDisplayMode(.large)` — do not use it. Use `.bottom` for overlays.
- `DayReflection.init` normalizes date to `startOfDay` — always pass raw `Date`, never a pre-normalized one.
- `AccessibilityNotification.Announcement` and `.symbolEffect` require iOS 17 — already the minimum deployment target.
- All animations must be gated on `@Environment(\.accessibilityReduceMotion)`.
