# Epic: Router WiFi Connection (STA Mode)

**Epic ID**: EPIC-ROUTER-WIFI
**Created**: January 18, 2026
**Status**: Planning
**Priority**: High

---

## Executive Summary

Enable the Veepa camera to connect via a home/office WiFi router instead of requiring the phone to connect to the camera's direct hotspot. This is essential for practical, real-world use of the camera.

---

## Current State vs Target State

### Current State (AP Mode - Working)
```
Phone ──WiFi──> Camera Hotspot (@MC-0379196)
                     │
                  Camera (192.168.168.1)
```
- Phone must disconnect from home WiFi
- No internet access while connected to camera
- Impractical for regular use

### Target State (STA Mode - To Implement)
```
Phone ──WiFi──> Home Router <──WiFi── Camera
                     │
                 Internet
```
- Both devices on same network
- Phone keeps internet access
- Camera accessible remotely (via cloud/P2P)
- Practical for daily use

---

## Technical Background

### Connection Modes (connectType)
| Mode | Value | Use Case |
|------|-------|----------|
| P2P Direct | 126 | Router/LAN connection (target) |
| Relay | 123 | Fallback when P2P fails |
| AP Mode | 63 | Current direct hotspot mode |

### Key CGI Commands
| Command | Purpose |
|---------|---------|
| `wifi_scan.cgi?` | Scan for available WiFi networks |
| `get_wifi_scan_result.cgi?` | Get scan results (SSID, channel, security) |
| `set_wifi.cgi?ssid=X&channel=Y&authtype=Z&wpa_psk=W&enable=1` | Connect to WiFi |
| `get_status.cgi?` | Verify connection status |

### Connection Flow
1. Connect to camera in AP mode (current working state)
2. Scan available WiFi networks
3. User selects home WiFi and enters password
4. Send `set_wifi.cgi` to configure camera
5. Camera reboots and connects to router
6. Reconnect using P2P mode with LAN scan

---

## Stories

### Story 1: WiFi Network Scanner

**ID**: ROUTER-WIFI-001
**Points**: 3
**Priority**: P0 (Critical)

**As a** user,
**I want** to see available WiFi networks from the camera,
**So that** I can select my home network.

**Acceptance Criteria**:
1. Button to initiate WiFi scan from P2P test screen
2. Display list of available networks (SSID, signal strength, security type)
3. Handle scan timeout (5 seconds max)
4. Show loading indicator during scan
5. Handle "no networks found" case

**Technical Notes**:
```dart
// Scan command
await device.writeCgi('wifi_scan.cgi?');
await Future.delayed(Duration(seconds: 3));
await device.writeCgi('get_wifi_scan_result.cgi?');
// Parse response for SSID, channel, authtype, signal
```

**Tests**:
- [ ] Unit test: Parse WiFi scan response
- [ ] Manual test: Scan shows real networks

---

### Story 2: WiFi Configuration UI

**ID**: ROUTER-WIFI-002
**Points**: 5
**Priority**: P0 (Critical)

**As a** user,
**I want** to select a WiFi network and enter my password,
**So that** I can configure the camera to connect to my router.

**Acceptance Criteria**:
1. Tappable list of scanned networks
2. Password entry dialog when network selected
3. Show security type (WPA2, WPA, Open)
4. "Connect" button to apply configuration
5. Confirmation dialog before sending (camera will reboot)
6. Input validation (password length for WPA2: 8+ chars)

**UI Mockup**:
```
┌─────────────────────────────────────┐
│  Select WiFi Network                │
├─────────────────────────────────────┤
│  📶 HomeNetwork_5G        WPA2  ▸   │
│  📶 HomeNetwork           WPA2  ▸   │
│  📶 Neighbor_Guest        Open  ▸   │
│  📶 Office_WiFi           WPA2  ▸   │
├─────────────────────────────────────┤
│  [Refresh]                          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Connect to "HomeNetwork"           │
├─────────────────────────────────────┤
│  Security: WPA2                     │
│                                     │
│  Password: [••••••••••]             │
│                                     │
│  ⚠️ Camera will reboot after       │
│     connecting to this network      │
│                                     │
│  [Cancel]            [Connect]      │
└─────────────────────────────────────┘
```

**Tests**:
- [ ] Unit test: Password validation
- [ ] Manual test: UI flow works end-to-end

---

### Story 3: Send WiFi Configuration Command

**ID**: ROUTER-WIFI-003
**Points**: 3
**Priority**: P0 (Critical)

**As a** developer,
**I want** to send the WiFi configuration CGI command,
**So that** the camera connects to the selected network.

**Acceptance Criteria**:
1. Build correct `set_wifi.cgi` command with URL encoding
2. Send command to camera
3. Handle success/failure response
4. Show "Camera is rebooting..." message
5. Disconnect from camera AP gracefully

**Technical Notes**:
```dart
String wifiCommand = 'set_wifi.cgi?'
    'ssid=${Uri.encodeQueryComponent(ssid)}&'
    'channel=$channel&'
    'authtype=$authType&'
    'wpa_psk=${Uri.encodeQueryComponent(password)}&'
    'enable=1&';

bool success = await device.writeCgi(wifiCommand);
if (success) {
  // Show reboot message, camera will disconnect
}
```

**Tests**:
- [ ] Unit test: CGI command URL encoding
- [ ] Manual test: Camera receives and applies config

---

### Story 4: Reconnect via LAN (P2P Mode)

**ID**: ROUTER-WIFI-004
**Points**: 5
**Priority**: P0 (Critical)

**As a** user,
**I want** to reconnect to the camera after it joins my router,
**So that** I can use it on my home network.

