# Epic: Router WiFi Connection (STA Mode)

**Epic ID**: EPIC-ROUTER-WIFI
**Created**: January 18, 2026
**Status**: Planning
**Priority**: High

---

## Executive Summary

Enable the Veepa camera to connect via a home/office WiFi router instead of requiring the phone to connect to the camera's direct hotspot. This is essential for practical, real-world use of the camera.

---

## Engineering Decisions (From Feedback Review)

### Confirmed Settings
| Setting | Value | Source |
|---------|-------|--------|
| Default Password | `888888` | Official SDK docs, confirmed working |
| Username | `admin` | Fixed, cannot be changed |
| connectType for Router | `126` | Required for virtual IDs (OKB-style) |
| connectType for AP Mode | `63` | Direct hotspot connection |

### Critical Implementation Requirements

1. **Login Verification Gate**
   - Login `clientLogin()` return value only means request sent, NOT accepted
   - Must wait for `cmd 24577` with `result=0` before running WiFi CGI commands
   - Command listener must be attached BEFORE calling login

2. **Virtual ID Handling**
   - OKB-style IDs are virtual and require cloud resolution
   - Must resolve to real clientId (VSTH-style) for reliable connections
   - Use `connectType=126` for router connections with virtual IDs

3. **Credential Extraction**
   - `realdeviceid` can be extracted from camera via `get_status.cgi`
   - `serviceParam` from SDK built-in table (VSTH included) or cloud if prefix missing
   - Credentials stable until factory reset or vendor re-provisioning

### WiFi CGI Commands (Best-Effort - Validate Live!)

⚠️ **These commands are NOT in official translated docs.** Parameters are derived from SDK demo code and must be validated via live command responses. Actual parameters may vary by firmware version.

- `wifi_scan.cgi?` - Trigger network scan
- `get_wifi_scan_result.cgi?` - Get scan results
- `set_wifi.cgi?ssid=X&channel=Y&authtype=Z&wpa_psk=W&enable=1&` - Configure WiFi

**Always validate responses live** - treat these as experimental until confirmed working.

### Credential Caching Strategy

**The Two IDs Explained:**
| ID Type | Example | What It Is |
|---------|---------|------------|
| Virtual ID (VUID) | `OKB0379196OXYB` | Printed on camera, used for QR codes |
| Real Device ID | `VSTH285556GJXNB` | Actual SDK identifier |

**How to Get Credentials (One-Time per Camera):**
1. Connect phone to camera's WiFi hotspot
2. Login with password `888888`
3. Send `get_status.cgi` → extracts `realdeviceid`
4. Fetch `serviceParam` from cloud (internet required once)
5. Cache both permanently

**Exporting/Storing Credentials:**
Credentials can be exported and stored externally (your own cloud, database, etc.):
```json
{
  "virtualId": "OKB0379196OXYB",
  "realDeviceId": "VSTH285556GJXNB",
  "serviceParam": "EBGBEMBMKGJM...",
  "password": "888888"
}
```

These credentials:
- **IDs and serviceParam are hardware-based** and don't change under normal use
- **Password defaults to `888888`** - can be changed after connecting (factory reset restores default)
- Can be imported on any device/installation
- Don't require re-fetching from cloud once cached
- **Stable until factory reset or re-provisioning** by vendor

---

## Technical Logic Deep-Dive (For Review)

This section explains the complete connection logic for review by other engineers/AIs.

### The Identity Resolution Problem

The Veepa SDK has a two-tier identity system:

```
┌─────────────────────────────────────────────────────────────────┐
│  VIRTUAL ID (what you see)          REAL ID (what SDK needs)   │
│  ─────────────────────────          ────────────────────────   │
│  OKB0379196OXYB          →→→        VSTH285556GJXNB            │
│                                                                 │
│  • Printed on camera                • Hardware identifier       │
│  • Used in QR codes                 • Required for P2P connect  │
│  • Human-readable                   • Never changes             │
└─────────────────────────────────────────────────────────────────┘
```

