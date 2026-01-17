# Deep Dive Troubleshooting: Veepa Camera Connection & Streaming

**Document**: VS-005 Technical Analysis
**Created**: January 17, 2026
**Status**: ACTIVE INVESTIGATION
**Vendor Feedback**: "No default passwords, SDK allows direct video streaming"

---

## Executive Summary

After deep analysis of the SDK codebase and vendor feedback, we discovered:

1. **`result=-1` does NOT necessarily mean "wrong password"** - it's a generic login failure
2. **The SDK CAN stream video directly without authentication** - vendor confirmed
3. **We may be hitting initialization issues**, not password problems
4. **Critical missing step**: Command listener setup timing

---

## Part 1: What We Misunderstood

### The `result=-1` Myth

We assumed:
```
result=-1 = "Wrong password"
```

Reality (from `camera_device.dart:330-335`):
```dart
if (result.result == "-1" || result.result == "-2" || result.result == "-3") {
  connectState = CameraConnectState.password;  // MISLEADING LABEL
}
```

**The code labels ALL of these as "password" error, but they mean:**

| Result | Actual Meaning |
|--------|----------------|
| `-1` | Generic login failure (timeout, no listener, device not ready, OR wrong password) |
| `-2` | Second login attempt failed |
| `-3` | Third login attempt failed |
| `-4` | Illegal/invalid device state |
| `0` | Success |

### The Vendor's Claim Explained

> "There are no default passwords and authentication restrictions"
> "The SDK allows video data to be streamed directly"

**This is TRUE because:**

1. **Option A**: Skip login entirely - send `livestream.cgi` directly after P2P connect
2. **Option B**: Camera firmware doesn't require password for video
3. **Option C**: P2P connection itself IS the authentication

---

## Part 2: Root Cause Hypotheses

### Hypothesis 1: Missing Command Listener (HIGH PROBABILITY)

**The Problem:**
```dart
// In camera_device.dart:313
await this.setCommandListener();  // ← MUST happen before login
```

If this isn't called, the camera's response (CMD 24577) is lost, and `waitCommandResult()` times out.

**Evidence:**
- Your log shows CMD 24577 arriving AFTER "SUCCESS" message
- The listener was set up too late

### Hypothesis 2: Video Works Without Login (VENDOR CONFIRMED)

**The Possibility:**
```dart
// Skip login entirely, go straight to video:
await p2pConnect();  // Get P2P online
await setCommandListener();
await startStream();  // Send livestream.cgi directly
// Camera might stream without password!
```

### Hypothesis 3: Empty Password Works

Some camera firmwares accept:
- Empty string `""`
- Default `"888888"`
- Or literally no password field

### Hypothesis 4: AP Mode Has Different Rules

When connected to camera's WiFi hotspot:
- Authentication might be disabled
- Local network = trusted

---

## Part 3: Experiments to Try

### Experiment 1: Video Without Login

**Goal**: Test if camera streams without authentication

```dart
Future<void> testVideoWithoutLogin() async {
  final credentials = await _cache.loadCredentials(_cameraUID);

  // Step 1: Create P2P client
  final clientPtr = await AppP2PApi().clientCreate(credentials.clientId);

  // Step 2: P2P Connect (but DON'T login)
  await AppP2PApi().clientConnect(
    clientPtr, true, credentials.serviceParam,
    connectType: 63,  // LAN mode
  );

  // Step 3: Set command listener
  AppP2PApi().setCommandListener(clientPtr, (cmd, data) {
    print('>>> CMD $cmd: ${String.fromCharCodes(data)}');
  });

  // Step 4: Create player
  final player = AppPlayerController(changeCallback: ...);
  await player.create();
  await player.setVideoSource(LiveVideoSource(clientPtr));

  // Step 5: Send livestream CGI DIRECTLY (no login!)
  await AppP2PApi().clientWriteCgi(clientPtr, 'livestream.cgi?streamid=10&substream=2&');

  // Step 6: Start player
  await player.start();

  // OBSERVE: Does video stream without authentication?
}
```

### Experiment 2: Empty Password

**Goal**: Test if camera accepts empty password

