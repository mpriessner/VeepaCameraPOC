# Video Streaming Analysis & Troubleshooting Plan v2

**Document**: VS-005 Deep Analysis
**Created**: January 17, 2026
**Status**: New Hypotheses and Experiments Defined

---

## 1. Objective

To achieve reliable, offline video streaming from the Veepa camera by successfully authenticating and starting the video stream using the low-level P2P API. This document provides a deep analysis of the codebase and a new set of experiments to resolve the `result=-1` error.

---

## 2. Core Analysis: The Two Connection Flows

The key to solving this is understanding the difference between the SDK's high-level `CameraDevice` class (which works, but requires internet) and the low-level approach in `p2p_test_screen.dart` (which you are using for offline access).

### Flow A: `CameraDevice` (The "Official" Online Method)

This is a complex, stateful process designed for robust, cloud-assisted connection.

1.  **`connect()` is called.**
2.  **`getClientId()` -> Internet Required**: Resolves the camera's virtual UID (e.g., `OKB...`) to its real `clientId` (e.g., `VSGG...`) and fetches a critical `serviceParam` from the cloud. **This is the step we bypass with caching.**
3.  **`_checkConnectType()`**: Dynamically selects a `connectType`. It often defaults to **`126`** (cloud-assisted P2P) or `0x7B` (123) for certain camera models.
4.  **`p2pConnect()`**: It attempts to connect, and may retry with different connection types if one fails.
5.  **`_login()`**: After a successful P2P connection, it sends the `admin`/`password` credentials.
6.  **Crucially, it waits for and validates the `CMD 24577` (STATUS) response.** It explicitly checks `result.result` for error codes like `-1`, `-2`, `-3` and sets the state to `CameraConnectState.password` on failure. This confirms our original finding.

### Flow B: `p2p_test_screen` (The Current Offline Method)

This is a manual, low-level attempt to replicate Flow A without the internet requirement.

1.  **`_connectForVideo()` is called.**
2.  **Load from Cache**: It successfully loads the `clientId` and `serviceParam` that were previously fetched from the cloud.
3.  **`clientCreate(clientId)`**: Creates a P2P client using the **real, cached `clientId`**.
4.  **`clientConnect(connectType: 63)`**: Attempts connection using **`connectType: 63`** (LAN-only mode).
5.  **`clientLogin()`**: Sends the login credentials.
6.  **Asynchronous `result=-1`**: The `_onCameraCommand` listener receives `CMD 24577` with `result=-1`, indicating an authentication failure. The camera session is now in a state that will not permit streaming.
7.  The code proceeds to create a player and request the stream, but the camera ignores these requests due to the failed login.

### Key Insight & The "No Password" Contradiction

The `CameraDevice` handles the `result=-1` as a definitive password error. The tech team's claim of "no password" is therefore either:
a) Incorrect, and the password *is* the issue.
b) True only under specific conditions we haven't met.

The most significant difference between the two flows is the **`connectType`** (`126` vs. `63`). It is highly likely that `connectType=63` is a limited "discovery" mode, while `connectType=126` is the full-featured mode required for authenticated streaming, even on a local network.

---

## 3. New Hypotheses & Detailed Investigation Steps

Here is a set of experiments, ordered from most likely to least likely to succeed. The goal is to make one change at a time and observe the result.

### **Hypothesis 1: `connectType=63` is the wrong mode for authenticated streaming.**

This is the most probable cause of the issue. The `connectType=126` (used by `CameraDevice`) is likely required to signal a full-featured P2P session, even if the connection resolves locally.

#### **Action 1.1: The Critical Experiment**
Modify `_connectForVideo()` in `p2p_test_screen.dart` to use `126` instead of `63`. This combines your cached credentials with the connection type from the official flow.

**File:** `lib/screens/p2p_test_screen.dart`
**Function:** `_connectForVideo()`

**Change this:**
```dart
      // Step 2: P2P Connect (LAN mode with cached serviceParam)
      _log('');
      _log('Step 2: P2P connecting (LAN mode)...');
      final connectResult = await AppP2PApi()
          .clientConnect(
            clientPtr,
            true,  // lanScan
            credentials.serviceParam,
            connectType: 63,  // LAN mode
            p2pType: 0,
          )
```

