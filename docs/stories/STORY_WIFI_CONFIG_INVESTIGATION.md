# Story: WiFi Configuration Investigation

**Type:** Human-in-the-Loop Investigation
**Priority:** P0 - Blocking
**Date:** January 18, 2026
**Status:** ✅ RESOLVED

---

## Problem Statement

The `set_wifi.cgi` command is being sent, but the camera fails to connect to the router WiFi. The camera LED blinks blue (searching) but never becomes solid (connected).

---

## My Analysis (Claude's Opinion)

After reviewing the SDK source code and current implementation, I've identified the **most likely root causes** in order of probability:

### Root Cause #1: Unknown `authtype` Format (90% confident)
**The Issue:** We're passing `ap_security[$i]` directly to `authtype`, but we don't know what value the camera returns. It could be:
- A number: `"3"` (WPA2)
- A string: `"WPA2PSK"` or `"WPA2"` or `"WPA2-PSK/AES"`

**Why This Matters:** If the camera expects `authtype=3` but we send `authtype=WPA2PSK`, the command will silently fail.

**Evidence:** The SDK passes `info.security` directly without transformation, suggesting the scan returns a format the camera already understands. But different camera models may have different formats.

### Root Cause #2: Parameter Name Mismatch (60% confident)
**The Issue:** Documentation shows both `wpa_psk=` and `pass=` for the password parameter.

**Why This Matters:** Wrong parameter name = camera ignores the password = auth failure on router.

### Root Cause #3: Missing Login Verification (40% confident)
**The Issue:** Current code sets `_isLoginVerified = true` without actually checking cmd 24577 response. WiFi commands might be sent before the camera has accepted the login.

**Why This Matters:** Commands sent before login is confirmed may be rejected.

---

## Investigation Plan (Human-in-the-Loop Tests)

### Test 1: Log the Security Value (5 minutes)
**Goal:** See exactly what `ap_security` returns from the scan.

**Steps:**
1. Open the app, go to WiFi Setup
2. Connect to camera
3. Scan networks
4. Look at the logs for lines like: `Found: YourNetwork (signal: 80, security: ???, ch: 6)`
5. **Record the exact security string** for your home network

**Expected Finding:** The security value (e.g., "3", "WPA2", "WPA2PSK")

---

### Test 2: Direct HTTP Test (10 minutes) ⭐ RECOMMENDED FIRST
**Goal:** Establish ground truth - find the exact CGI format that works.

**Why This First:** This bypasses all P2P complexity and gives us a definitive answer.

**Prerequisites:**
- Camera must be in AP mode (factory reset if needed)
- Phone connected to camera's hotspot

**Steps:**
1. Factory reset camera (hold reset >10 seconds)
2. Wait for camera to boot (LED blinking)
3. Connect phone to camera's WiFi hotspot (e.g., `@MC-0379196`)
4. Open Safari on phone
5. Try each URL below, one at a time (replace YOUR_SSID and YOUR_PASSWORD):

**Test 2A - SDK Format:**
```
http://192.168.168.1:81/set_wifi.cgi?ssid=YOUR_SSID&channel=6&authtype=WPA2PSK&wpa_psk=YOUR_PASSWORD&enable=1&
```

**Test 2B - Numeric authtype + wpa_psk:**
```
http://192.168.168.1:81/set_wifi.cgi?ssid=YOUR_SSID&channel=6&authtype=3&wpa_psk=YOUR_PASSWORD&enable=1&
```

**Test 2C - Numeric authtype + pass:**
```
http://192.168.168.1:81/set_wifi.cgi?ssid=YOUR_SSID&channel=6&authtype=3&pass=YOUR_PASSWORD&enable=1&
```

**Test 2D - Full HTTP format (with login params):**
```
http://192.168.168.1:81/set_wifi.cgi?loginuse=admin&loginpas=888888&ssid=YOUR_SSID&pass=YOUR_PASSWORD&authtype=3&enctype=4
```

**After each test:**
- Wait 60 seconds
- Check if camera LED becomes solid blue
- Check router's device list for new device
- If fails, factory reset and try next format

**Record which format works!**

---

### Test 3: Simple Network Test (10 minutes)
**Goal:** Rule out SSID/password encoding issues.

**Steps:**
1. Create a mobile hotspot on another phone with:
   - SSID: `testnet` (simple, no spaces)
   - Password: `test1234` (simple, alphanumeric)
   - Security: WPA2
   - Frequency: 2.4GHz only
