# Dynamic Fast Dowload URLs AMXX

A dynamic FastDL (Fast Download) URL load balancer for AMX Mod X servers.

This plugin automatically assigns the closest available FastDL server to players based on **region** or **country code**, with automatic health checks, fallback logic, and full configurability via INI + JSON.

---

## 🔧 Features

-   Region-based or Country-based FastDL selection
-   Automatic server availability checks
-   Automatic health-check fast download URL servers
-   Automatic fallback when servers go down
-   Logging system for errors and info
-   JSON-based FastDL configuration
-   Supports any number of regions / countries

---

## ⚙️ Requirements

Make sure your server meets the following minimum versions:

- **AMX Mod X** `1.9.0-5271+`
- **ReHLDS** `v3.14.0.857+`
- **ReAPI** `v5.26.0.338 +`
- **[AmxxEasyHTTP](https://github.com/Next21Team/AmxxEasyHttp)**  `v1.4.0+` 

NOTE: For **AmxxEasyHTTP**, besides [easy_http.inc](https://github.com/Next21Team/AmxxEasyHttp/blob/main/amxx/scripting/include/easy_http.inc), you will also need [easy_http_json.inc](https://github.com/Next21Team/AmxxEasyHttp/blob/main/amxx/scripting/include/easy_http_json.inc).

---

## 🧩 Flowchart diagram
<img width="1481" height="517" alt="image" src="https://github.com/user-attachments/assets/071e71fd-62a4-4674-a76c-0ad4a151ef09" />



---

## 🌍 FastDL Mirror JSON Format

``` json
{
  "0:EU": [
    "http://fastdl-eu.example.com/cstrike"
  ],
  "0:US": [
    "http://fastdl-us.example.com/cstrike"
  ],
  "1:RO": [
    "http://fastdl-ro.example.com/cstrike"
  ],
  "1:DE": [
    "http://fastdl-de.example.com/cstrike"
  ],
  "1:EN": [
    "http://fastdl-en.example.com/cstrike"
  ]
}
```

---

# 🧠 How It Works

### 1. Region-Based Mode (`REGION_BASED_FASTDL = 1`)

-   Player's region / country is detected using `geoip` module.
-   Plugin selects matching `"0:<Region>"`
-   Falls back if needed

### 2. Country-Based Mode (`REGION_BASED_FASTDL = 0`)

-   Uses `"1:<CountryCode>"` entries

---

## 🩺 DownloadURL Server Health Checking

-   Runs every `DOWNLOADURL_CHECK_INTERVAL` seconds
-   Down URLs are skipped and logged
-   Automatically recovers healthy URLs

---

## 📝 TODOs
-   Multiple FastDL mirrors per region/country

---

## 📄 License

- Database and Contents Copyright (c) [MaxMind](https://www.maxmind.com/), Inc.
- [GeoLite2 End User License Agreement](https://www.maxmind.com/en/geolite2/eula)
- [Creative Commons Corporation Attribution-ShareAlike 4.0 International License (the "Creative Commons License")](https://creativecommons.org/licenses/by-sa/4.0/)
