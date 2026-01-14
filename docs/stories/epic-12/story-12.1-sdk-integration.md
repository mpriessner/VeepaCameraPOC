# Story 12.1: Veepa SDK Integration

## Story
As a developer, I need to integrate the real Veepa SDK into the Flutter module to enable actual camera communication.

## Acceptance Criteria
- [ ] Veepa SDK (vsdk) package added to project
- [ ] Native libraries configured (libVSTC.a for iOS)
- [ ] SDK initialization working
- [ ] P2P API accessible
- [ ] Basic connection test passing

## Technical Details

### SDK Components
- `vsdk` Flutter package
- `libVSTC.a` - iOS native library (24.6 MB)
- `app_p2p_api.aar`, `app_player.aar` - Android libraries

### Integration Steps
1. Copy vsdk package from Veepaisdk repo
2. Add to pubspec.yaml as path dependency
3. Configure iOS native library linking
4. Initialize P2P API on app start
5. Verify SDK callbacks working

### Files to Create/Modify
- `flutter_veepa_module/pubspec.yaml` - add vsdk
- Copy SDK files from `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/`
- `ios_host_app/project.yml` - native library linking
- `flutter_veepa_module/lib/services/veepa_sdk_service.dart`

## Definition of Done
- [ ] SDK package integrated
- [ ] Native libraries linked
- [ ] SDK initializes without error
- [ ] P2P API instance created
- [ ] Code committed