**Why two IDs?**
- Virtual IDs (OKB) are for user convenience and can map to different physical devices
- Real IDs (VSTH) are burned into hardware and used for actual connections

### How to Resolve Virtual → Real ID

**Method 1: Cloud Lookup (requires internet)**
```
Phone → https://vuid.eye4.cn → POST {vuid: "OKB0379196OXYB"} → Returns "VSTH285556GJXNB"
```

**Method 2: Direct from Camera (no internet needed)**
```
Phone → Camera WiFi Hotspot → get_status.cgi → Response contains "realdeviceid=VSTH285556GJXNB"
```

### The serviceParam Requirement

The SDK needs a `serviceParam` (also called "initstring") for P2P routing. This contains encoded server addresses.

**How it's obtained:**
1. SDK has built-in lookup table for common prefixes (VSTC, VSTA, VSTB, VSTH, etc.)
2. For prefixes NOT in table, must fetch from cloud:
   ```
   POST https://authentication.eye4.cn/getInitstring
   Body: {"uid": ["XXXX"]}  // 4-char prefix
   Returns: "EBGBEMBMKGJMGAJP..."
   ```

**Key insight:** serviceParam is based on the 4-character PREFIX, not the full ID. All cameras with same prefix share the same serviceParam. VSTH is in the SDK's built-in table.

### Connection Types Explained

| connectType | Name | When to Use | How It Works |
|-------------|------|-------------|--------------|
| 63 | LAN/AP Mode | Phone on camera hotspot | Direct local connection, no cloud |
| 126 | P2P Direct | Same network via router | Uses P2P servers to establish connection |
| 123 | Relay Mode | Fallback | All traffic routed through cloud servers |

**Critical:** Virtual IDs (OKB) require `connectType=126` even on local network because the SDK needs cloud to resolve the ID.

### Login Verification Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. Attach command listener (BEFORE login)                      │
│     AppP2PApi().setCommandListener(clientPtr, onCommand);       │
│                                                                 │
│  2. Send login request                                          │
│     AppP2PApi().clientLogin(clientPtr, 'admin', '888888');      │
│     // Returns true = request SENT (not accepted!)              │
│                                                                 │
│  3. Wait for cmd 24577 response                                 │
│     onCommand(24577, data) → parse for "result=0"               │
│                                                                 │
│  4. Verify result                                               │
│     result=0  → Login successful, proceed with CGI commands     │
│     result=-1 → Wrong password                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Complete WiFi Setup Sequence

```
PHASE 1: INITIAL SETUP (One-time, requires camera hotspot)
═══════════════════════════════════════════════════════════

   Step 1: Connect phone to camera hotspot (@MC-0379196)
           └─ Phone WiFi Settings → Select camera network

   Step 2: Create P2P client
           └─ clientPtr = AppP2PApi().clientCreate(virtualId)

   Step 3: Connect in AP mode
           └─ AppP2PApi().clientConnect(clientPtr, true, "", connectType: 63)

   Step 4: Attach command listener
           └─ AppP2PApi().setCommandListener(clientPtr, onCommand)

   Step 5: Login and verify
           └─ AppP2PApi().clientLogin(clientPtr, 'admin', '888888')
           └─ Wait for cmd 24577, verify result=0

   Step 6: Extract real device ID
           └─ AppP2PApi().clientWriteCgi(clientPtr, 'get_status.cgi?')
           └─ Parse response for "realdeviceid=VSTH..."

   Step 7: Get serviceParam
           └─ Check SDK built-in table first (VSTH is included)
           └─ If prefix missing from table: requires internet (cellular data)
           └─ ⚠️ Phone on camera hotspot has NO internet - use cellular or pre-cache
           └─ Or use cached value if available

   Step 8: Cache credentials permanently
           └─ Store: {virtualId, realDeviceId, serviceParam, password}


PHASE 2: WIFI CONFIGURATION (Tells camera to join router)
═══════════════════════════════════════════════════════════

   Step 9: Scan for networks
           └─ AppP2PApi().clientWriteCgi(clientPtr, 'wifi_scan.cgi?')
           └─ Wait 3 seconds
           └─ AppP2PApi().clientWriteCgi(clientPtr, 'get_wifi_scan_result.cgi?')

   Step 10: User selects network and enters password

   Step 11: Send WiFi configuration
           └─ AppP2PApi().clientWriteCgi(clientPtr,
              'set_wifi.cgi?ssid=X&channel=Y&authtype=Z&wpa_psk=W&enable=1&')

   Step 12: Camera reboots (connection lost - this is expected)
           └─ Wait 30-60 seconds for camera to join router


PHASE 3: ROUTER CONNECTION (Daily use after setup)
═══════════════════════════════════════════════════════════

   Step 13: Connect phone to home WiFi (same as camera)

   Step 14: Create P2P client with REAL device ID
           └─ clientPtr = AppP2PApi().clientCreate(realDeviceId)  // VSTH, not OKB!

   Step 15: Connect in P2P mode
           └─ AppP2PApi().clientConnect(clientPtr, true, serviceParam,
              connectType: 126)  // Must be 126 for router mode

   Step 16: Login and verify
           └─ Same as Step 5

   Step 17: Start video stream
           └─ Camera working on home network!
```