**To this:**
```dart
      // Step 2: P2P Connect (TRYING CLOUD-ASSISTED TYPE ON LAN)
      _log('');
      _log('Step 2: P2P connecting (Using connectType 126 on LAN)...');
      final connectResult = await AppP2PApi()
          .clientConnect(
            clientPtr,
            true,  // lanScan
            credentials.serviceParam,
            connectType: 126,  // <-- CRITICAL CHANGE
            p2pType: 0,
          )
```
**Expected Outcome:** If this works, you should see `result=0` in the `CMD 24577` response, and the video stream should start. This would prove that `connectType=126` is necessary even for local streaming.

---

### **Hypothesis 2: The password IS the problem, and the camera is in a "bad" state.**

This assumes the tech team is wrong and `result=-1` is definitive. The `admin`/`admin` password may only be valid on a completely fresh, un-configured camera.

#### **Action 2.1: The "Clean Room" Test**
The goal is to connect to the camera when it's in its purest factory state.

1.  **Factory Reset:** Perform a full, 10+ second factory reset on the camera.
2.  **DO NOT USE THE EYE4 APP.**
3.  **Connect Directly:** Connect your phone's WiFi directly to the camera's own WiFi hotspot (its AP mode). The camera is now isolated from everything.
4.  **Run the App:** Run your app and execute the **existing `_connectForVideo` flow** (with `connectType: 63`).
5.  **Observe:** Check the logs for the `CMD 24577` response.

**Expected Outcome:** If `result=0` is received, it proves that `admin`/`admin` works *only* on a pristine camera. This implies that as soon as the camera is configured by the Eye4 app, it gets a new, unique password, and the offline low-level approach would require that new password.

#### **Action 2.2: Confirm the meaning of `result=-1`**
In your current setup, run `_connectForVideo` but intentionally enter a wrong password (e.g., `wrongpass`). If you still get `result=-1`, it strongly confirms this code means "password error". Then, try with a **blank password**. Some cameras use this as a default.

---

### **Hypothesis 3: A preliminary "handshake" command is missing.**

The `CameraDevice` class is constantly communicating with the camera (`requestWakeupStatus`, `getStatus`). Your low-level approach might be missing a command that tells the camera "I'm a trusted client".

#### **Action 3.1: Log the "Official" Command Sequence**
The `p2p_test_screen.dart` already has a button "Full SDK" which runs `_testWithCameraDevice`. We can spy on it to see exactly what it does.

1.  **Modify the low-level `writeCgi` function to log all outgoing commands.**

    **File:** `lib/sdk/p2p_device/p2p_device.dart` (Note: this is `p2p_device`, not `app_p2p_api`)
    **Function:** `writeCgi`

    **Add a print statement:**
    ```dart
    Future<bool> writeCgi(String cgi, {int timeout = 5}) async {
      // Add this line to log the command
      print('[P2P_DEVICE_LOG] Writing CGI: $cgi');
      
      if (_clientPtr == null) {
        return false;
      }
      return AppP2PApi().clientWriteCgi(_clientPtr!, cgi, timeout: timeout);
    }
    ```

2.  **Run the "Full SDK" Test:** Go online, and run the test using the "Full SDK" button.
3.  **Capture the Logs:** Copy the entire sequence of CGI commands from the debug console (look for `[P2P_DEVICE_LOG]`).
4.  **Replicate the Sequence:** Modify your `_connectForVideo` function to send the *exact same sequence of CGI commands* in the same order before you attempt to start the stream.

**Expected Outcome:** You may discover that `CameraDevice` sends a specific `get_status.cgi`, `get_params.cgi`, or other command before login that is critical for the handshake.

---

## 4. Path Forward

1.  **Start with Action 1.1 immediately.** It's the simplest and most likely fix. Changing `connectType: 63` to `connectType: 126` requires a one-line change and could solve the entire problem.

2.  If that fails, proceed to **Hypothesis 2** to definitively settle the password question. The "Clean Room" test (Action 2.1) is vital.

3.  If the password is still an issue, **Hypothesis 3** is your next best bet. Spying on the `CameraDevice` command sequence will give you the ground truth of how the official SDK communicates.

This structured approach will methodically eliminate variables and should lead you to the correct combination of `connectType`, credentials, and commands required for offline streaming.
