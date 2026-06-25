# Architecture

## Goal

NJUPT-AutoConnect is a manual one-click campus network login helper. It is intentionally not a daemon, APK, EXE installer, or cloud service.

The first screen stays simple: connect to the NJUPT Wi-Fi, open the saved page or bookmark, and click once.

## Main Flow

```text
open PWA
  -> load saved local profile
  -> user clicks "连接校园网"
  -> build intranet gateway URL
  -> navigate browser to the login URL
  -> user returns to normal browsing after authentication
```

The primary URL is:

```text
http://10.10.244.11:801/eportal/portal/login
```

The PWA does not wait for a cross-origin response. Browser security rules make that unreliable, and the user only needs the request to reach the campus gateway.

## Daily Entry Strategy

There are three practical entries:

```text
GitHub Pages PWA
  best for first setup while internet is available

Installed/cached PWA
  good after the page has been opened once on the device

Generated direct bookmark
  best when GitHub Pages cannot load before campus authentication
```

The direct bookmark is deliberately shown after credentials are saved because it is the simplest no-install way to open the campus gateway while the device is still unauthenticated.

## Storage

PWA storage:

- `localStorage` key: `njupt.autoconnect.profile.v1`
- saved fields: account, ISP, remember-password flag, optional password
- clear action: removes the local profile immediately

Windows script storage:

- config: `%APPDATA%\NJUPT-AutoConnect\config.json`
- password: `%APPDATA%\NJUPT-AutoConnect\password.dpapi`
- encryption: Windows DPAPI through `ConvertFrom-SecureString`
- login request: `curl.exe --noproxy "*"` to the same intranet gateway URL

No server stores or receives saved credentials.

## Files

```text
web/index.html                 main one-click PWA
web/sw.js                      offline cache service worker
web/manifest.webmanifest       add-to-home-screen metadata
web/icon.svg                   simple local app icon
scripts/windows/connect.cmd    double-click launcher
scripts/windows/connect.ps1    DPAPI-backed Windows one-click script
.github/workflows/pages.yml    publishes web/ to GitHub Pages
```

## Constraints

- The device must already be connected to `NJUPT`, `NJUPT-CMCC`, or `NJUPT-CHINANET`.
- GitHub Pages may not load before Portal authentication unless the PWA has already been cached.
- A direct bookmark can work before internet access, but it contains credentials in the URL.
- PWA cannot reliably detect current Wi-Fi SSID or internet status across browsers, so it only sends a login request when the user clicks.
- Service Worker works on HTTPS/localhost, not when opened directly as `file://`.
- Browser localStorage password saving is convenient but less protected than system keychain storage; users can disable password saving.

## Future Work

- Add a "copy direct link" control if bookmark creation is not obvious enough on phones.
- Add an optional local HTML generator that never depends on GitHub Pages.
- Add optional router/OpenWRT script only after the one-click PWA is validated on campus network.