### Credential Persistence Summary

| Data | Stable? | Source | Cache Strategy |
|------|---------|--------|----------------|
| Virtual ID | ✅ Yes | Printed on camera | Store once |
| Real Device ID | ✅ Yes | `get_status.cgi` → `realdeviceid` | Store once |
| serviceParam | ✅ Yes | SDK built-in table or cloud API | Store once |
| Password | ⚠️ Can change | Default `888888`, user can modify | Store, handle fallback |

**Conclusion:** Cached credentials are stable until factory reset or vendor re-provisioning. For password, try cached value first, fall back to default `888888`.

---

## The Simple Flow (How It Works)

### Overview
```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: Connect to Camera Hotspot (like now)                   │
│  ────────────────────────────────────────────────────────────── │
│  Phone Settings → WiFi → Connect to "@MC-0379196"               │
│  (This is what you already do today)                            │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: Tell Camera Your Home WiFi                             │
│  ────────────────────────────────────────────────────────────── │
│  In App: "WiFi Setup" → Scan Networks → Select "YourHomeWiFi"   │
│  Enter password → Camera reboots                                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: Connect Phone to Home WiFi                             │
│  ────────────────────────────────────────────────────────────── │
│  Phone Settings → WiFi → Connect to "YourHomeWiFi"              │
│  (Same network the camera just joined)                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: Reconnect to Camera (Now on Same Network!)             │
│  ────────────────────────────────────────────────────────────── │
│  In App: "Connect via Router" → Camera found → Video works!     │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Order?
1. **You must talk to the camera first** - The only way to configure WiFi is by connecting to it
2. **Camera needs your WiFi credentials** - It can't guess your home WiFi password
3. **Camera reboots to apply changes** - This is normal, takes ~30 seconds
4. **Then both are on same network** - Now they can find each other!

---

## UI Design: New "WiFi Setup" Button

### Home Screen Layout
```
┌─────────────────────────────────────────┐
│           Veepa Camera POC              │
│                  📷                      │
│         SDK Status: Ready               │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  🔧  WiFi Setup                 │    │  ← NEW BUTTON
│  │  Configure camera for router    │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  🏠  Connect via Router         │    │  ← NEW BUTTON
│  │  For cameras on your WiFi       │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  📡  Direct Connection (AP)     │    │  ← EXISTING (renamed)
│  │  Connect to camera hotspot      │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

### Button Purposes
| Button | When to Use | Prerequisite |
|--------|-------------|--------------|
| **WiFi Setup** | First time setup, or reconfiguring | Phone connected to camera hotspot |
| **Connect via Router** | Daily use after setup | Phone on same WiFi as camera |
| **Direct Connection** | Debugging, or if router fails | Phone connected to camera hotspot |

---

## Stories with Manual Tests

### Story 1: WiFi Network Scanner

**ID**: ROUTER-WIFI-001
**Points**: 3
**Priority**: P0 (Critical)

