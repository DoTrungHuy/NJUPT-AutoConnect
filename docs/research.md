# Research Notes

## Official Network Flow

NJUPT's official student network guide describes a web Portal flow:

- connect to `NJUPT`, `NJUPT-CMCC`, or `NJUPT-CHINANET`
- obtain an address through DHCP
- open a browser and authenticate through the Portal
- if the Portal does not appear automatically, open `p.njupt.edu.cn`

The same guide lists `NJUPT`, `NJUPT-CMCC`, and `NJUPT-CHINANET` as the common Wi-Fi entries.

## Existing Community Implementations

Public NJUPT scripts point to two practical login styles.

### Full Dr.COM Portal Request

Several scripts use the Dr.COM Portal endpoint:

```text
https://p.njupt.edu.cn:802/eportal/portal/login
https://10.10.244.11:802/eportal/portal/login
```

Common parameters:

```text
callback=dr1003
login_method=1
user_account=,0,<account><isp-suffix>
user_password=<password>
wlan_user_ip=<device-ip>
```

Important detail: working CLI/router implementations usually detect and pass the current device IPv4 address. A browser-only PWA cannot reliably read the local Wi-Fi IPv4 address or fetch `p.njupt.edu.cn/a79.htm` because of browser privacy and cross-origin limits.

### Fast Intranet GET Request

`lux-QAQ/NJUPT_Fastlogin` uses the intranet gateway IP directly and describes NJUPT login as a GET request carrying account and password. This avoids depending on external DNS and is better aligned with a no-install, manual one-click page.

The current PWA and Windows script therefore use:

```text
http://10.10.244.11:801/eportal/portal/login?login_method=1&user_account=...&user_password=...
```

This path has the best fit for the current product goal:

- no app package
- no background service
- no local IP detection
- can be saved as a normal browser bookmark
- can work when GitHub Pages cannot be reached, as long as the device is connected to the NJUPT Wi-Fi network

## ISP Suffixes

```text
教育网: empty suffix
电信:   @njxy
移动:   @cmcc
```

The PWA encodes the account as:

```text
,0,<account><isp-suffix>
```

## Why The First PWA Test Could Fail

The first version tried to send a JSONP request to the `p.njupt.edu.cn:802` Portal endpoint with an empty `wlan_user_ip`. That is fragile for two reasons:

- many working scripts include the local IPv4 address
- the online PWA itself is hosted on GitHub Pages, which may be unreachable before Portal authentication

The updated version treats GitHub Pages only as the first setup/generator page. The durable daily fallback is the generated intranet direct link.

## Known Limits

- Browser localStorage is not as protected as Windows DPAPI or a system keychain.
- Service Worker offline caching requires HTTPS or localhost; it cannot register from a direct `file://` open.
- The direct bookmark contains account and password in the URL, so it is only suitable for personal devices.
- The page cannot reliably detect the current Wi-Fi SSID across browsers; users must connect to an NJUPT Wi-Fi first.
- Repeated login attempts may disconnect an already logged-in account according to existing community scripts.

## References

- NJUPT 信息化办上网指南: https://xxb.njupt.edu.cn/wlfw_18365/list.htm
- NJUPT 学生服务手册 PDF: https://xxb.njupt.edu.cn/_upload/article/files/eb/d5/aeb437a84d66a533135961fa8849/e9c3b23e-4a0a-434c-989b-65ff2009ef8a.pdf
- s235784/NJUPT_AutoLogin: https://github.com/s235784/NJUPT_AutoLogin
- ArcticLampyrid/njupt_wifi_login: https://github.com/ArcticLampyrid/njupt_wifi_login
- lux-QAQ/NJUPT_Fastlogin: https://github.com/lux-QAQ/NJUPT_Fastlogin
- zeisscai/njupt.drcom: https://github.com/zeisscai/njupt.drcom
- pd12bb/NJUPT_Network_AutoLogin: https://github.com/pd12bb/NJUPT_Network_AutoLogin
- WiIIiamWei/NJUPT-login: https://github.com/WiIIiamWei/NJUPT-login
