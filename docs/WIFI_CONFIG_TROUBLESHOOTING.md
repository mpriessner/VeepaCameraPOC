# WiFi Configuration Troubleshooting Guide

**Date:** January 18, 2026
**Status:** Under Investigation
**Issue:** Camera not connecting to router WiFi after `set_wifi.cgi` command

---

## 1. Problem Summary

After sending the `set_wifi.cgi` command via P2P connection:
- The app shows "Configuration possibly successful" (timeout waiting for response)
- The camera's AP hotspot disappears (expected behavior)
- Camera LED keeps blinking blue slowly
- Camera does NOT appear on the router's device list
- Cannot connect to camera via router

---

## 2. Expected vs Observed Behavior

### Expected Behavior (After Successful WiFi Config)
1. Camera receives `set_wifi.cgi` command
2. Camera reboots (AP hotspot disappears - **this is normal**)
3. Camera LED blinks while connecting to router
4. **Camera LED becomes solid** when connected
5. Camera appears on router's DHCP client list
6. Camera is accessible via new IP address

### Observed Behavior (Current)
1. Camera receives command (no response before timeout)
2. Camera reboots (AP hotspot disappears - **this happened**)
3. Camera LED **keeps blinking blue** indefinitely
4. Camera does NOT appear on router
5. Camera may still be in "searching for WiFi" state

### LED Status Guide (Typical for IP Cameras)
| LED State | Meaning |
|-----------|---------|
| Blinking Blue (fast) | Booting / Starting up |
| Blinking Blue (slow) | Searching for WiFi / Trying to connect |
| Solid Blue | Connected to WiFi successfully |
| Blinking Red | Error / No connection |
| Off | Camera powered off or LED disabled |

**Your observation:** Slow blue blinking = Camera is searching/trying to connect but failing

---

## 3. The `set_wifi.cgi` Format Confusion

### Multiple Formats Found in Documentation

We found **4 different formats** in the project documentation:

#### Format 1: Official SDK (camera_command.dart:1957)
```
set_wifi.cgi?ssid=...&channel=...&authtype=<string>&wpa_psk=...&enable=1&
```
- **Source:** `Veepaisdk/flutter-sdk-demo/lib/camera_device/commands/camera_command.dart`
- **Used via:** P2P connection (already authenticated)
- **authtype:** String from scan results (e.g., "WPA2PSK")

#### Format 2: MASTER_TROUBLESHOOTING_GUIDE.md
```
set_wifi.cgi?loginuse=admin&loginpas=888888&ssid=...&pass=...&authtype=2&enctype=4
```
- **Used via:** HTTP direct access (browser)
- **authtype:** Numeric (0=Open, 1=WEP, 2=WPA, 3=WPA2)
- **Includes:** Authentication params (`loginuse`, `loginpas`)

#### Format 3: EPIC_ROUTER_WIFI_CONNECTION.md
```
set_wifi.cgi?ssid=...&channel=...&authtype=WPA2&wpa_psk=...&enable=1&
```
- **authtype:** String (e.g., "WPA2")

#### Format 4: story-11.3-wifi-provisioning.md
```
set_wifi.cgi?ssid=...&password=...&enctype=WPA2
```
- Uses `password=` instead of `wpa_psk=`
- Uses `enctype=` instead of `authtype=`

### Which Format is Correct?

**Recommendation:** Trust the **official SDK source code** (Format 1) as the authoritative reference:
```
set_wifi.cgi?ssid=${encoded}&channel=${channel}&authtype=${security_string}&wpa_psk=${encoded_password}&enable=1&
```

**Reasoning:**
- SDK is provided by the camera vendor
- SDK is actually used in production apps
- Documentation may be outdated or for different camera models

---

## 4. Possible Causes of Failure

### A. Password Issue
- WiFi password entered incorrectly
- Special characters not URL-encoded properly
- Password too long or has unsupported characters

### B. Security Type Mismatch
- The `authtype` value from scan doesn't match what camera expects
- Some cameras need numeric authtype (0, 1, 2, 3)
- Some cameras need string authtype ("WPA2PSK", "WPA2")

### C. Channel Issue
- Router may have changed channels (auto-channel selection)
- Channel from scan may not match router's current channel

### D. Network Not Reachable
- Router's WiFi signal too weak at camera location
- 5GHz network selected but camera only supports 2.4GHz
- Hidden SSID not handled correctly

### E. Command Not Received
- P2P connection dropped before command was processed
- Camera rebooted before processing the command

---

## 5. Testing & Verification Steps

### Step 1: Check Camera's Current State
After attempting WiFi config:
1. **Wait 60 seconds** for camera to fully reboot
2. **Check router's device list** - look for new device
3. **Check if camera hotspot reappears** - if yes, config failed and camera reverted