**As a** user,
**I want** to see available WiFi networks from the camera,
**So that** I can select my home network.

**Acceptance Criteria**:
1. "Scan Networks" button on WiFi Setup screen
2. Display list of available networks (SSID, signal strength, security type)
3. Handle scan timeout (5 seconds max)
4. Show loading indicator during scan
5. Handle "no networks found" case

**Technical Implementation**:
```dart
// IMPORTANT: Set command listener BEFORE login
AppP2PApi().setCommandListener(clientPtr, onCommand);

// Login and wait for cmd 24577 result=0 confirmation
bool loginSent = await AppP2PApi().clientLogin(clientPtr, 'admin', '888888');
// Wait for cmd 24577 response with result=0 before proceeding

// After login confirmed:
// 1. Send scan command
await AppP2PApi().clientWriteCgi(clientPtr, 'wifi_scan.cgi?');

// 2. Wait for camera to scan
await Future.delayed(Duration(seconds: 3));

// 3. Get results
await AppP2PApi().clientWriteCgi(clientPtr, 'get_wifi_scan_result.cgi?');

// 4. Parse response (comes via command listener)
// Expected format: ap_ssid[0]="NetworkName"; ap_signal[0]=80; ap_security[0]="WPA2";
```

**Login Verification**:
- cmd 24577 with `result=0` = Login successful
- cmd 24577 with `result=-1` = Wrong password
- Must verify before proceeding with WiFi scan

---

#### **MANUAL TEST: WiFi Scanner**

**Prerequisites**:
- [ ] Phone connected to camera's WiFi hotspot (@MC-0379196)
- [ ] App open on WiFi Setup screen

**Test Steps**:
| Step | Action | Expected Result | ✓/✗ |
|------|--------|-----------------|-----|
| 1 | Tap "Scan Networks" | Loading spinner appears | |
| 2 | Wait 3-5 seconds | List of WiFi networks appears | |
| 3 | Verify your home WiFi is in list | Your network name visible | |
| 4 | Check signal strength shown | Bars or percentage displayed | |
| 5 | Check security type shown | "WPA2" or "Open" displayed | |
| 6 | Tap "Scan Networks" again | List refreshes | |

**Edge Case Tests**:
| Test | Action | Expected Result | ✓/✗ |
|------|--------|-----------------|-----|
| No networks | Scan in isolated area | "No networks found" message | |
| Timeout | Disconnect camera mid-scan | Timeout error, retry button | |
| Many networks | Scan in busy area | Scrollable list works | |

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

---

#### **MANUAL TEST: WiFi Configuration UI**

**Prerequisites**:
- [ ] WiFi scan completed (Story 1 working)
- [ ] Your home WiFi visible in list

**Test Steps**:
| Step | Action | Expected Result | ✓/✗ |
|------|--------|-----------------|-----|
| 1 | Tap your home WiFi name | Password dialog appears | |
| 2 | Check network name shown | Correct name displayed | |
| 3 | Check security type shown | "WPA2" or correct type | |
| 4 | Enter short password (3 chars) | Error: "Password too short" | |
| 5 | Enter correct password | "Connect" button enabled | |
| 6 | Tap "Connect" | Confirmation dialog appears | |
| 7 | Confirm message text | "Camera will reboot..." shown | |
| 8 | Tap "Cancel" | Dialog closes, no action | |

**Edge Case Tests**:
| Test | Action | Expected Result | ✓/✗ |
|------|--------|-----------------|-----|
| Open network | Tap network with no security | No password needed, connect directly | |
| Special chars | Password with $#@! | Characters accepted | |
| Very long password | 63 character password | Accepted (WPA2 max) | |

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

**Technical Implementation**:
```dart
String buildWifiCommand(String ssid, String password, String channel, String authType) {
  return 'set_wifi.cgi?'
      'ssid=${Uri.encodeQueryComponent(ssid)}&'
      'channel=$channel&'
      'authtype=$authType&'
      'wpa_psk=${Uri.encodeQueryComponent(password)}&'
      'enable=1&';
}

// Example: set_wifi.cgi?ssid=MyNetwork&channel=6&authtype=WPA2&wpa_psk=password123&enable=1&
```

