# Session Notes - January 16-17, 2026

**Project**: VeepaCameraPOC - Video Streaming Implementation
**Status**: BLOCKED - But New Insights from Vendor!

---

## CRITICAL UPDATE (January 17, 2026)

**Vendor Feedback Received:**
> "There are no default passwords and authentication restrictions"
> "The SDK allows video data to be streamed directly into my own application"

**This changes everything!** See `DEEP_DIVE_TROUBLESHOOTING.md` for full analysis.

### Key Insight: `result=-1` Misinterpreted

We assumed `result=-1` = wrong password. **WRONG!**

It actually means: Generic login failure (could be timeout, no listener, device not ready, OR password)

### New Approach: Try Video Without Login

The vendor says video streams directly. Try this:
1. P2P Connect (skip login)
2. Set command listener
3. Send `livestream.cgi` directly
4. Start player

See experiments in `DEEP_DIVE_TROUBLESHOOTING.md`

---

## Executive Summary

We made significant progress on video streaming but are blocked by two issues:
1. **App Crash on Restart** - App crashes when reopened after closing
2. **Password Authentication** - Camera rejecting password (`result=-1`)

---

## What Was Accomplished

### 1. Video Streaming Architecture Understood
- `AppPlayerController` creates texture for Flutter rendering
- `LiveVideoSource(clientPtr)` binds player to P2P connection
- `screenshot(filePath)` enables frame capture for Gemini AI integration
- Native library is arm64 only (device testing required, no simulator)

### 2. Connection Flow Working
- P2P connection establishes successfully (`CONNECT_STATUS_ONLINE`)
- Credential caching works (clientId + serviceParam from cloud)
- LAN mode connection works when on camera's AP WiFi

### 3. Root Cause of "No Video" Identified
The video streaming fails because of **password authentication failure**:
```
>>> CMD 24577 (STATUS): result=-1;vuid=OKB0379196OXYB;pwdfactory=1;
```

**Key Insight**: `clientLogin()` returning `true` only means the request was SENT, not that the password was ACCEPTED. The actual result comes asynchronously in CMD 24577 response.

| Result Value | Meaning |
|--------------|---------|
| `result=0` | Password accepted |
| `result=-1` | Wrong password |
| `result=-2` | Wrong username |
| `result=-3` | Auth error |

### 4. Crash Fix Attempted
Added error handling to `app_p2p_api.dart`:
- Wrapped EventChannel stream setup in try/catch
- Added `onError` handlers to prevent crashes from native errors
- Added null/bounds checking on incoming stream data

---

## Current Blockers

### Blocker 1: App Crashes on Restart

**Symptom**: After closing the app completely, it won't reopen (crashes immediately)

**Attempted Fix**: Added error handling to `lib/sdk/app_p2p_api.dart`:
- Stream initialization wrapped in try/catch
- Error handlers on stream listeners
- Null checking on incoming data

**Status**: Fix committed but not yet verified. May need further debugging.

**Next Steps**:
1. Test if error handling fix resolves crash
2. If still crashing, check native iOS SDK (libVSTC.a) for initialization issues
3. Consider adding cleanup in iOS AppDelegate

### Blocker 2: Password Authentication Failure

**Symptom**: Camera responds with `result=-1` (password rejected) even though `pwdfactory=1`

**Root Cause**: When camera is paired with Eye4 app, it changes the password from default `admin/admin` to something else.

**Solution** (not yet completed):
1. Factory reset camera (hold reset 10+ seconds until voice prompt)
2. Do NOT reconnect with Eye4 app after reset
3. Connect directly with our app using `admin/admin`
4. Verify `result=0` in CMD 24577 response

---

## Code Changes Made This Session

### Modified: `lib/sdk/app_p2p_api.dart`

```dart
// BEFORE: No error handling on streams
AppP2PApi._internal() {
  _connectStream.listen(_onConnectListener);
  _commandStream.listen(_onCommandListener);
}

// AFTER: Error handling added
AppP2PApi._internal() {
  _initStreams();
}

void _initStreams() {
  try {
    _connectStream.listen(
      _onConnectListener,
      onError: (error) => print('Connect stream error: $error'),
      cancelOnError: false,
    );
    // ... similar for command stream
  } catch (e) {
    print('Failed to initialize streams: $e');
  }
}
```

Also added null/bounds checking in `_onConnectListener` and `_onCommandListener`.

---

## Files to Review

| File | Purpose |
|------|---------|
| `lib/screens/p2p_test_screen.dart` | Main test UI with video player |
| `lib/sdk/app_p2p_api.dart` | P2P API with crash fix |
| `lib/sdk/app_player.dart` | Video player controller |
| `docs/VIDEO_STREAMING_TROUBLESHOOTING.md` | Detailed debugging log |
| `docs/VIDEO_PLAYER_API.md` | SDK API documentation |

---

## Workflow Reminder

### To Get Video Working:

```
1. Ensure credentials are cached (green box in app)
   - If not: Connect to internet WiFi → "Fetch & Cache"

2. Factory reset camera
   - Hold reset button 10+ seconds
   - Wait for "Reset successful" voice prompt
   - DO NOT open Eye4 app!

3. Connect to camera's AP WiFi (@MC-0379196 or similar)

4. In app:
   - Username: admin
   - Password: admin
   - Tap "Connect" in video section

5. Check logs for:
   >>> CMD 24577 (STATUS): result=0  ← SUCCESS!

6. If result=0, tap "Start Video"
```

---

## Known Issue: UI Shows "Ready" Before Auth Confirmed

The code shows "Ready to Stream" after `clientLogin()` returns `true`, but this is misleading. The code should wait for CMD 24577 response and check `result=0` before showing success.

**Future Fix Needed**: Parse CMD 24577 response in `_onCameraCommand()` and update UI state based on actual authentication result.

---

## Environment

- Camera UID: OKB0379196OXYB
- Camera model: Veepa IP Camera
- SDK: libVSTC.a (arm64 only)
- Flutter: 3.x
- iOS: 18.5

---

## Next Session Checklist

- [ ] Test if app crash is fixed
- [ ] If crash persists, debug native iOS layer
- [ ] Factory reset camera properly (10+ seconds)
- [ ] Test connection with admin/admin
- [ ] Verify `result=0` in CMD 24577
- [ ] If auth works, test video streaming
- [ ] Consider fixing UI to properly check auth result

---

*Last updated: January 16, 2026*