### Step 2: Try HTTP Direct Test (if hotspot available)
If camera hotspot reappears, connect to it and test via browser:
```
http://192.168.168.1:81/set_wifi.cgi?loginuse=admin&loginpas=888888&ssid=YOUR_SSID&pass=YOUR_PASSWORD&authtype=2&enctype=4
```
Replace:
- `YOUR_SSID` = your router's WiFi name (URL encode special chars)
- `YOUR_PASSWORD` = your WiFi password (URL encode special chars)

### Step 3: Verify Credentials Work
Test that you can still login to camera:
```
http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888
```
Should return device info text.

### Step 4: Check Scan Results
Look at the scan results in app logs:
- What does `authtype` / `ap_security` show? (e.g., "WPA2PSK", "WPA2", "3")
- Does it match your router's actual security type?

### Step 5: Factory Reset and Retry
1. **Factory reset camera** (hold reset button >10 seconds)
2. Wait for camera to restart
3. Connect phone to camera hotspot
4. Run WiFi setup flow again
5. Use a simple WiFi password (no special characters) for testing

---

## 6. Debugging Checklist

- [ ] WiFi password is correct (test on another device)
- [ ] Router is 2.4GHz (not 5GHz only)
- [ ] Router SSID has no special characters (test with simple name)
- [ ] Camera is within good WiFi range of router
- [ ] Check app logs for exact CGI command sent
- [ ] Check app logs for any error response
- [ ] Try HTTP method if P2P method fails

---

## 7. Implementation Recommendations

### For Next AI Agent / Developer

1. **Log the exact command sent** - include full CGI string (mask password)
2. **Log the security string from scan** - verify format (string vs number)
3. **Try both formats** - SDK format first, HTTP format as fallback
4. **Add retry logic** - camera may need multiple attempts
5. **Verify via HTTP** - after config, try direct HTTP access to confirm

### Potential Code Fix to Try

If SDK format fails, try adding authentication params:
```dart
// Try with authentication params (HTTP style)
final cgiCommand = 'set_wifi.cgi?'
    'loginuse=admin&'
    'loginpas=888888&'
    'ssid=$encodedSsid&'
    'pass=$encodedPassword&'
    'authtype=3&'  // 3 = WPA2-PSK
    'enctype=4';   // 4 = AES
```

### Questions to Resolve

1. What exact value does `ap_security[$i]` return from scan? Log it.
2. Does the camera expect string or numeric `authtype`?
3. Is `enctype` required for this camera model?
4. Does the camera need `enable=1` or is it optional?

---

## 8. Current Implementation (as of Jan 18, 2026)

**File:** `flutter_veepa_module/lib/screens/wifi_setup_screen.dart`

**Current format used:**
```dart
final cgiCommand = 'set_wifi.cgi?'
    'ssid=$encodedSsid&'
    'channel=${network.channel}&'
    'authtype=${network.security}&'
    'wpa_psk=$encodedPassword&'
    'enable=1&';
```

**This matches the official SDK format.**

---

## 9. References

- Official SDK: `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/camera_device/commands/camera_command.dart` (lines 1955-1977)
- CGI Manual: `docs/official_documentation/CGI_COMMAND_MANUAL_v12_20231223.md`
- Epic: `docs/stories/EPIC_ROUTER_WIFI_CONNECTION.md`

---

## 10. Status Updates

| Date | Update |
|------|--------|
| 2026-01-18 | Initial investigation - camera LED blinking, not connecting |
| | Found 4 different CGI formats in documentation |
| | Implemented SDK format (Format 1) - FAILED |
| | Camera hotspot disappears but camera doesn't appear on router |
| **2026-01-18** | **SOLVED via HTTP direct test** |
| | **Working format:** `set_wifi.cgi?loginuse=admin&loginpas=888888&ssid=...&pass=...&authtype=3&enctype=4` |
| | Key differences from SDK format: |
| | - Requires `loginuse=admin&loginpas=888888` (auth params) |
| | - Uses `pass=` instead of `wpa_psk=` |
| | - Uses numeric `authtype=3` (not string) |
| | - Requires `enctype=4` |
| | Code updated in wifi_setup_screen.dart |

---

## 11. VERIFIED WORKING FORMAT

**Tested and confirmed working on 2026-01-18:**

```
set_wifi.cgi?loginuse=admin&loginpas=888888&ssid=<SSID>&pass=<PASSWORD>&authtype=3&enctype=4
```

**Parameters:**
| Parameter | Value | Notes |
|-----------|-------|-------|
| `loginuse` | `admin` | Required for authentication |
| `loginpas` | `888888` | Default camera password |
| `ssid` | URL-encoded SSID | Network name |
| `pass` | URL-encoded password | WiFi password (NOT `wpa_psk`) |
| `authtype` | `3` | Numeric: 0=Open, 1=WEP, 2=WPA, 3=WPA2 |
| `enctype` | `4` | Encryption type (4=AES) |

**What was wrong with the SDK format:**
- SDK uses `wpa_psk=` but camera needs `pass=`
- SDK passes security string directly, but camera needs numeric `authtype`
- SDK doesn't include `loginuse`/`loginpas` or `enctype`
