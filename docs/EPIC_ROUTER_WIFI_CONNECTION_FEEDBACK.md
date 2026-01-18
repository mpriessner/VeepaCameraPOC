# Feedback: EPIC_ROUTER_WIFI_CONNECTION

Scope
- Review of docs/stories/EPIC_ROUTER_WIFI_CONNECTION.md against official documentation and current SDK code.
- Focus: connecting camera to phone via router (STA mode), reliability, and correctness.

Primary Findings (Most Critical First)
1) Default credentials conflict
- Official docs state username is fixed to admin and factory default password is 888888.
- Epic assumes 888888 in several tests but also includes wording that implies credentials are uncertain.
- Action: make 888888 the explicit baseline in setup and troubleshooting, and provide a path to handle per-device passwords.
- Sources: docs/official_documentation/flutter_sdk_parameter_usage_instructions.md, docs/official_documentation/veepai_device_adding_and_usage_process.md.

2) LAN-only assumption is risky for virtual IDs
- The SDK treats OKB-style IDs as virtual and relies on cloud resolution to VSTH clientId and serviceParam.
- Even on the same router, connectType=63 may fail for virtual IDs; SDK defaults to connectType=126 and uses cloud-assisted parameters.
- Action: make connectType=126 the default for router reconnection flows unless the device is confirmed non-virtual.
- Sources: flutter_veepa_module/lib/sdk/p2p_device/p2p_device.dart, flutter_veepa_module/lib/sdk/camera_device/camera_device.dart.

3) Login success must be verified before WiFi CGI
- Official docs instruct waiting for cmd 24577 responses; login return value only means request sent, not accepted.
- The epic does not require a successful login confirmation before scanning or setting WiFi.
- Action: require cmd 24577 with result=0 before running wifi_scan.cgi or set_wifi.cgi.
- Sources: docs/official_documentation/flutter_sdk_parameter_usage_instructions.md, flutter_veepa_module/lib/sdk/camera_device/commands/status_command.dart.

4) Potential false password error with virtual IDs
- CameraDevice.connect() flags password errors when realdeviceid != id, which happens if you used a virtual OKB id.
- Action: resolve to real clientId and use that for connection where possible, or adjust logic to tolerate vuid/realdeviceid mismatch.
- Source: flutter_veepa_module/lib/sdk/camera_device/camera_device.dart.

5) Empty password is blocked by SDK wrapper
- CGI docs show loginpas= (empty) is valid in some contexts, but AppP2PApi.clientLogin rejects empty passwords.
- Action: add a debug-only switch to allow empty password tests.
- Sources: docs/official_documentation/CGI_COMMAND_MANUAL_v12_20231223.md, flutter_veepa_module/lib/sdk/app_p2p_api.dart.


What I Would Change or Add to the Epic

A) Connection prerequisites
- Add explicit step: resolve VUID to real clientId (VSTH…) and fetch serviceParam before router connection.
- Track and store the real clientId per device for router-mode reconnect.

B) Login verification gate
- Add acceptance criteria: login is considered successful only when cmd 24577 result=0 is received.
- Add a manual test that confirms cmd 24577 result=0 before wifi_scan.cgi.

C) Stream start sequence alignment
- Epic should require: startStream() -> wait for cmd 24631 -> start player.
- This follows SDK’s VideoCommand.startStream pattern.
- Source: flutter_veepa_module/lib/sdk/camera_device/commands/video_command.dart.

D) Dual-path router connect
- Add branch: if device is virtual ID, use connectType=126; if not virtual, allow connectType=63.
- Provide UI feedback for which mode is used (P2P vs relay).

E) Password handling clarity
- Add a subsection in the setup flow: 
  - Default password 888888
  - If provisioning uses per-device password (from QR or vendor system), prompt for it.

F) Failure modes from official docs
- The official flow includes device binding (ID + password). Add a failure mode for “binding not complete” or “device not activated,” and guide to Eye4/Veepai onboarding if needed.


Suggested Acceptance Criteria Additions
- Router reconnect must succeed with connectType=126 for virtual IDs; fallback to relay mode is acceptable but must be visible.
- Command listener must be attached before login and all cmd 24577 responses logged.
- WiFi scan returns SSID, signal, security, and channel from get_wifi_scan_result.cgi.
- WiFi configuration includes confirmation of camera reboot and a poll/retry loop for device availability.


Open Questions to Resolve (Before Implementation)
- Do we have an official list of wifi_scan.cgi/get_wifi_scan_result.cgi/set_wifi.cgi parameters? Not in the translated CGI manual; confirm in vendor docs or SDK demo.
- For router mode, do we require cloud connectivity even if the phone and camera are on the same LAN? Current SDK suggests yes for virtual IDs.
- Is the device password provided in the camera’s QR code or only via vendor binding flow?


Practical Implementation Notes (from codebase)
- connectType defaults to 126 in CameraDevice; align router flows with that.
- The current P2P test screen uses connectType=63 in some places; avoid copying that into router flows.
- Use AppP2PApi.setCommandListener before login and before wifi_scan.


Recommended Next Step for Agent
- Update EPIC_ROUTER_WIFI_CONNECTION.md with the above acceptance criteria and gating logic.
- Implement a small diagnostic flow: connect -> login -> cmd 24577 parse -> wifi_scan -> get_wifi_scan_result -> set_wifi.

