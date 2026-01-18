# Execution Plan for Veepa Camera Connection Task

**To:** Coding Agent
**From:** Project Lead
**Date:** January 17, 2026
**Subject:** Action plan for resolving the Veepa Camera streaming issue.

---

## 1. Objective

Achieve a stable, offline video stream from the Veepa camera to the test application. The primary environment is the camera and the phone being connected to the same local router, without requiring an internet connection.

## 2. Context & Key Findings

Our primary obstacle has been a persistent `result=-1` error during the login phase, which we have confirmed corresponds to a "wrong password" error.

**Critical Finding:** Analysis of the official SDK documentation (specifically `flutter sdk参数使用说明.pdf`) has revealed that the **factory default password is `888888`**, not `admin`. This is the most significant lead and must be prioritized.

The existing testbed, `p2p_test_screen.dart`, is the correct environment for executing these tests. All necessary documentation is now located in the `docs/official_documentation/` folder for reference.

## 3. Primary Action Plan (Execute First)

This is the highest priority task and is expected to solve the problem.

### **Task 1: Test Connection with Correct Default Password**

1.  **Action:** In the `P2PTestScreen` UI of the Flutter application, enter the following credentials:
    *   **Username:** `admin`
    *   **Password:** `888888`
2.  **Execute:** Run the "Connect for Video" flow using the app's UI (typically the "Connect" and then "Start Video" buttons, which trigger the `_connectForVideo` function).
3.  **Observe:** Monitor the application logs for the response to the login command.
    -   **Success:** The camera returns `result=0` in the `CMD 24577 (STATUS)` response. You should subsequently receive video frames, and the stream should appear in the player.
    -   **Failure:** The camera still returns `result=-1`.

**If this task is successful, the primary objective is met. No further steps are necessary.**

---

## 4. Contingency Plan (Execute Only if Task 1 Fails)

If the `888888` password does not work, it implies the password was changed from the factory default at some point. Proceed with the following experiments derived from the `VIDEO_STREAMING_ANALYSIS_V2.md` document.

### **Task 2: Experiment with `connectType`**

The official `CameraDevice` class uses `connectType: 126`, whereas our offline test uses `63`. This may be the point of failure.

1.  **Action:** In `p2p_test_screen.dart`, locate the `_connectForVideo` function. Modify the `clientConnect` call to use `126`.
    ```dart
    // Change this line in _connectForVideo()
    final connectResult = await AppP2PApi().clientConnect(
        clientPtr,
        true,
        credentials.serviceParam,
        connectType: 126, // Change from 63 to 126
        p2pType: 0,
    );
    ```
2.  **Execute:** Repeat the connection test. Attempt it with both `888888` and `admin` as the password.
3.  **Rationale:** This test determines if `connectType: 126` is mandatory for authenticated streaming, even on a local network.

### **Task 3: Perform a "Clean Room" Test**

This test will determine if the password is changed permanently after initial setup.

1.  **Action:** Follow the steps for the "Clean Room" test as detailed in **Action 2.1** of `docs/official_documentation/VIDEO_STREAMING_ANALYSIS_V2.md`. The key steps are:
    a.  Perform a hard factory reset of the camera (hold reset button >10s).
    b.  **Do not** use the Eye4 app.
    c.  Connect the phone directly to the camera's own WiFi hotspot (AP Mode).
    d.  Run the `_connectForVideo` flow using the `888888` password.
2.  **Rationale:** This creates a pristine testing environment. If the connection works here, it proves the password is changed during cloud setup.

### **Task 4: Refine Stream Start Sequence**

If the previous tasks succeed in logging in (`result=0`) but video still fails to start, the command sequence for starting the stream may be incorrect. The official SDK waits for a confirmation command before starting the player.

1.  **Action:** Modify the `_startVideo` function in `p2p_test_screen.dart`. After sending the `livestream.cgi` command, add logic to wait for the `CMD 24631` response from the camera *before* calling `_playerController!.start()`. You can implement this by adapting the `waitCommandResult` logic from `lib/sdk/p2p_device/p2p_command.dart`.
2.  **Rationale:** This ensures the player only tries to render the stream after the camera has explicitly confirmed it has started sending video data, which is a more robust approach.

---

## 5. Advanced Fallback Plan

If all the above steps fail, we can bypass the P2P library and use the CGI commands directly over HTTP.

### **Task 5: Direct HTTP CGI Communication Test**

1.  **Action:**
    a.  Identify the camera's local IP address from your router's DHCP client list.
    b.  Using `curl` or a web browser, attempt to make the following HTTP GET request:
        ```
        http://<CAMERA_IP_ADDRESS>/get_status.cgi?loginuse=admin&loginpas=888888
        ```
2.  **Observe:**
    -   **Success:** The request returns a text string with the device status (e.g., `var alias="IPCAM"; var id="...";` etc.).
    -   **Failure:** The request times out or returns an authentication error.
3.  **Rationale:** Success here proves the camera's web server is accessible on the LAN and provides a viable, if more complex, alternative for communication by sending CGI commands directly. The full CGI manual is available at `docs/official_documentation/CGI_COMMAND_MANUAL_v12_20231223.md`.

Please proceed with this plan, starting with Task 1. Report the outcome before proceeding to the contingency plans.
