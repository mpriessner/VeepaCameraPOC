# Troubleshooting Guide

## Connection Issues

### Camera Not Found

**Symptoms:**
- Connection attempts time out
- Camera shows as offline

**Solutions:**
1. Verify camera is powered on and connected to WiFi
2. Check if phone and camera are on same network
3. Try LAN discovery mode instead of P2P
4. Verify device ID is correct (from QR code)

```dart
// Force LAN discovery
final config = CameraConfigServiceFactory.forLAN(ip: '192.168.1.100');
```

### P2P Connection Fails

**Symptoms:**
- "P2P connection failed" error
- Long connection times

**Solutions:**
1. Check internet connectivity on both devices
2. Verify firewall allows P2P traffic
3. Try using relay server mode
4. Check camera firmware version

### WiFi AP Not Detected

**Symptoms:**
- Phone doesn't see camera's WiFi network
- "VEEPA_" or "VSTC_" network not appearing

**Solutions:**
1. Reset camera to AP mode (check camera manual)
2. Move closer to camera (within 10 meters)
3. Disable/enable phone WiFi
4. Check if camera AP mode is enabled

## Video Streaming Issues

### No Video / Black Screen

**Symptoms:**
- Connected but no video
- Player state stuck in "buffering"

**Solutions:**
1. Verify camera lens is not covered
2. Check camera video output settings
3. Restart video player:

```dart
await _playerService.stop();
await Future.delayed(Duration(seconds: 1));
await _playerService.start();
```

### Low Frame Rate

**Symptoms:**
- Choppy video
- FPS below 10

**Solutions:**
1. Reduce video quality in camera settings
2. Switch to lower resolution channel
3. Check network bandwidth
4. Close other streaming apps

```dart
// Switch to sub-stream
await _playerService.stop();
await _playerService.start(channel: 1); // Sub-stream
```

### High Latency

**Symptoms:**
- Video delay > 2 seconds
- PTZ controls feel unresponsive

**Solutions:**
1. Use LAN mode instead of P2P
2. Reduce video quality
3. Check for network congestion
4. Use wired connection if available

## PTZ Control Issues

### PTZ Not Responding

**Symptoms:**
- Camera doesn't move
- No response to commands

**Solutions:**
1. Verify camera supports PTZ
2. Check PTZ connection:

```dart
final stats = _ptzService.getStatistics();
print('Commands sent: ${stats["commandsSent"]}');
```

3. Try reconnecting:

```dart
await _connectionManager.disconnect();
await _connectionManager.connect(device);
```

### PTZ Moves Wrong Direction

**Symptoms:**
- Camera moves opposite to expected direction
- Left command moves right

**Solutions:**
1. Check camera orientation settings
2. Some cameras have inverted controls
3. Verify PTZ codes match camera model

## QR Code Scanning Issues

### QR Code Not Recognized

**Symptoms:**
- Scanner doesn't detect QR code
- "Invalid QR code" error

**Solutions:**
1. Ensure QR code is well-lit
2. Hold phone steady, 15-30cm from code
3. Check supported formats:

```dart
// Supported formats:
// VSTC:DEVICE_ID:PASSWORD:MODEL
// {"id":"DEVICE_ID","pwd":"PASSWORD"}
// vstc://DEVICE_ID/password/model
```

4. Try manual entry if scanning fails

## WiFi Provisioning Issues

### Provisioning Fails

**Symptoms:**
- Camera doesn't connect to home WiFi
- "Configuration failed" error

**Solutions:**
1. Verify WiFi credentials are correct
2. Check encryption type matches:
   - Most networks use WPA2
   - Enterprise networks may not be supported
3. Ensure WiFi password is 8+ characters
4. Try rebooting camera manually

### Camera Doesn't Reboot

**Symptoms:**
- Provisioning sent but camera stays in AP mode
- No response after configuration

**Solutions:**
1. Wait 60 seconds for camera to process
2. Manually reboot camera
3. Check CGI command response:

```dart
final result = await _configService.setWifiConfig(...);
print('Result: ${result.message}');
```

## Debug Logging

### Enable Debug Output

```dart
import 'package:flutter/foundation.dart';

// Enable verbose logging
debugPrint('[YourTag] Your message');
```

### Check SDK Logs

```dart
final manager = VeepaSDKManager();
await manager.initialize();

// Check initialization state
print('SDK state: ${manager.initState}');
print('Error: ${manager.errorMessage}');
```

### Export Test Results

```dart
final runner = HardwareTestRunner(
  deviceId: deviceId,
  password: password,
);

final results = await runner.runAllTests();
print(results.toJson());
```

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "SDK not initialized" | SDK init failed | Call `initialize()` first |
| "Not connected" | No active connection | Connect before using services |
| "Connection timeout" | Network issue | Check WiFi, retry connection |
| "Invalid device ID" | Wrong format | Verify QR code scan |
| "Stream failed" | Video issue | Check camera, restart stream |

## Getting Help

If issues persist:

1. Run hardware test suite to identify specific failures
2. Export test results and logs
3. Check camera firmware version
4. Contact Veepa support with device model and logs
