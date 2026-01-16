# Offline P2P Credential Cache - Implementation Plan

**Date**: January 16, 2026
**Goal**: Enable offline P2P camera connection by caching cloud-derived credentials
**Approach**: Low-impact solution using the existing P2P test screen

---

## Executive Summary

The Veepa SDK requires two cloud-fetched parameters to establish a P2P connection:
1. **clientId** - Real device ID (resolved from virtual ID)
2. **serviceParam** - Bootstrap token for P2P handshake

This plan adds credential caching to the P2P test screen, allowing:
- One-time online credential fetch and cache
- Subsequent offline connections using cached credentials

---

## Technical Background

### Current Flow (Requires Internet)

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│   App       │     │  Veepa Cloud     │     │   Camera    │
└──────┬──────┘     └────────┬─────────┘     └──────┬──────┘
       │                     │                      │
       │ 1. GET vuid.eye4.cn │                      │
       │    ?vuid=OKB...     │                      │
       │────────────────────>│                      │
       │                     │                      │
       │ 2. Returns real     │                      │
       │    clientId         │                      │
       │<────────────────────│                      │
       │                     │                      │
       │ 3. POST             │                      │
       │    authentication.  │                      │
       │    eye4.cn          │                      │
       │────────────────────>│                      │
       │                     │                      │
       │ 4. Returns          │                      │
       │    serviceParam     │                      │
       │<────────────────────│                      │
       │                     │                      │
       │ 5. P2P Connect with │                      │
       │    clientId +       │                      │
       │    serviceParam     │                      │
       │─────────────────────────────────────────────>
```

### Proposed Flow (With Cache)

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│   App       │     │  Local Cache     │     │   Camera    │
└──────┬──────┘     └────────┬─────────┘     └──────┬──────┘
       │                     │                      │
       │ 1. Load cached      │                      │
       │    credentials      │                      │
       │────────────────────>│                      │
       │                     │                      │
       │ 2. Returns          │                      │
       │    clientId +       │                      │
       │    serviceParam     │                      │
       │<────────────────────│                      │
       │                     │                      │
       │ 3. P2P Connect      │                      │
       │    (direct LAN)     │                      │
       │─────────────────────────────────────────────>
```

---

## Data to Cache

### 1. Client ID Resolution

**API**: `GET https://vuid.eye4.cn?vuid=OKB0379853SNLJ`

**Expected Response** (JSON):
```json
{
  "uid": "ACTUAL_DEVICE_ID_HERE",
  "supplier": "...",
  "cluster": "..."
}
```

**What to cache**: The `uid` field (the real device ID)

### 2. Service Parameter

**API**: `POST https://authentication.eye4.cn/getInitstring`

**Request Body**:
```json
{
  "uid": ["OKB0"]  // First 4 chars of camera prefix
}
```

**Expected Response**: Array with the service parameter string

**What to cache**: The service parameter string (initstring)

---

## Implementation Stories

Each story is independent and can be implemented/tested separately.

---

### Story 1: Create P2P Credential Cache Service

**File**: `flutter_veepa_module/lib/services/p2p_credential_cache.dart`

**Purpose**: Manage local storage of P2P credentials

**Acceptance Criteria**:
- [ ] Create `P2PCredentialCache` class
- [ ] Implement `saveCredentials(cameraUid, clientId, serviceParam)`
- [ ] Implement `loadCredentials(cameraUid)` → returns cached data or null
- [ ] Implement `hasCredentials(cameraUid)` → returns bool
- [ ] Implement `clearCredentials(cameraUid)`
- [ ] Implement `getCacheTimestamp(cameraUid)` → when cached
- [ ] Use SharedPreferences for storage
- [ ] Add error handling for storage failures

