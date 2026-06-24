# Architecture

## Goal

NJUPT-AutoConnect is a manual one-click campus network login helper. It is intentionally not a daemon, APK, EXE installer, or cloud service.

## Main Flow

```text
open PWA
  -> load saved local profile
  -> user clicks "连接校园网"
  -> build NJUPT Portal URL
  -> try JSONP login request
  -> show success/failure
  -> if JSONP fails, show "打开登录链接"
```

## Storage

PWA storage:

- `localStorage` key: `njupt.autoconnect.profile.v1`
- saved fields: account, ISP, remember-password flag, optional password
- clear action: removes the local profile immediately

Windows script storage:

- config: `%APPDATA%\NJUPT-AutoConnect\config.json`
- password: `%APPDATA%\NJUPT-AutoConnect\password.dpapi`
- encryption: Windows DPAPI through `ConvertFrom-SecureString`

No server stores or receives saved credentials.

## Files

```text
web/index.html                 main one-click PWA
web/sw.js                      offline cache service worker
web/manifest.webmanifest       add-to-home-screen metadata
web/icon.svg                   simple local app icon
scripts/windows/connect.cmd    double-click launcher
scripts/windows/connect.ps1    DPAPI-backed Windows one-click script
```

## Constraints

- PWA cannot reliably detect current Wi-Fi SSID or internet status across browsers, so it only sends a login request when the user clicks.
- Service Worker works on HTTPS/localhost, not when opened directly as `file://`.
- Browser localStorage password saving is convenient but less protected than system keychain storage; users can disable password saving.
- If JSONP is blocked, the fallback opens the generated Portal login link in the browser.

## Future Work

- Publish `web/` with GitHub Pages.
- Add a no-password Shortcut template for iOS if PWA fallback is not enough.
- Add optional router/OpenWRT script only after the one-click PWA is validated on campus network.