2. Use the app to configure camera to this simple network
3. Check if camera connects

**If this works:** The issue is URL encoding of special characters in your home WiFi credentials.

---

### Test 4: Enhanced Logging Test (15 minutes)
**Goal:** See all command responses to verify the flow.

**Code Changes Required:**
1. Log cmd 24577 (login response) - check for `result=0`
2. Log cmd 24618 (scan response)
3. Log cmd 24584 (scan results)
4. Log cmd 24593 (WiFi config response)
5. Log the exact `ap_security` value for each network

**What to Look For:**
- Does cmd 24577 return `result=0`? (login successful)
- What exact value is in `ap_security`?
- Does cmd 24593 arrive? What's the `result`?

---

## Quick Decision Tree

```
START
  │
  ├─► Run Test 2 (HTTP Direct) FIRST
  │     │
  │     ├─► Test 2A works? → SDK format is correct, issue is in P2P flow
  │     ├─► Test 2B works? → Need numeric authtype
  │     ├─► Test 2C works? → Need numeric authtype + "pass" param
  │     ├─► Test 2D works? → Need full HTTP format with login params
  │     └─► None work? → Camera firmware issue or network problem
  │
  └─► If HTTP test successful, update app code to match working format
```

---

## Expected Outcomes & Next Steps

| Test Result | Next Action |
|-------------|-------------|
| Test 2A works | P2P flow has a bug; investigate command listener timing |
| Test 2B works | Update code: use numeric authtype (map string→number) |
| Test 2C works | Update code: use `pass=` instead of `wpa_psk=` + numeric authtype |
| Test 2D works | Update code: add `loginuse`, `loginpas`, `enctype` params |
| None work | Try Test 3 (simple network) to rule out encoding |
| Test 3 works | Issue is URL encoding; fix special character handling |
| Test 3 fails | Camera hardware/firmware issue or 5GHz problem |

---

## Code Reference for Fixes

### If Test 2B Works (Numeric authtype)
```dart
// Map security string to numeric value
int getAuthType(String security) {
  final s = security.toUpperCase();
  if (s.contains('WPA2')) return 3;
  if (s.contains('WPA')) return 2;
  if (s.contains('WEP')) return 1;
  return 0; // Open
}

final cgiCommand = 'set_wifi.cgi?'
    'ssid=$encodedSsid&'
    'channel=${network.channel}&'
    'authtype=${getAuthType(network.security)}&'
    'wpa_psk=$encodedPassword&'
    'enable=1&';
```

### If Test 2C Works (pass + numeric authtype)
```dart
final cgiCommand = 'set_wifi.cgi?'
    'ssid=$encodedSsid&'
    'channel=${network.channel}&'
    'authtype=${getAuthType(network.security)}&'
    'pass=$encodedPassword&'
    'enable=1&';
```

### If Test 2D Works (Full HTTP format)
```dart
final cgiCommand = 'set_wifi.cgi?'
    'loginuse=admin&'
    'loginpas=$_defaultPassword&'
    'ssid=$encodedSsid&'
    'pass=$encodedPassword&'
    'authtype=${getAuthType(network.security)}&'
    'enctype=4';
```

---

## Notes for Human Tester

1. **URL Encoding:** If your SSID or password has spaces or special characters, you need to URL encode them:
   - Space → `%20`
   - `&` → `%26`
   - `=` → `%3D`
   - `+` → `%2B`

2. **2.4GHz Requirement:** Most IP cameras only support 2.4GHz WiFi. If your router is 5GHz-only or uses the same SSID for both bands, try forcing 2.4GHz.

3. **Channel:** If you don't know your router's channel, use `channel=0` or omit it entirely.

4. **Factory Reset Between Tests:** Always factory reset between HTTP tests to ensure clean state.

---

## Confidence Levels

| Fix | Confidence | Rationale |
|-----|------------|-----------|
| Numeric authtype | 70% | Many cameras use enum values |
| `pass` instead of `wpa_psk` | 50% | Seen in multiple docs |
| Add login params | 30% | Usually only needed for HTTP, not P2P |
| Command listener timing | 40% | Could cause intermittent issues |
| URL encoding | 20% | Only if using special characters |

---

## Success Criteria

- [ ] Camera LED becomes solid blue after configuration
- [ ] Camera appears on router's device list
- [ ] Can access camera via new IP address (e.g., `http://192.168.32.x/get_status.cgi`)
