# Story 11.2: AP Mode Connection Flow

## Story
As a user, I need to connect my phone to the camera's WiFi access point for initial setup.

## Acceptance Criteria
- [ ] Instructions screen for AP mode connection
- [ ] Deep link to iOS WiFi settings
- [ ] Detection when connected to camera AP
- [ ] Automatic progression when AP detected
- [ ] Timeout handling if connection fails

## Technical Details

### User Flow
1. Show instructions: "Connect to camera WiFi"
2. Display expected SSID pattern
3. Button to open WiFi settings
4. Monitor for connection to camera AP
5. Auto-proceed when detected

### Implementation
1. Create `APConnectionScreen`
2. Create `WifiSettingsLauncher` utility
3. Polling/monitoring for AP connection
4. State machine for connection flow

### Files to Create/Modify
- `flutter_veepa_module/lib/screens/ap_connection_screen.dart`
- `flutter_veepa_module/lib/utils/wifi_settings_launcher.dart`
- `flutter_veepa_module/lib/services/ap_connection_monitor.dart`

## Definition of Done
- [ ] AP connection screen implemented
- [ ] WiFi settings launcher works on iOS
- [ ] AP detection triggers progression
- [ ] Timeout and retry handling
- [ ] Code committed
