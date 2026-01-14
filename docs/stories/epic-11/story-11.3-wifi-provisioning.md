# Story 11.3: WiFi Provisioning

## Story
As a user, I need to configure my camera to connect to my home WiFi network.

## Acceptance Criteria
- [ ] WiFi network selection UI
- [ ] Password input for selected network
- [ ] Send WiFi credentials to camera via CGI
- [ ] Monitor camera's WiFi connection status
- [ ] Success/failure feedback to user
- [ ] Camera reconnection after provisioning

## Technical Details

### CGI Commands
```
// Set WiFi credentials
set_wifi.cgi?ssid=MyNetwork&password=MyPassword&enctype=WPA2

// Check WiFi status
get_wifi_status.cgi
```

### User Flow
1. Show list of available networks
2. User selects their home WiFi
3. User enters password
4. App sends credentials to camera
5. Camera reboots and connects
6. App detects camera on home network

### Implementation
1. Create `WifiProvisioningScreen`
2. Create `CameraConfigService` for CGI commands
3. Create `WifiCredentialsForm` widget
4. Polling for camera on home network

### Files to Create/Modify
- `flutter_veepa_module/lib/screens/wifi_provisioning_screen.dart`
- `flutter_veepa_module/lib/services/camera_config_service.dart`
- `flutter_veepa_module/lib/widgets/wifi_credentials_form.dart`
- `flutter_veepa_module/test/services/camera_config_service_test.dart`

## Definition of Done
- [ ] WiFi selection UI implemented
- [ ] CGI commands for WiFi config
- [ ] Camera reconnection detection
- [ ] Error handling for failed provisioning
- [ ] Tests passing
- [ ] Code committed
