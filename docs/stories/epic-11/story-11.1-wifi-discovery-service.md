# Story 11.1: WiFi Discovery Service

## Story
As a developer, I need a service to discover available WiFi networks and detect when connected to a Veepa camera's AP mode.

## Acceptance Criteria
- [ ] Detect current WiFi connection
- [ ] Identify if connected to Veepa camera AP (SSID pattern)
- [ ] List available WiFi networks (requires location permission on iOS)
- [ ] Monitor WiFi connection changes
- [ ] Platform channel for native WiFi APIs

## Technical Details

### Veepa AP Pattern
Camera AP SSIDs typically follow: `VEEPA_XXXXXX` or `VSTC_XXXXXX`

### Implementation
1. Create `WifiDiscoveryService` in Flutter
2. Create Swift `WifiManager` for native APIs
3. Platform channel for WiFi operations
4. Handle iOS/Android permission differences

### Files to Create/Modify
- `flutter_veepa_module/lib/services/wifi_discovery_service.dart`
- `ios_host_app/VeepaPOC/Services/WifiManager.swift`
- Platform channel integration
- `flutter_veepa_module/test/services/wifi_discovery_service_test.dart`

## iOS Specific
- Requires `NEHotspotHelper` or `NetworkExtension` for WiFi scanning
- Location permission required for SSID access
- Add entitlements for WiFi access

## Definition of Done
- [ ] WiFi discovery service implemented
- [ ] Camera AP detection works
- [ ] Platform channel working
- [ ] Tests passing
- [ ] Code committed
