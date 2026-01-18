# Master Troubleshooting Guide: Veepa Camera Connection & Video Streaming

**Document Version**: 6.0 - Milestone Achieved
**Date**: January 18, 2026
**Status**: Direct WiFi Connection WORKING - Router Connection Next

---

## Current Status

### MILESTONE ACHIEVED: Direct WiFi Connection Works!

| Feature | Status | Notes |
|---------|--------|-------|
| App Restart | **WORKING** | Fixed by using Release Flutter frameworks |
| Direct WiFi Connection (AP Mode) | **WORKING** | Phone connects to camera's hotspot |
| P2P Connection | **WORKING** | Uses password `888888` |
| Video Streaming | **WORKING** | Live video displays correctly |
| Router WiFi Connection (STA Mode) | **NOT TESTED** | Next goal |

---

## What We Solved

### Issue 1: Wrong Password (SOLVED)
- **Problem**: Using `admin` as password
- **Solution**: Changed to `888888` (factory default)
- **File Changed**: `p2p_test_screen.dart`

### Issue 2: App Crash on Restart (SOLVED)
- **Problem**: Debug Flutter frameworks required debugger connection
- **Solution**: Switched to Release Flutter frameworks in `project.yml`
- **Root Cause**: Debug frameworks crash when launched without Xcode attached

### Issue 3: Singleton State on Restart (SOLVED)
- **Problem**: `AppP2PApi` singleton retained stale EventChannel state
- **Solution**: Added `resetInstance()` method, called on app startup
- **Files Changed**: `app_p2p_api.dart`, `main.dart`

---

## Next Goal: Router WiFi Connection

### Current Setup (Working)
```
Phone ──WiFi──> Camera Hotspot (@MC-0379196)
                     │
                  Camera
```
- Phone connects directly to camera's WiFi hotspot
- IP: 192.168.168.1
- This is "AP Mode" (Access Point Mode)

### Target Setup (To Implement)
```
Phone ──WiFi──> Home Router <──WiFi── Camera
                     │
                 Internet
```
- Both phone AND camera connect to the same WiFi router
- Camera needs to be configured for "STA Mode" (Station Mode)
- This enables remote access and is more practical for real use

### How to Configure Camera for Router WiFi

#### Option 1: Via Eye4 App
1. Open Eye4 app
2. Add camera (if not added)
3. Go to camera settings → WiFi settings
4. Select your home WiFi and enter password
5. Camera will restart and connect to router

#### Option 2: Via CGI Command (While in AP Mode)
```
http://192.168.168.1:81/set_wifi.cgi?loginuse=admin&loginpas=888888&ssid=YOUR_WIFI_NAME&pass=YOUR_WIFI_PASSWORD&authtype=2&enctype=4
```

#### Option 3: Via Our App (To Implement)
- Add WiFi configuration screen
- Send `set_wifi.cgi` command
- Handle camera restart and reconnection

### Testing Router Connection

Once camera is on router WiFi:
1. Find camera's new IP address (from router admin or `get_status.cgi`)
2. Update device ID or use cloud connection
3. Test P2P connection with `connectType=126` (cloud assist mode)

---

## Quick Reference

### Credentials
| Field | Value |
|-------|-------|
| Username | `admin` |
| Password | `888888` |

### Connection Modes
| Mode | connectType | Use Case |
|------|-------------|----------|
| LAN/AP (Direct WiFi) | 63 | Phone on camera hotspot |
| Cloud Assist | 126 | Both on router, may need cloud |
| Relay | 123 | Fallback mode |

### Device IDs
| Type | Prefix | Example |
|------|--------|---------|
| Virtual ID | OKB | OKB0379196OXYB |
| Real ID | VSTH | VSTH285556GJXNB |

---

## Archived Documentation

The following troubleshooting docs have been archived (issues solved):
- `archive/troubleshooting_solved/DEEP_DIVE_TROUBLESHOOTING.md`
- `archive/troubleshooting_solved/VIDEO_STREAMING_TROUBLESHOOTING.md`
- `archive/troubleshooting_solved/VIDEO_STREAMING_ANALYSIS_V2.md`
- `archive/troubleshooting_solved/CAMERA_CONNECTION_ANALYSIS.md`
- `archive/troubleshooting_solved/SDK_DEEP_ANALYSIS_v2.md`
- `archive/troubleshooting_solved/STREAMING_TROUBLESHOOT_TRAVEL_SHOOT.md`

---

## Files Modified for Solutions

| File | Change |
|------|--------|
| `flutter_veepa_module/lib/screens/p2p_test_screen.dart` | Password changed to `888888` |
| `flutter_veepa_module/lib/sdk/app_p2p_api.dart` | Added `resetInstance()` method |
| `flutter_veepa_module/lib/main.dart` | Call `resetInstance()` on startup |
| `ios_host_app/project.yml` | Changed to Release Flutter frameworks |
| `ios_host_app/VeepaPOC/Services/FlutterEngineManager.swift` | Added debug logging |
| `ios_host_app/VeepaPOC/App/AppDelegate.swift` | Added lifecycle logging |

---

*Document updated January 18, 2026 - Direct WiFi streaming milestone achieved*