```dart
// In your test, try:
await AppP2PApi().clientLogin(clientPtr, 'admin', '');  // Empty password
// Check CMD 24577 response for result=0
```

### Experiment 3: Different Default Passwords

Try these in sequence:
1. `""` (empty)
2. `"888888"` (common default)
3. `"admin"`
4. `"123456"`
5. Last 6 digits of camera serial number

### Experiment 4: Check Command Listener Timing

**Goal**: Ensure listener is set BEFORE login

```dart
// CORRECT ORDER:
clientPtr = await AppP2PApi().clientCreate(id);
await AppP2PApi().clientConnect(clientPtr, ...);

// SET LISTENER FIRST!
AppP2PApi().setCommandListener(clientPtr, (cmd, data) {
  print('>>> CMD $cmd received');
  if (cmd == 24577) {
    String response = String.fromCharCodes(data);
    print('>>> LOGIN RESPONSE: $response');
    // Look for result=0 vs result=-1
  }
});

// THEN login
await AppP2PApi().clientLogin(clientPtr, 'admin', password);

// Wait and observe what CMD 24577 says
```

### Experiment 5: Use CameraDevice Properly

**Goal**: Follow the exact SDK demo pattern

```dart
// This is how the official demo does it:
CameraDevice device = CameraDevice(_cameraUID, 'Test', 'admin', '', 'QW6-T');

// Add listeners BEFORE connect
device.addListener<StatusChanged>(_onStatus);
device.addListener<CameraConnectChanged>(_onConnect);

// Connect (this handles everything internally)
final state = await device.connect(lanScan: true);

if (state == CameraConnectState.connected) {
  // NOW start video
  await device.startStream(resolution: VideoResolution.general);
}
```

---

## Part 4: Code Changes to Try

### Change 1: Add Verbose Logging

In `p2p_test_screen.dart`, update `_onCameraCommand`:

```dart
void _onCameraCommand(int cmd, Uint8List data) {
  String text = '';
  try {
    text = String.fromCharCodes(data);
  } catch (e) {
    text = '${data.length} bytes (binary)';
  }

  // Parse result field
  if (cmd == 24577) {
    final match = RegExp(r'result=(-?\d+)').firstMatch(text);
    if (match != null) {
      final result = match.group(1);
      _log('>>> LOGIN RESULT: $result');
      if (result == '0') {
        _log('>>> AUTH SUCCESS!');
      } else if (result == '-1') {
        _log('>>> AUTH FAILED: Generic failure (could be password OR timeout OR other)');
      }
    }
  }

  _log('>>> CMD $cmd: $text');
}
```

### Change 2: Try Video Without Login Button

Add a new test button:

```dart
Future<void> _testVideoNoLogin() async {
  _log('=== TEST: Video Without Login ===');

  final credentials = await _cache.loadCredentials(_cameraUID);
  if (credentials == null) {
    _log('ERROR: No cached credentials');
    return;
  }

  // P2P Connect only
  final clientPtr = await AppP2PApi().clientCreate(credentials.clientId);
  await AppP2PApi().clientConnect(clientPtr, true, credentials.serviceParam, connectType: 63);
  _log('P2P Connected');

  // Set listener
  AppP2PApi().setCommandListener(clientPtr, _onCameraCommand);
  _log('Listener set');

  // Skip login entirely!
  _log('SKIPPING LOGIN - going straight to video');

  // Create player
  _playerController = AppPlayerController(changeCallback: _onPlayerState);
  await _playerController!.create();
  await _playerController!.setVideoSource(LiveVideoSource(clientPtr));

  // Send livestream command
  _log('Sending livestream.cgi...');
  await AppP2PApi().clientWriteCgi(clientPtr, 'livestream.cgi?streamid=10&substream=2&');

  // Start player
  await _playerController!.start();

  _log('Player started - watching for frames...');
}
```

### Change 3: Proper Initialization Order

