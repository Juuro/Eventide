# Eventide

A calm, private evening-ritual app for iPhone. Each night, jot down **5 things you did well** and **5 things you enjoyed** — under two minutes, then close the app.

## Run

```bash
open Eventide.xcodeproj
```

Select an iPhone simulator (or a device) and press ⌘R. Requires Xcode 16+ / iOS 17+.

## What it does

- One reflection per calendar day, with a prominent date header.
- Two sections of five short rows each; tap a row and type.
- **Auto-saves as you type** — no save button. Powered by SwiftData, stored locally on-device only (no network, no accounts).
- A progress indicator (10 dots + count) and a gentle "all ten" done state.
- A calendar button opens **Past days** — a list of earlier reflections you can reopen and edit.

## Structure

| Layer | Files |
|---|---|
| Model | `Models/DayReflection.swift` — `@Model`, two `[String]` of 5, `filledCount`/`isComplete` |
| Persistence | SwiftData `ModelContainer` in `EventideApp.swift` |
| Views | `RootView`, `HomeView` (today, fetch-or-create), `ReflectionEditor` (shared), `PastEntriesView`, `DayDetailView` |
| Support | `ReflectionSection` (labels + microcopy), `Theme` (colors, spacing, date formats) |

## Accessibility

Dynamic Type throughout, 44pt+ touch targets, VoiceOver labels on rows and progress, system materials for automatic light/dark + contrast adaptation.
