# Echo

A personal music player for iPhone. Your audio, covers and accounts stay on your phone: no servers, no ads, no subscription.

The app is a thin native Swift shell (`WKWebView`) around a single `index.html`. The page is bundled inside the app and loads locally, so no internet is needed to run it.

## Features

- Add tracks from Files or the photo library: mp3, m4a, wav, mp4, mov (only the audio is used from videos).
- Title, artist and cover are read from ID3 tags and can be edited by hand.
- Behaves like a real music player: background playback, lock screen and Control Center controls, headphones and Bluetooth.
- Keeps playing with the screen off.
- Favorites, search, sorting, shuffle, repeat all / one, sleep timer.
- Playback speed from 0.5× to 1.5×.
- Three visualizer styles and an animated hero image on the home screen.
- Custom avatar from your photo library, cropped to a circle.
- Dark and light themes, accent color, battery saver.
- Multiple local accounts on one phone.

## Echo Premium

| | Free | Premium |
|---|:---:|:---:|
| Playback, favorites, search, sleep timer | ✓ | ✓ |
| Avatar from the photo library | ✓ | ✓ |
| Accent colors | 3 | 7 |
| Echo effect | | ✓ |
| Equalizer with five presets | | ✓ |
| 8D audio | | ✓ |
| Neon glow around the cover | | ✓ |
| Gold avatar ring and PRO badge | | ✓ |
| Tracks in the library | up to 30 | unlimited |

### Configuring premium

Everything lives at the top of the script in `index.html`:

```js
var FREE_LIMIT=30, PRO_PRICE='199 ₽', DEMO_BUY=true, PROMOS=['...'];
```

- `FREE_LIMIT`: how many tracks the free version allows.
- `PRO_PRICE`: price shown on the button.
- `DEMO_BUY`: while `true`, the buy button unlocks premium for free (test mode). Set it to `false` so premium unlocks only with a promo code or a real purchase.
- `PROMOS`: promo code hashes, produced by `h53(CODE_IN_UPPERCASE, 7)`.

> **Note.** Premium here is built in without real payments. An unsigned IPA installed through Sideloadly or AltStore cannot take Apple payments. Real purchases need a paid Apple Developer account, a product in App Store Connect and StoreKit code in `App.swift`. `index.html` already has the bridge for it: it posts `{action:'buy'}` and `{action:'restore'}` to an `echoIAP` message handler and expects the result via `window.echoProResult(true|false)`. Promo codes are checked on the device, which is fine for gifts but not tamper-proof.

## Building the IPA

The build runs on GitHub Actions, no Mac required.

1. Push `App.swift`, `index.html`, `project.yml`, `icon.png`, `make_icon.py`, `Contents.json` and `.github/workflows/main.yml` to your repository.
2. Open the **Actions** tab, pick **Build unsigned IPA** and press **Run workflow** (or just push to `main`).
3. After a minute or two the run contains an **Echo-IPA** artifact. Download and unzip it to get `Echo.ipa`.

The workflow draws the app icon (`make_icon.py`), generates the Xcode project from `project.yml` with XcodeGen and builds an unsigned IPA.

## Installing on iPhone

The IPA is unsigned, so sign it with your own Apple ID using Sideloadly, AltStore, or TrollStore where your iOS version supports it. A free Apple ID needs re-signing every 7 days.

## Background playback

- Music plays through a regular `<audio>` element, so iOS treats it as a song and keeps it alive when the screen locks.
- `UIBackgroundModes: audio` and a `playback` audio session are enabled.
- Echo, EQ and 8D use Web Audio. While they are off, audio goes straight to the output. If sound cuts out on lock with effects on, reset them and restart the app.
- Without effects, the visualizer is decorative rather than driven by the real spectrum. With effects it shows the real spectrum.

## Project layout

| File | Purpose |
|---|---|
| `index.html` | The whole UI and player logic |
| `App.swift` | `WKWebView` shell, `echo://` scheme, audio session |
| `project.yml` | XcodeGen project description |
| `make_icon.py` | App icon generator |
| `.github/workflows/main.yml` | GitHub Actions IPA build |

## Updating

Edits to `index.html` reach the app only after a new build and reinstall. Installing over the old version keeps tracks and accounts.

## Privacy

The app sends nothing over the network. Accounts, tracks, covers, avatars and premium status stay in the app's storage on this phone.