```dart
Future<void> _connectForVideoProper() async {
  // 1. Create client
  final clientPtr = await AppP2PApi().clientCreate(credentials.clientId);
  _videoClientPtr = clientPtr;

  // 2. P2P Connect
  final connectResult = await AppP2PApi().clientConnect(...);
  if (connectResult != ClientConnectState.CONNECT_STATUS_ONLINE) {
    _log('P2P failed');
    return;
  }

  // 3. SET LISTENER IMMEDIATELY AFTER P2P CONNECT
  AppP2PApi().setCommandListener(clientPtr, _onCameraCommand);
  _log('Command listener set');

  // 4. Small delay for camera to be ready
  await Future.delayed(Duration(milliseconds: 500));

  // 5. Try login (observe what happens)
  _log('Attempting login...');
  final loginResult = await AppP2PApi().clientLogin(clientPtr, 'admin', '');
  _log('Login sent: $loginResult');

  // 6. Wait for CMD 24577 response (it will come through _onCameraCommand)
  await Future.delayed(Duration(seconds: 2));

  // 7. Regardless of login result, try video
  _log('Attempting video regardless of login result...');
  // ... create player and start
}
```

---

## Part 5: Questions to Investigate

### About the Camera

1. **What's the camera's web interface?**
   - Connect to camera's AP WiFi
   - Open `http://192.168.168.1` in Safari
   - Is there a password field? What's set?

2. **Does the camera have a reset-to-factory button?**
   - What's the ACTUAL factory password (not assumed)?

3. **Check camera model documentation**
   - Does this model support passwordless streaming?

### About the SDK

1. **Does `clientWriteCgi` work without login?**
   - Try: `get_status.cgi` without calling `clientLogin`
   - If it works, authentication isn't required

2. **What commands does the demo app send?**
   - Run demo app with network logging
   - Capture the exact sequence

---

## Part 6: Key Code Locations

| File | What to Check |
|------|---------------|
| `camera_device.dart:228-383` | Full `connect()` flow |
| `camera_device.dart:313` | Where `setCommandListener()` is called |
| `camera_device.dart:330-336` | Where `result=-1` is interpreted |
| `status_command.dart:520-551` | Login implementation |
| `video_command.dart:55-74` | `startStream()` implementation |
| `p2p_command.dart:166-189` | Command listener system |
| `p2p_command.dart:233-245` | `waitCommandResult()` timeout logic |

---

## Part 7: Summary of Possible Fixes

| Issue | Fix |
|-------|-----|
| Command listener not set | Call `setCommandListener()` IMMEDIATELY after P2P connect |
| Wrong password | Try empty string `""` or `"888888"` |
| Login not required | Skip login, send `livestream.cgi` directly |
| Timing issue | Add 500ms delay between P2P connect and login |
| Camera not ready | Add retry logic with exponential backoff |

---

## Part 8: Next Steps Checklist

### Immediate (Try Today)

- [ ] Test video without login (Experiment 1)
- [ ] Try empty password (Experiment 2)
- [ ] Add verbose command logging (Change 1)
- [ ] Check command listener timing (Experiment 4)

### If Video Without Login Works

- [ ] Document that authentication isn't required
- [ ] Update connection flow to skip login
- [ ] Test stability over time

### If Empty Password Works

- [ ] Document the actual default password
- [ ] Update credentials in app
- [ ] Test full flow

### If Nothing Works

- [ ] Capture camera's web interface settings
- [ ] Contact vendor with specific technical questions
- [ ] Consider using their demo app code directly

---

## Appendix: Command Reference

| CMD Code | Name | Description |
|----------|------|-------------|
| 24577 | STATUS | Login response, contains `result=` field |
| 24631 | LIVESTREAM | Response to `livestream.cgi` |
| 24579 | PARAMS | Camera parameters |
| 24785 | GENERIC | Multi-purpose response |

### Response Format
```
result=-1;vuid=OKB0379196OXYB;realdeviceid=OKB0379196OXYB;pwdfactory=1;
```

Parse with:
```dart
final match = RegExp(r'result=(-?\d+)').firstMatch(response);
final result = match?.group(1);  // "-1", "0", etc.
```

---

*Document created after vendor feedback: "No default passwords, SDK allows direct streaming"*
*This suggests we should try streaming WITHOUT authentication*
