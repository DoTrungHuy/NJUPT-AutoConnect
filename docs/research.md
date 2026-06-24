# Research Notes

## Portal Endpoint

NJUPT campus network examples and public scripts commonly use the Dr.COM Portal endpoint:

```text
https://p.njupt.edu.cn:802/eportal/portal/login
```

Login parameters used by the one-click PWA:

```text
callback=dr1003
login_method=1
user_account=,0,<account><isp-suffix>
user_password=<password>
wlan_user_ip=
wlan_user_ipv6=
wlan_user_mac=000000000000
wlan_ac_ip=
wlan_ac_name=
jsVersion=4.1.3
terminal_type=1
lang=zh-cn
```

ISP suffixes:

```text
教育网: empty suffix
电信:   @njxy
移动:   @cmcc
```

## Why PWA First

The current goal is convenience, not background automation. A static PWA is the lightest cross-device route:

- no APK or EXE installer
- works on phones, tablets, and PCs
- can be added to the home screen
- can be hosted on GitHub Pages
- can still be downloaded and opened locally

The PWA uses JSONP because a normal browser `fetch()` to the Portal endpoint is likely to hit CORS restrictions. If JSONP fails, the page exposes a fallback link.

## Known Limits

- Browser localStorage is not as protected as Windows DPAPI or a system keychain.
- Service Worker offline caching requires HTTPS or localhost; it cannot register from a direct `file://` open.
- The page cannot reliably detect whether the device is already online or which Wi-Fi SSID is active, so users should click only when they need campus network login.
- Repeated Portal login attempts may disconnect an already logged-in account according to existing community scripts.

## References

- NJUPT 信息化办上网指南: https://xxb.njupt.edu.cn/wlfw_18365/list.htm
- s235784/NJUPT_AutoLogin: https://github.com/s235784/NJUPT_AutoLogin
- ArcticLampyrid/njupt_wifi_login: https://github.com/ArcticLampyrid/njupt_wifi_login
- Lintkey/njupt_net: https://github.com/Lintkey/njupt_net
- WiIIiamWei/NJUPT-login: https://github.com/WiIIiamWei/NJUPT-login