**Data Model**:
```dart
class P2PCredentials {
  final String cameraUid;      // Original UID (e.g., OKB0379853SNLJ)
  final String clientId;       // Resolved real ID from cloud
  final String serviceParam;   // Bootstrap token from cloud
  final String? password;      // Camera password (optional, for convenience)
  final DateTime cachedAt;     // When cached
  final String? supplier;      // From cloud response (for debugging)
  final String? cluster;       // From cloud response (for debugging)

  // Validation
  bool get isValid =>
    cameraUid.isNotEmpty &&
    clientId.isNotEmpty &&
    serviceParam.isNotEmpty;

  // JSON serialization methods
  Map<String, dynamic> toJson() => {
    'cameraUid': cameraUid,
    'clientId': clientId,
    'serviceParam': serviceParam,
    'password': password,
    'cachedAt': cachedAt.toIso8601String(),
    'supplier': supplier,
    'cluster': cluster,
  };

  factory P2PCredentials.fromJson(Map<String, dynamic> json) => P2PCredentials(
    cameraUid: json['cameraUid'],
    clientId: json['clientId'],
    serviceParam: json['serviceParam'],
    password: json['password'],
    cachedAt: DateTime.parse(json['cachedAt']),
    supplier: json['supplier'],
    cluster: json['cluster'],
  );
}
```

**Validation Methods**:
```dart
// Validate before saving
String? validateCredentials(P2PCredentials creds) {
  if (creds.cameraUid.isEmpty) return 'Camera UID is empty';
  if (creds.clientId.isEmpty) return 'Client ID is empty';
  if (creds.clientId.length < 5) return 'Client ID too short';
  if (creds.serviceParam.isEmpty) return 'Service param is empty';
  if (creds.serviceParam.length < 20) return 'Service param too short';
  return null; // Valid
}
```

**Estimated Effort**: 30 minutes

---

### Story 2: Create Cloud Credential Fetcher

**File**: `flutter_veepa_module/lib/services/p2p_credential_fetcher.dart`

**Purpose**: Fetch credentials from Veepa cloud APIs