**Acceptance Criteria**:
1. Prompt user to connect phone to same WiFi as camera
2. "Reconnect" button with LAN scan enabled
3. Use `connectType: 126` (P2P Direct mode)
4. Handle connection timeout (camera may still be rebooting)
5. Retry logic (3 attempts with increasing delay)
6. Success message when connected

**Technical Notes**:
```dart
CameraDevice device = CameraDevice(
  deviceId, name, 'admin', '888888', model,
  connectType: 126  // P2P Direct mode
);

var state = await device.connect(
  lanScan: true,      // Scan local network
  connectCount: 3     // Retry attempts
);
```

**Tests**:
- [ ] Unit test: Connection retry logic
- [ ] Manual test: Reconnect after WiFi switch

---

### Story 5: WiFi Setup Flow Screen

**ID**: ROUTER-WIFI-005
**Points**: 5
**Priority**: P1 (High)

**As a** user,
**I want** a guided setup flow for WiFi configuration,
**So that** I can easily set up router connection.

**Acceptance Criteria**:
1. Step-by-step wizard UI
2. Step 1: "Connect to camera WiFi" (with camera hotspot name)
3. Step 2: "Scan for networks" (shows available WiFi)
4. Step 3: "Enter password" (for selected network)
5. Step 4: "Connecting..." (camera reboots)
6. Step 5: "Connect to your WiFi" (prompt user to switch)
7. Step 6: "Reconnect to camera" (LAN mode)
8. Progress indicator showing current step

**UI Flow**:
```
[Step 1: Connect to Camera] → [Step 2: Scan Networks] →
[Step 3: Enter Password] → [Step 4: Camera Rebooting] →
[Step 5: Switch WiFi] → [Step 6: Reconnect] → [Done!]
```

**Tests**:
- [ ] Manual test: Complete flow end-to-end

---

### Story 6: Connection Mode Indicator

**ID**: ROUTER-WIFI-006
**Points**: 2
**Priority**: P2 (Medium)

**As a** user,
**I want** to see which connection mode I'm using,
**So that** I know if I'm on direct WiFi or router.

**Acceptance Criteria**:
1. Display current connection mode on P2P test screen
2. Icons: 📡 AP Mode, 🏠 LAN Mode, ☁️ Cloud Relay
3. Show camera's IP address when connected
4. Update when connection mode changes

**Tests**:
- [ ] Manual test: Mode indicator accurate

---

### Story 7: Persist WiFi Configuration

**ID**: ROUTER-WIFI-007
**Points**: 3
**Priority**: P2 (Medium)

**As a** user,
**I want** the app to remember that my camera is on router WiFi,
**So that** it connects correctly next time.

**Acceptance Criteria**:
1. Save connection mode preference per device
2. Auto-select P2P mode (126) for devices configured for router
3. Store in local device storage
4. Option to "Forget" and reconfigure

**Tests**:
- [ ] Unit test: Persistence logic
- [ ] Manual test: Mode persists across app restart

---

### Story 8: Error Handling & Recovery

**ID**: ROUTER-WIFI-008
**Points**: 3
**Priority**: P1 (High)

**As a** user,
**I want** clear error messages and recovery options,
**So that** I can fix problems during setup.

**Acceptance Criteria**:
1. "Wrong password" → Retry with different password
2. "Camera not found" → Instructions to verify same network
3. "Connection timeout" → Retry button with longer timeout
4. "WiFi scan failed" → Retry scan button
5. "Fallback to AP mode" → Instructions to reconnect to camera hotspot
6. Log errors for debugging

**Error Messages**:
| Error | Message | Action |
|-------|---------|--------|
| Wrong WiFi password | "Camera couldn't connect. Check password." | Retry |
| Camera not found | "Camera not found on network. Ensure phone and camera are on same WiFi." | Retry/AP Mode |
| Timeout | "Connection timed out. Camera may still be rebooting." | Wait & Retry |

**Tests**:
- [ ] Manual test: Each error scenario handled

---

## Implementation Plan

### Phase 1: Core Functionality (Stories 1-4)
**Goal**: Basic WiFi configuration working end-to-end
**Estimated**: 2-3 days

1. Implement WiFi scanner (Story 1)
2. Build configuration UI (Story 2)
3. Send CGI command (Story 3)
4. Reconnect via LAN (Story 4)

### Phase 2: Polish & UX (Stories 5-6)
**Goal**: Smooth user experience
**Estimated**: 1-2 days

1. Guided setup wizard (Story 5)
2. Connection mode indicator (Story 6)

### Phase 3: Robustness (Stories 7-8)
**Goal**: Handle edge cases and errors
**Estimated**: 1 day

1. Persist configuration (Story 7)
2. Error handling (Story 8)

---

## Dependencies

- ✅ Direct WiFi connection working (completed)
- ✅ Password `888888` confirmed working
- ✅ App restart issue fixed
- Camera must support WiFi configuration (WiFi type 21-24)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Camera firmware doesn't support `set_wifi.cgi` | High | Test with actual camera first |
| Router blocks P2P/UDP | Medium | Fall back to relay mode (123) |
| User enters wrong WiFi password | Low | Clear error message, retry option |
| Camera reboots take too long | Low | Increase timeout, show progress |

---

## Success Criteria

1. ✅ Camera connects to home WiFi router
2. ✅ Video streaming works over router connection
3. ✅ Connection is stable and reconnects automatically
4. ✅ User can complete setup without technical knowledge

---

## References

- CGI Command Manual: `docs/official_documentation/CGI_COMMAND_MANUAL.md`
- Cloud Info: `docs/official_documentation/cloud_info.md`
- SDK Source: `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/`

---

*Epic created January 18, 2026*
