# Glucose Glance

A personal iPhone app that shows a Dexcom CGM reading at a glance, modelled on Sugarmate.

> Not a medical device. Readings can be delayed or missing. Always confirm with the Dexcom app, a receiver or a fingerstick before treating.

## What's in v1

| Feature | Where you see it |
| --- | --- |
| Big current value, trend arrow, change since last reading, "x min ago" | App dashboard |
| 3h / 6h / 12h / 24h chart with your target range shaded | App dashboard |
| Small and medium Home Screen widgets (medium has a 3h mini chart) | Home Screen |
| Round Lock Screen "bubble" (value with arrow) | Lock Screen, `accessoryCircular` |
| Rectangular Lock Screen widget with mini chart, plus an inline one above the clock | Lock Screen |
| Live Activity with Dynamic Island (value on the left, arrow on the right) | Lock Screen and top of screen, toggle in the app |
| mmol/L by default (switchable to mg/dL), adjustable low and high targets | Settings |
| Stale data warning when nothing new has arrived for 15 minutes | Everywhere |

## How it gets data

Like Sugarmate, it reads from **Dexcom Share** using the sensor wearer's own Dexcom login. In the Dexcom G6/G7 app, Share has to be turned on with at least one follower (Dexcom Follow) or the data won't be available. Canadian accounts use the "Outside US" region.

Share is not an official public API. It's what Sugarmate, Nightscout and pydexcom all rely on, but Dexcom could change it. Credentials are kept in the iPhone Keychain and only ever sent to Dexcom.

## Running it on your iPhone

You need a Mac with Xcode 15 or newer.

1. Install XcodeGen: `brew install xcodegen`
2. In this folder run `xcodegen generate`, then open `GlucoseGlance.xcodeproj`
3. For both targets (GlucoseGlance and GlucoseGlanceWidgets), go to Signing & Capabilities and pick your team. Or set `DEVELOPMENT_TEAM` in `project.yml` once and regenerate.
4. If Xcode says the bundle ID or App Group is taken, replace `com.gurjotmann.glucoseglance` everywhere in `project.yml` with something unique, then regenerate.
5. Plug in your iPhone, pick it as the run destination and press Run.
6. Add widgets: long-press the Home Screen or Lock Screen, tap Customize, and add "Glucose".

A free Apple ID can install it, but the app stops opening after 7 days and has to be reinstalled from Xcode. The paid Apple Developer Program ($99 USD/yr) removes that limit, allows TestFlight, and is required for phase 2 below.

## Known limits (iOS rules, not bugs)

* **Widgets**: iOS rations widget refreshes, so they usually update every 15 to 30 minutes, not every 5. Each widget shows the time of the reading and greys out once it's stale, so an old number never looks current.
* **Live Activity**: updates every 5 minutes while the app is open. Once the app is in the background, iOS only lets it refresh occasionally, so the Live Activity can fall behind. iOS also ends Live Activities after 8 hours. Sugarmate solves both with its own server that pushes updates (see phase 2).
* **No alerts yet**. Keep Dexcom's own alerts on.

## Roadmap

* **Phase 2, small server for real-time updates.** A tiny cloud service polls Dexcom every 5 minutes and sends Apple push updates to the Live Activity (and can restart it after the 8 hour limit). This is how Sugarmate keeps its Live Activity current. Needs the paid developer account for push.
* **Phase 3, alerts.** High, low and "falling fast" notifications, plus optional repeat alerts.
* **Phase 4, extras.** Apple Watch complication, StandBy mode layout, time in range stats, carb/insulin notes, Siri/Shortcuts ("what's my sugar?").

## Project layout

```
GlucoseGlance/
  project.yml          XcodeGen spec (app + widget extension, App Group, shared Keychain)
  Shared/              Code used by both the app and widgets
    Glucose.swift        Reading, trend, units, target range, settings
    DexcomShareClient.swift
    Storage.swift        App Group cache and Keychain credentials
    GlucoseActivityAttributes.swift
    GlucoseChart.swift
  App/                 The iPhone app (dashboard, sign in, settings, Live Activity control)
  Widgets/             Home Screen, Lock Screen and Live Activity / Dynamic Island UI
```

A GitHub Actions workflow (`.github/workflows/glucoseglance-build.yml`) compiles the project on every push so build errors show up without needing a Mac.