---

#### **MANUAL TEST: Send WiFi Configuration**

**Prerequisites**:
- [ ] Stories 1 & 2 working
- [ ] Know your home WiFi password

**Test Steps**:
| Step | Action | Expected Result | ✓/✗ |
|------|--------|-----------------|-----|
| 1 | Select your home WiFi | Password dialog shown | |
| 2 | Enter correct password | "Connect" enabled | |
| 3 | Tap "Connect" | Confirmation dialog | |
| 4 | Tap "Yes, Connect" | "Sending configuration..." | |
| 5 | Wait 2-3 seconds | "Camera is rebooting..." | |
| 6 | Camera status | Connection lost (expected!) | |
| 7 | Camera LED | Blinks, then changes color | |
| 8 | Wait 30-60 seconds | Camera LED solid (connected) | |

**Verify Camera Connected to Router**:
| Check | How | Expected | ✓/✗ |
|-------|-----|----------|-----|
| Router admin | Check connected devices | Camera appears | |
| Camera LED | Visual check | Solid (not blinking) | |

---

### Story 4: Reconnect via LAN (P2P Mode)

**ID**: ROUTER-WIFI-004
**Points**: 5
**Priority**: P0 (Critical)

**As a** user,
**I want** to reconnect to the camera after it joins my router,
**So that** I can use it on my home network.

**Acceptance Criteria**:
1. "Connect via Router" button on home screen
2. Uses `connectType: 126` (P2P Direct mode)
3. Enables `lanScan: true` to find camera on network
4. Handle connection timeout (camera may still be rebooting)
5. Retry logic (3 attempts with increasing delay)
6. Success message when connected
7. Video streaming works

**Technical Implementation**:
```dart
// CRITICAL: Use real clientId (VSTH) not virtual ID (OKB) for router connections
// Real ID can be extracted via get_status.cgi during WiFi setup

// Key differences from AP mode:
// 1. connectType: 126 (not 63) - required for virtual IDs
// 2. lanScan: true - scan local network for camera
// 3. serviceParam - needed for P2P routing

final connectState = await AppP2PApi().clientConnect(
  clientPtr,
  true,              // lanScan = true (scan local network)
  serviceParam,      // Required - fetch from cloud if not cached
  connectType: 126,  // P2P Direct mode (not 63 for AP)
  p2pType: 0
);

// Note: If using virtual ID (OKB), connection may fail even on same LAN
// The SDK needs cloud to resolve virtual → real ID mapping
```

**Credential Requirements for Router Mode**:
| Credential | Source | Cache? |
|------------|--------|--------|
| Real clientId | `get_status.cgi` → `realdeviceid` | Yes, permanent |
| serviceParam | Cloud API (for VSTH devices) | Yes, permanent |

---

#### **MANUAL TEST: Connect via Router**

**Prerequisites**:
- [ ] Camera configured for your home WiFi (Story 3 done)
- [ ] Phone connected to same home WiFi (NOT camera hotspot!)
- [ ] Camera LED shows connected state

**Test Steps**:
| Step | Action | Expected Result | ✓/✗ |
|------|--------|-----------------|-----|
| 1 | Verify phone WiFi | Connected to home network | |
| 2 | Open app | Home screen shown | |
| 3 | Tap "Connect via Router" | Connection screen | |
| 4 | Enter Device ID | Same ID as before | |
| 5 | Enter password (888888) | Password field filled | |
| 6 | Tap "Connect" | "Connecting..." shown | |
| 7 | Wait up to 30 seconds | "Connected" or timeout | |
| 8 | If connected, start video | Video stream works | |

**Troubleshooting Tests**:
| Issue | Check | Solution | ✓/✗ |
|-------|-------|----------|-----|
| "Camera not found" | Phone on same WiFi? | Switch to home WiFi | |
| "Camera not found" | Camera LED solid? | Wait for camera to boot | |
| "Connection timeout" | Wait longer | Retry after 30 seconds | |
| "Wrong password" | Using 888888? | Reset camera if needed | |

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
2. Clear instructions at each step
3. Progress indicator
4. Can go back to previous steps
5. Handles all edge cases gracefully

