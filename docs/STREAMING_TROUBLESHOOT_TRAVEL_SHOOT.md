# Streaming Troubleshoot Travel Shoot

Purpose
- Capture what the official documentation says, where it contradicts vendor feedback, and how that changes the troubleshooting plan for live streaming.

Source Documents (Official)
- docs/official_documentation/flutter_sdk_parameter_usage_instructions.md
- docs/official_documentation/veepai_device_adding_and_usage_process.md
- docs/official_documentation/CGI_COMMAND_MANUAL_v12_20231223.md
- docs/official_documentation/CGI Documentation0125.md

What the Official Docs Say (and why it matters)
- Default credentials: username is fixed to admin and factory default password is 888888. This directly contradicts the vendor note that there are no default passwords.
- Device binding uses device ID and password. One example shows a long, random password (70312622c2eec424), which implies per-device passwords can be set or provisioned during onboarding.
- Login result must be verified via the status command (cmd 24577). The docs explicitly call out waiting for cmd 24577 for status responses.
- Live stream flow is CameraDevice.connect() followed by mDevice.startStream(), then AppPlayerController for rendering.
- CGI manual examples show loginpas can be empty (loginpas=). This suggests empty passwords can be valid in some devices or modes. The current SDK Dart wrapper refuses empty passwords.

Contradictions to Vendor Feedback
- Vendor: "no default passwords". Official docs: "factory default is 888888" and admin is fixed. That is a hard contradiction.
- Vendor: "no auth restrictions". Official docs and SDK: login errors are explicit via result codes; devices can return password errors and enforce credentials.

SDK Code Observations (from this repo)
- AppP2PApi.clientLogin rejects empty passwords; this conflicts with CGI manual examples that allow blank passwords.
- CameraDevice.connect() uses status result fields to detect password errors and will also flag password errors if realdeviceid != id when id is a virtual OKB id. That can produce a false "password" state if you connect using OKB instead of the resolved VSTH ID.
- The P2P video path in P2PTestScreen uses connectType=63 (LAN) while the SDK default for virtual IDs is connectType=126 (cloud assist).
- The official flow emphasizes startStream() (which waits for cmd 24631) before starting the player. The test path currently sends livestream.cgi but does not wait for 24631.

Travel Shoot Allegory (New Version)

Act 1: The Passport Office (Credentials + IDs)
- Goal: validate the traveler identity (real device ID + password).
- Evidence: official docs list default password 888888 and admin is fixed.
- Shot list:
  - Try 888888 explicitly, even if vendor said otherwise.
  - Try empty password by temporarily allowing empty in clientLogin.
  - Retrieve the actual password from QR or vendor system if the device has a per-device password (example shows a random password in official docs).

Act 2: The Ferry (P2P Tunnel)
- Goal: establish P2P tunnel in the correct mode for virtual IDs.
- Evidence: SDK chooses connectType=126 for virtual IDs; LAN-only mode often fails.
- Shot list:
  - Switch video connectType to 126 in the live-stream path.
  - Log clientCheckMode() to see if you are P2P or relay after connect.

Act 3: Customs (Authentication Confirmation)
- Goal: confirm cmd 24577 result=0 after login; otherwise no streaming will start.
- Evidence: docs explicitly say to wait for cmd 24577 for status.
- Shot list:
  - Register command listener BEFORE login.
  - Parse cmd 24577 and log result, realdeviceid, pwdfactory.

Act 4: The Dock (Livestream Start)
- Goal: receive cmd 24631 and only then start the player.
- Evidence: startStream() waits for 24631 in SDK.
- Shot list:
  - Reorder: livestream.cgi -> wait cmd 24631 -> player.start().
  - Try substream values (1,2,4,100) if 24631 never appears.

Act 5: The Camera Rig (Playback Binding)
- Goal: verify the player is bound to the correct clientPtr and is receiving frames.
- Evidence: AppPlayerController uses a texture; frames are not exposed as raw bytes.
- Shot list:
  - Use screenshot() to confirm frames exist even if the texture is black.
  - Log progress/head info callbacks to confirm playback state.

Act 6: The Producer Notes (Cloud + Vendor Reality)
- Goal: confirm cloud endpoints are required for virtual IDs and provisioning.
- Evidence: getInitstring and vuid lookups are required for OKB IDs.
- Shot list:
  - Ensure the device and phone have internet connectivity during connect.
  - Cache initstring only after successful cloud resolution, but still connect in cloud mode for OKB.

Actionable Suggestions (Updated)
1) Treat 888888 as a valid default and test it, despite vendor feedback.
2) Temporarily allow empty passwords in AppP2PApi.clientLogin and test blank credentials (supported by CGI manual examples).
3) Use the real device ID (VSTH...) when possible to avoid false password errors tied to virtual IDs.
4) Use connectType=126 in the live-video connection path for virtual IDs.
5) Align with official flow: connect -> startStream (wait for 24631) -> player.start().
6) Always register command listener before login and parse cmd 24577 explicitly.
7) If the device was provisioned with a per-device password (random string), retrieve it from QR provisioning or vendor binding flow.

Notes
- These recommendations are based on the official SDK docs in docs/official_documentation and the current Flutter SDK code in flutter_veepa_module.
- This document is intended to preserve the rationale for the next test passes and minimize rework during troubleshooting.
