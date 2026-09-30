# Float · VisualPhone for HarmonyOS

**English** · [中文](./README.zh-CN.md)

A third-party HarmonyOS HAP shell for [xiaolongbao0709/ai-virtual-phone](https://github.com/xiaolongbao0709/ai-virtual-phone), running fully offline in full screen.

> This project only provides a HarmonyOS runtime container for the upstream Web project. **No upstream business code is modified.**

## Features

- **Fully offline**: Next.js static output embedded into the HAP, no web server required
- **Full-screen adaptive**: fits any HarmonyOS device resolution, no phone-shell decoration, content fills the entire screen
- **Self-hosted mode**: `NEXT_PUBLIC_SELF_HOSTED_MODE=true` by default, skips account gate
- **Keeps all upstream single-device features**: chat, character cards, world book, games, 3D world builder, etc.

## Requirements

| Tool | Version |
|---|---|
| DevEco Studio | 5.x |
| HarmonyOS SDK | API 12+ |
| Node.js | 20+ (for building the upstream Web project) |

## Build Steps

### 1. Build the upstream Web project

```bash
git clone https://github.com/xiaolongbao0709/ai-virtual-phone
cd ai-virtual-phone
```

Edit `next.config.mjs`, add static export configuration:

```javascript
const nextConfig = {
  output: 'export',
  assetPrefix: './',
  images: { unoptimized: true },
  // ... keep other existing config
};
```

Build the static output:

```bash
NEXT_PUBLIC_SELF_HOSTED_MODE=true npm run build
```

This generates an `out/` directory in the project root.

### 2. Copy static files

Copy **everything** inside `out/` into this project's:

```
entry/src/main/resources/rawfile/
```

### 3. Configure signing

1. Copy the example config:

   ```bash
   cp build-profile-example.json5 build-profile.json5
   ```

2. Open this project in DevEco Studio

3. `File → Project Structure → Signing Configs` → check `Automatically generate signature`

4. Sign in with your Huawei Developer account. The IDE will write signing info into `build-profile.json5`.

### 4. Build the HAP

`Build → Build Hap(s)/APP(s) → Build Hap(s)`

The artifact is located at:

```
entry/build/default/outputs/default/entry-default-signed.hap
```

## Bundle Name

```
io.github.xiaolongbao.likeeevernight.float
```

## Project Structure

```
float-visualphone-harmony/
├── AppScope/
│   ├── app.json5                # App config (bundleName, version)
│   └── resources/               # App icon, name
├── entry/
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/    # UIAbility entry (full-screen setup)
│   │   │   └── pages/Index.ets  # WebView host (resource intercept, CSS injection)
│   │   ├── resources/
│   │   │   └── rawfile/         # ★ upstream Web static output goes here
│   │   └── module.json5         # Module config, permissions
│   └── build-profile.json5
├── build-profile-example.json5  # App-level signing config template (no signature)
└── README.md
```

## Core Implementation

### Key techniques in `Index.ets`

1. **Virtual domain + SchemeHandler intercept**  
   Maps requests to `https://app.local/` to local files inside `rawfile/`, bypassing ArkWeb's cross-origin restriction on `resource://`.

2. **HTML injection**  
   When serving `index.html`, injects a `<script>` at the very beginning of `<head>`, running before any project code.

3. **CSS override**  
   For containers like `.phone-shell` / `.phone-case` / `.phone-frame`, forcibly zeroes out `padding`, `margin`, `border`, `background`, and sets `100vw × 100vh` to fill the screen.

4. **Environment spoofing**  
   Overrides `navigator.maxTouchPoints`, `matchMedia`, `screen.orientation`, etc., so the project believes it runs on a mobile browser.

### Key techniques in `EntryAbility.ets`

- `setWindowLayoutFullScreen(true)` — extends content behind the status bar and navigation bar
- `setWindowSystemBarProperties` — makes system bars transparent, icons black

## Upstream Project

- **Author**: xiaolongbao0709
- **Repository**: https://github.com/xiaolongbao0709/ai-virtual-phone
- **License**: AGPL-3.0-only

## Known Limitations

- Only supports HarmonyOS devices (HAP format)
- Users must build the upstream `out/` directory themselves and copy it into `rawfile/` (this repo does not ship the Web output, out of respect for upstream copyright)
- Community features (account, app market, game hall, etc.) are automatically hidden in the upstream self-hosted mode

## License

**AGPL-3.0-only** (consistent with upstream)

The upstream project is licensed under GNU Affero General Public License v3.0 only. This shell project, as a derivative work, follows the same license. See [LICENSE](./LICENSE).

## Credits

- Upstream Web project by [xiaolongbao0709](https://github.com/xiaolongbao0709)
- Product design and system abstractions inspired by [SillyTavern](https://github.com/SillyTavern/SillyTavern)