**Flow Steps**:
```
STEP 1: "Connect to Camera"
────────────────────────────
"First, connect your phone to the camera's WiFi hotspot"

📱 Go to Settings → WiFi
📡 Select: @MC-0379196
🔑 Password: (none needed)

[I'm Connected] [Help]


STEP 2: "Scan for Networks"
────────────────────────────
"Now let's find your home WiFi"

[Scanning... 🔄]

Found 5 networks:
• 📶 HomeNetwork_5G (WPA2)
• 📶 HomeNetwork (WPA2)
• 📶 Neighbor_WiFi (WPA2)

[Refresh]


STEP 3: "Enter Password"
────────────────────────────
Connecting to: HomeNetwork
Security: WPA2

Password: [••••••••••]
          [Show]

[Back] [Connect Camera]


STEP 4: "Camera Rebooting"
────────────────────────────
✅ Configuration sent!

The camera is now rebooting to connect
to your home WiFi. This takes about
30-60 seconds.

[Progress bar: ████████░░░░]

Camera LED should change from blinking
to solid when connected.


STEP 5: "Connect Your Phone"
────────────────────────────
Now connect your phone to the same WiFi:

📱 Go to Settings → WiFi
📡 Select: HomeNetwork

[I'm Connected]


STEP 6: "Reconnect to Camera"
────────────────────────────
Let's find your camera on the network!

Device ID: OKB0379196OXYB
Password: 888888

[Connect to Camera]

Attempt 1 of 3...


STEP 7: "Success!"
────────────────────────────
🎉 Camera connected via router!

You can now use your camera while
staying connected to the internet.

[Start Video] [Done]
```

---

#### **MANUAL TEST: Complete WiFi Setup Flow**

**Prerequisites**:
- [ ] Camera on and working
- [ ] Know your home WiFi name and password
- [ ] Fresh start (camera in AP mode)

**Test the Full Flow**:
| Step | Screen | Action | Expected | ✓/✗ |
|------|--------|--------|----------|-----|
| 1 | Home | Tap "WiFi Setup" | Step 1 appears | |
| 2 | Step 1 | Connect phone to camera WiFi | WiFi connected | |
| 3 | Step 1 | Tap "I'm Connected" | Step 2 appears | |
| 4 | Step 2 | Wait for scan | Networks listed | |
| 5 | Step 2 | Tap your home WiFi | Step 3 appears | |
| 6 | Step 3 | Enter password | Password shown | |
| 7 | Step 3 | Tap "Connect Camera" | Step 4 appears | |
| 8 | Step 4 | Wait 30-60 seconds | Progress completes | |
| 9 | Step 4 | Automatic or tap next | Step 5 appears | |
| 10 | Step 5 | Connect phone to home WiFi | WiFi switched | |
| 11 | Step 5 | Tap "I'm Connected" | Step 6 appears | |
| 12 | Step 6 | Tap "Connect to Camera" | Connecting... | |
| 13 | Step 6 | Wait for connection | Step 7 appears | |
| 14 | Step 7 | Tap "Start Video" | Video plays! | |

**Time to Complete**: Should be under 3 minutes total

---

### Story 6: Connection Mode Indicator

**ID**: ROUTER-WIFI-006
**Points**: 2
**Priority**: P2 (Medium)

**As a** user,
**I want** to see which connection mode I'm using,
**So that** I know if I'm on direct WiFi or router.

**Acceptance Criteria**:
1. Display current connection mode
2. Clear icons for each mode
3. Show when connected

**Indicators**:
```
📡 Direct (AP Mode) - Connected to camera hotspot
🏠 Router (LAN Mode) - Both on same WiFi network
☁️ Cloud (Relay Mode) - Connected via internet
```

---

#### **MANUAL TEST: Connection Mode Indicator**