**Acceptance Criteria**:
- [ ] Create `P2PCredentialFetcher` class
- [ ] Implement `fetchClientId(virtualUid)` → calls vuid.eye4.cn
- [ ] Implement `fetchServiceParam(uidPrefix)` → calls authentication.eye4.cn
- [ ] Implement `fetchAllCredentials(cameraUid)` → fetches both, returns P2PCredentials
- [ ] Add timeout handling (5 second timeout)
- [ ] Add detailed error messages for debugging
- [ ] Return null on failure (don't throw)

**API Details**:
```dart
// Client ID Resolution
Future<String?> fetchClientId(String virtualUid) async {
  // GET https://vuid.eye4.cn?vuid={virtualUid}
  // Returns JSON with "uid" field
}

// Service Parameter
Future<String?> fetchServiceParam(String uidPrefix) async {
  // POST https://authentication.eye4.cn/getInitstring
  // Body: {"uid": [uidPrefix]}  // e.g., ["OKB0"]
  // Returns array with service param
}
```

**Estimated Effort**: 45 minutes

---

### Story 3: Add "Fetch & Cache" Button to P2P Test Screen

**File**: `flutter_veepa_module/lib/screens/p2p_test_screen.dart`

**Purpose**: Allow user to fetch and cache credentials when online

**Acceptance Criteria**:
- [ ] Add "Fetch & Cache Credentials" button (green)
- [ ] When pressed:
  - Show "Fetching from cloud..." in logs
  - Call `P2PCredentialFetcher.fetchAllCredentials()`
  - Display fetched values in logs (partially masked for security)
  - Save to cache using `P2PCredentialCache.saveCredentials()`
  - Show success/failure message
- [ ] Disable button while fetching (show spinner)
- [ ] Handle network errors gracefully

**UI Layout**:
```
┌─────────────────────────────────────┐
│  Camera UID: OKB0379853SNLJ         │
├─────────────────────────────────────┤
│ [Fetch & Cache]  [Test Direct LAN]  │
│                                     │
│ [Test with Cache]  [Clear Cache]    │
├─────────────────────────────────────┤
│  Cache Status: ✓ Cached (2 min ago) │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │ Logs appear here...         │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

**Estimated Effort**: 45 minutes

---

### Story 4: Add "Test with Cache" Button (CRITICAL - Full Connection Flow)

**File**: `flutter_veepa_module/lib/screens/p2p_test_screen.dart`

**Purpose**: Test COMPLETE P2P connection using cached credentials (works offline)

**IMPORTANT**: The full connection flow requires:
1. Create client with clientId
2. P2P connect with serviceParam
3. **LOGIN with username/password** ← Often missed!
4. Set up connection listeners

**Acceptance Criteria**:
- [ ] Add "Test with Cache" button (orange)
- [ ] Add password input field (default: "admin")
- [ ] When pressed:
  - Check if credentials are cached
  - If not cached, show error "No cached credentials. Fetch first."
  - If cached, load credentials
  - **Step 1**: Create P2P client with cached clientId
  - **Step 2**: Connect with cached serviceParam
  - **Step 3**: LOGIN with username "admin" + password
  - **Step 4**: Check connection mode (P2P vs Relay)
  - Display all steps in logs
  - Show final result (success/failure)
- [ ] Button disabled if no cache exists
- [ ] Proper cleanup on failure or completion

**Complete Connection Flow**:
```dart
Future<void> _runTestWithCache() async {
  _log('=== TEST WITH CACHED CREDENTIALS ===');

  // 1. Load cache
  final cache = P2PCredentialCache();
  final credentials = await cache.loadCredentials(_cameraUID);

  if (credentials == null) {
    _log('ERROR: No cached credentials found');
    _log('Please fetch credentials first (requires internet)');
    return;
  }

  _log('Loaded cached credentials:');
  _log('  clientId: ${_maskString(credentials.clientId)}');
  _log('  serviceParam: ${_maskString(credentials.serviceParam)}');
  _log('  cached at: ${credentials.cachedAt}');

  int? clientPtr;
  try {
    // 2. Create client with cached clientId (NOT the virtual UID!)
    _log('');
    _log('Step 1: Creating P2P client...');
    _log('  Using REAL clientId (not virtual UID)');
    clientPtr = await AppP2PApi().clientCreate(credentials.clientId);

    if (clientPtr == null || clientPtr == 0) {
      _log('  FAILED - Could not create client');
      return;
    }
    _log('  OK - Client pointer: $clientPtr');

    // 3. Connect with cached serviceParam
    _log('');
    _log('Step 2: P2P Connection...');
    _log('  lanScan: true');
    _log('  serviceParam: (from cache)');
    _log('  connectType: 63 (LAN mode)');

    final connectResult = await AppP2PApi().clientConnect(
      clientPtr,
      true,  // lanScan
      credentials.serviceParam,
      connectType: 63,
      p2pType: 0,
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () => ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT,
    );

    _log('  Result: ${connectResult.name}');

    if (connectResult != ClientConnectState.CONNECT_STATUS_ONLINE) {
      _log('');
      _log('ERROR: P2P connection failed');
      _log('Cached credentials may be invalid or expired');
      return;
    }

    // 4. LOGIN - CRITICAL STEP!
    _log('');
    _log('Step 3: Login to camera...');
    _log('  username: admin');
    _log('  password: $_password');

    final loginResult = await AppP2PApi().clientLogin(
      clientPtr,
      'admin',
      _password,  // From password input field
    );

    _log('  Login result: $loginResult');

    if (!loginResult) {
      _log('');
      _log('ERROR: Login failed');
      _log('Check if password is correct');
      return;
    }

    // 5. Check connection mode
    _log('');
    _log('Step 4: Checking connection mode...');
    final modeResult = await AppP2PApi().clientCheckMode(clientPtr);
    _log('  Mode: ${modeResult.mode.name}');

    if (modeResult.mode == ClientConnectMode.CONNECT_MODE_P2P) {
      _log('  ✓ DIRECT P2P CONNECTION!');
    } else if (modeResult.mode == ClientConnectMode.CONNECT_MODE_RELAY) {
      _log('  ⚠ Using cloud relay (not direct)');
    }

    // 6. SUCCESS!
    _log('');
    _log('=== SUCCESS ===');
    _log('Camera connected with cached credentials!');
    _log('Offline P2P connection is WORKING!');

  } catch (e) {
    _log('');
    _log('EXCEPTION: $e');
  } finally {
    // 7. Cleanup
    if (clientPtr != null && clientPtr != 0) {
      _log('');
      _log('Cleaning up...');
      await AppP2PApi().clientDisconnect(clientPtr);
      await AppP2PApi().clientDestroy(clientPtr);
      _log('  Client destroyed');
    }
    _log('');
    _log('=== TEST COMPLETE ===');
  }
}

String _maskString(String s) {
  if (s.length <= 8) return '****';
  return '${s.substring(0, 4)}...${s.substring(s.length - 4)}';
}
```

**UI Addition**: Password input field
```dart
TextField(
  controller: _passwordController,
  decoration: InputDecoration(
    labelText: 'Camera Password',
    hintText: 'admin',
  ),
  obscureText: true,
)
```

**Estimated Effort**: 45 minutes (increased due to login step)

---

### Story 5: Add Cache Status Display

**File**: `flutter_veepa_module/lib/screens/p2p_test_screen.dart`

**Purpose**: Show current cache status on the test screen

**Acceptance Criteria**:
- [ ] Display cache status section below buttons
- [ ] Show: "No credentials cached" or "✓ Cached (X minutes ago)"
- [ ] Show partial clientId if cached (first 8 chars + "...")
- [ ] Add "Clear Cache" button (red, small)
- [ ] Auto-refresh status when credentials are fetched/cleared

**UI**:
```
Cache Status:
  ✓ Credentials cached
  Camera: OKB0379853SNLJ
  Client ID: ABCD1234...
  Cached: 5 minutes ago
  [Clear Cache]
```

**Estimated Effort**: 20 minutes

---

### Story 6: Add Manual Credential Entry (Fallback)

**File**: `flutter_veepa_module/lib/screens/p2p_test_screen.dart`

**Purpose**: Allow manual entry of credentials (if obtained from Veepa or sniffing)

**Acceptance Criteria**:
- [ ] Add "Manual Entry" button
- [ ] When pressed, show dialog with two text fields:
  - Client ID
  - Service Parameter
- [ ] Validate inputs (not empty)
- [ ] Save to cache when submitted
- [ ] Show success message

**Use Case**: If user obtains credentials through other means (e.g., from Veepa support, or by capturing network traffic from official app), they can enter them manually.

**Estimated Effort**: 30 minutes

---

## Complete File Changes Summary

### New Files to Create

| File | Story | Purpose |
|------|-------|---------|
| `lib/services/p2p_credential_cache.dart` | 1 | Local storage for credentials |
| `lib/services/p2p_credential_fetcher.dart` | 2 | Fetch from cloud APIs |
| `lib/models/p2p_credentials.dart` | 1 | Data model with validation |

### Existing Files to Modify

| File | Story | Changes |
|------|-------|---------|
| `lib/screens/p2p_test_screen.dart` | 3,4,5,6 | Add buttons, password field, cache status |

### Files NOT Modified (Low Impact)

These SDK files remain unchanged:
- `lib/sdk/app_p2p_api.dart` - Used as-is
- `lib/sdk/p2p_device/p2p_device.dart` - Not modified
- `lib/sdk/p2p_device/p2p_connect.dart` - Not modified
- Native iOS code - Not modified

### Dependencies

| Package | Purpose | Already Installed? |
|---------|---------|-------------------|
| `shared_preferences` | Store cached credentials | ✅ Yes |
| `dio` | HTTP requests to cloud | ✅ Yes |

## File Structure

```
flutter_veepa_module/lib/
├── models/
│   └── p2p_credentials.dart         # Story 1 (NEW)
├── services/
│   ├── p2p_credential_cache.dart    # Story 1 (NEW)
│   └── p2p_credential_fetcher.dart  # Story 2 (NEW)
└── screens/
    └── p2p_test_screen.dart         # Stories 3, 4, 5, 6 (MODIFY)
```

---

## Implementation Order

**Recommended sequence**:

1. **Story 1** (Cache Service) - Foundation, no dependencies
2. **Story 2** (Fetcher) - Depends on Story 1's data model
3. **Story 5** (Status Display) - Can test cache visually
4. **Story 3** (Fetch & Cache Button) - Depends on Stories 1, 2, 5
5. **Story 4** (Test with Cache Button) - The main goal
6. **Story 6** (Manual Entry) - Optional fallback

**Minimum Viable Solution**: Stories 1, 2, 3, 4

---

## Testing Plan

### Test Case 1: Fetch Credentials (Online)
**Prerequisites**: Phone connected to WiFi with internet
**Steps**:
1. Open P2P Test screen
2. Tap "Fetch & Cache Credentials"
3. Wait for fetch to complete

**Expected Results**:
- [ ] Logs show "Fetching clientId from vuid.eye4.cn..."
- [ ] Logs show "OK - clientId: XXXX..."
- [ ] Logs show "Fetching serviceParam from authentication.eye4.cn..."
- [ ] Logs show "OK - serviceParam: XXXX..."
- [ ] Logs show "Credentials cached successfully"
- [ ] Cache status shows "✓ Cached (just now)"

### Test Case 2: Test with Cache (Online - Baseline)
**Prerequisites**: Test Case 1 completed, still online
**Steps**:
1. Enter password "admin" in password field
2. Tap "Test with Cache"

**Expected Results**:
- [ ] Step 1: Client created with cached clientId
- [ ] Step 2: P2P connection succeeds (CONNECT_STATUS_ONLINE)
- [ ] Step 3: Login succeeds
- [ ] Step 4: Connection mode shown (P2P or RELAY)
- [ ] Final: "SUCCESS" message

### Test Case 3: Test with Cache (OFFLINE - Key Test!)
**Prerequisites**: Test Case 1 completed (credentials cached)
**Steps**:
1. Enable Airplane Mode (or turn off WiFi + cellular)
2. Verify no internet (try opening Safari)
3. Open app → P2P Test screen
4. Enter password "admin"
5. Tap "Test with Cache"

**Expected Results**:
- [ ] Cached credentials load successfully (no network call)
- [ ] Step 1: Client created
- [ ] Step 2: P2P connection... **THIS IS THE KEY RESULT**
  - If ONLINE → **OFFLINE P2P WORKS!** 🎉
  - If TIMEOUT → Camera still needs cloud for something
- [ ] Step 3: Login (if Step 2 succeeded)

### Test Case 4: No Cache Error Handling
**Prerequisites**: Clear cache or fresh install
**Steps**:
1. Turn off internet
2. Open P2P Test screen
3. Tap "Test with Cache"

**Expected Results**:
- [ ] Error: "No cached credentials found"
- [ ] Message: "Please fetch credentials first (requires internet)"

### Test Case 5: Wrong Password Handling
**Prerequisites**: Credentials cached
**Steps**:
1. Enter wrong password (e.g., "wrongpass")
2. Tap "Test with Cache"

**Expected Results**:
- [ ] P2P connection succeeds
- [ ] Login fails with appropriate error message

### Test Case 6: Cache Persistence
**Prerequisites**: Credentials cached
**Steps**:
1. Force-quit the app
2. Reopen app
3. Go to P2P Test screen

**Expected Results**:
- [ ] Cache status shows credentials still cached
- [ ] Timestamp shows when originally cached

---

## Troubleshooting Guide

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| "Failed to fetch clientId" | No internet / API down | Check network, try again |
| "Failed to fetch serviceParam" | API returned empty | Check camera UID prefix is valid |
| P2P connection timeout (online) | Camera offline | Check camera is powered on |
| P2P connection timeout (offline) | Cached credentials invalid | Re-fetch credentials online |
| Login failed | Wrong password | Check password, try "admin" |
| "Invalid client" error | SDK not initialized | Restart app, check native SDK |
| Cache not persisting | Storage permission | Check app permissions |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Credentials expire | Low | High | Add refresh mechanism, check expiry |
| Credentials are device-specific | Medium | High | Test with captured credentials first |
| Cloud APIs change format | Low | Medium | Add response validation |
| Camera needs cloud for video (not just P2P) | Medium | High | This would mean offline is impossible |

---

## Success Criteria

The implementation is successful if:

1. ✅ Credentials can be fetched and cached when online
2. ✅ Cached credentials persist across app restarts
3. ✅ "Test with Cache" works without internet connectivity
4. ⚠️ **KEY**: P2P connection succeeds with cached credentials

**Note**: Even with cached credentials, the camera might still require cloud connectivity for video streaming (not just the P2P handshake). This implementation tests whether the P2P connection can be established offline. Video streaming is a separate concern.

---

## Appendix: API Endpoint Details

### vuid.eye4.cn

**Purpose**: Resolve virtual UID to real device ID

**Request**:
```http
GET https://vuid.eye4.cn?vuid=OKB0379853SNLJ
Content-Type: application/json; charset=utf-8
```

**Response** (expected):
```json
{
  "uid": "REAL_DEVICE_ID",
  "supplier": "supplier_name",
  "cluster": "cluster_name"
}
```

### authentication.eye4.cn

**Purpose**: Get service parameters (initstring) for P2P

**Request**:
```http
POST https://authentication.eye4.cn/getInitstring
Content-Type: application/json; charset=utf-8

{
  "uid": ["OKB0"]
}
```

**Response** (expected):
```json
["LONG_SERVICE_PARAMETER_STRING"]
```

---

*Plan created: January 16, 2026*
*For: VeepaCameraPOC - Offline P2P Connection*