| Test | Setup | Expected Indicator | ✓/✗ |
|------|-------|-------------------|-----|
| AP Mode | Phone on camera hotspot | 📡 Direct (AP Mode) | |
| Router Mode | Both on home WiFi | 🏠 Router (LAN Mode) | |
| Not connected | No connection | No indicator / "Disconnected" | |

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
2. Auto-select "Connect via Router" for configured devices
3. Option to "Reconfigure WiFi"

---

#### **MANUAL TEST: Persistence**

| Step | Action | Expected | ✓/✗ |
|------|--------|----------|-----|
| 1 | Complete WiFi setup | Device saved | |
| 2 | Close app completely | App closes | |
| 3 | Reopen app | Home screen | |
| 4 | Check saved devices | Your device listed | |
| 5 | Tap device | Auto-connects via router | |

---

### Story 8: Error Handling & Recovery

**ID**: ROUTER-WIFI-008
**Points**: 3
**Priority**: P1 (High)

**As a** user,
**I want** clear error messages and recovery options,
**So that** I can fix problems during setup.

**Error Scenarios**:
| Error | User Message | Recovery Action |
|-------|--------------|-----------------|
| Wrong WiFi password | "Camera couldn't connect to WiFi. Please check your password." | Re-enter password |
| Camera not found on network | "Camera not found. Make sure phone and camera are on the same WiFi." | Verify WiFi, retry |
| Connection timeout | "Connection timed out. Camera may still be starting up." | Wait and retry |
| Scan failed | "Couldn't scan for networks. Please try again." | Retry scan |

---

#### **MANUAL TEST: Error Handling**

| Test | How to Trigger | Expected Message | Recovery Works | ✓/✗ |
|------|----------------|------------------|----------------|-----|
| Wrong password | Enter wrong WiFi password | "Check your password" | Can retry | |
| Phone wrong network | Phone on different WiFi | "Same WiFi" message | Instructions shown | |
| Camera off | Turn off camera | "Camera not found" | Retry button | |
| Timeout | Very slow network | "Timed out" | Retry button | |

---

## Quick Start: Testing Today

Before implementing the full flow, you can test the core CGI commands manually:

### Test 1: WiFi Scan (via current P2P Test screen)

1. Connect phone to camera hotspot
2. Open P2P Test screen
3. Connect to camera (password: 888888)
4. In the CGI command field, type: `wifi_scan.cgi?`
5. Send command
6. Wait 3 seconds
7. Type: `get_wifi_scan_result.cgi?`
8. Send command
9. Check response for list of networks

### Test 2: Configure WiFi (CAREFUL - camera will reboot!)

1. After successful scan, note your home WiFi details:
   - SSID (network name)
   - Channel (from scan)
   - Security type (WPA2 usually)
2. Build command:
   ```
   set_wifi.cgi?ssid=YourNetwork&channel=6&authtype=WPA2&wpa_psk=YourPassword&enable=1&
   ```
3. Send command
4. Camera will reboot (connection lost)
5. Wait 60 seconds
6. Connect phone to home WiFi
7. Try connecting to camera again

---

## Implementation Priority

### Phase 1: Core (Must Have)
| Story | Description | Test Focus |
|-------|-------------|------------|
| 1 | WiFi Scanner | Can see networks |
| 2 | Configuration UI | Can enter password |
| 3 | Send Command | Camera reboots |
| 4 | Reconnect | Video works on router |

### Phase 2: UX (Should Have)
| Story | Description | Test Focus |
|-------|-------------|------------|
| 5 | Guided Wizard | Easy to follow |
| 6 | Mode Indicator | Know connection type |

### Phase 3: Polish (Nice to Have)
| Story | Description | Test Focus |
|-------|-------------|------------|
| 7 | Persistence | Remembers settings |
| 8 | Error Handling | Clear recovery |

---

## Success Criteria

- [ ] Can scan WiFi networks from camera
- [ ] Can configure camera to join home WiFi
- [ ] Can reconnect to camera via home WiFi
- [ ] Video streaming works on router connection
- [ ] Complete flow takes under 3 minutes
- [ ] Non-technical user can complete setup

---

*Epic created January 18, 2026 - Updated with detailed manual tests*
