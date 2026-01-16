# Epic: Video Streaming from Veepa Camera to Flutter App

**Epic ID**: VS-EPIC-001
**Created**: January 16, 2026
**Status**: Planning
**Priority**: High
**Location**: `/Users/mpriessner/windsurf_repos/VeepaCameraPOC/docs/stories/EPIC_VIDEO_STREAMING.md`

---

## Epic Overview

### Goal
Enable video streaming from Veepa camera to Flutter app, with the ability to display locally and forward to cloud services (Gemini) for AI analysis.

### Background
We have successfully established P2P connection to the camera with:
- ✅ Cached credentials (`clientId` + `serviceParam`)
- ✅ Default authentication (`admin`/`admin` on fresh/reset cameras)
- ✅ Direct P2P connection (`CONNECT_MODE_P2P`)
- ✅ Offline mode working (no internet needed after credential caching)

The connection is established. Now we need to receive and display the video stream.

### Architecture
```
┌──────────────┐     P2P Connection      ┌──────────────┐     Internet      ┌──────────────┐
│    Veepa     │◄───────────────────────►│   Flutter    │◄─────────────────►│   Gemini     │
│    Camera    │     Video Stream        │     App      │   Frame Analysis  │   Vision     │
└──────────────┘                         └──────────────┘                   └──────────────┘
       │                                        │
       └────────────── Same WiFi Network ───────┘
```

### Success Criteria
1. Live video stream displays in Flutter app
2. Stream works on local WiFi (camera + phone on same router)
3. Video frames can be captured and saved
4. Frames can be sent to Gemini for AI analysis
5. Latency under 500ms for live viewing

### SDK Components Available
Based on the Veepa SDK in our project:
- `AppP2PApi` - P2P connection (already working)
- `AppPlayerPlugin` - Video player (to be implemented)
- `CameraDevice` - High-level device management
- Native library: `libVSTC.a`

---

# Stories

---

## Story VS-001: Investigate SDK Video Player API

**Story ID**: VS-001
**Points**: 2
**Priority**: P0 - Critical Path
**Sprint**: 1
**Depends On**: None

### User Story
As a developer, I need to understand how the Veepa SDK handles video playback so that I can properly integrate video streaming into the Flutter app.

### Background
The Veepa SDK includes video playback capabilities through `AppPlayerPlugin`. Before implementing video display, we need to understand:
- What methods are available
- What video formats are supported
- How frames are delivered to the app
- What native views/textures are required

### Detailed Tasks

#### Task 1.1: Locate and read AppPlayerPlugin code
- [ ] Find `AppPlayerPlugin.h` and `AppPlayerPlugin.m` in the SDK folder
- [ ] Find corresponding Dart bindings in `lib/sdk/`
- [ ] Document all public methods with their signatures
- [ ] Identify initialization requirements

#### Task 1.2: Analyze the official SDK demo app
- [ ] Open `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/`
- [ ] Find where video playback is implemented
- [ ] Document the sequence of calls to start video
- [ ] Note any platform-specific code (iOS/Android)

#### Task 1.3: Document video format details
- [ ] Identify video codec (H.264, H.265, MJPEG)
- [ ] Identify resolution options (1080p, 720p, 480p, etc.)
- [ ] Identify frame rate
- [ ] Document any audio capabilities

#### Task 1.4: Document frame callback mechanism ⚠️ **PRIORITY #1**
> **Critical**: This determines feasibility of Gemini integration track (VS-007+)
- [ ] How does the SDK deliver video frames?
- [ ] Is it via native texture, platform view, or callbacks?
- [ ] **Can we access raw frame data (for Gemini)?** ← Must answer this
- [ ] What format are frames in (YUV, RGB, JPEG)?
- [ ] If GPU texture only: research methods to read back to CPU

#### Task 1.5: Investigate SDK threading model *(NEW - from feedback)*
- [ ] Does video player run on main UI thread or background thread?
- [ ] Are frame callbacks on main thread or separate thread?
- [ ] What are implications for Flutter widget rendering?
- [ ] Document threading requirements

#### Task 1.6: Check native library architecture *(NEW - from feedback)*
- [ ] Run `lipo -info libVSTC.a` to check supported architectures
- [ ] Determine if simulator testing is possible (x86_64/arm64-simulator)
- [ ] Document device-only testing requirement if applicable

#### Task 1.7: Create technical summary document
- [ ] Write up findings in a markdown file
- [ ] Include code snippets showing usage patterns
- [ ] List any limitations or concerns discovered
- [ ] **Explicitly state whether raw frame access is possible**

### Acceptance Criteria
- [ ] All public player methods documented with parameters and return types
- [ ] Video format and resolution options documented
- [ ] Frame delivery mechanism understood and documented
- [ ] Clear implementation plan written based on findings
- [ ] Technical summary saved to `docs/VIDEO_PLAYER_API.md`

### Testing
This is a research story - no app testing required. Deliverable is documentation.

### Output Location
`/Users/mpriessner/windsurf_repos/VeepaCameraPOC/docs/VIDEO_PLAYER_API.md`

### Estimated Time
2-3 hours of code reading and documentation

---

## Story VS-002: Add Video Player Widget to Test Screen

**Story ID**: VS-002
**Points**: 3
**Priority**: P0 - Critical Path
**Sprint**: 1
**Depends On**: VS-001

### User Story
As a user, I want to see a video display area on the test screen so that I have a place where the camera feed will appear.

### Background
Before we can display video, we need UI elements in place:
- A container/widget where video will render
- Controls to start/stop video
- Status indicators

### Detailed Tasks

#### Task 2.1: Design the video player UI layout
- [ ] Decide video area size (e.g., 16:9 aspect ratio)
- [ ] Position video above or below the log area
- [ ] Design loading/placeholder state
- [ ] Design error state

#### Task 2.2: Add video container widget with descriptive states *(Enhanced from feedback)*
- [ ] Create a `Container` with fixed aspect ratio (16:9)
- [ ] Add black background as placeholder
- [ ] Implement descriptive placeholder states:
  - "Ready to Connect" - Initial state
  - "Connecting..." - During P2P connection
  - "Authenticating..." - During login
  - "Starting Stream..." - After connection, before video
  - "Streaming" - When video is live
  - "Error: [message]" - On failure
- [ ] Add loading spinner for transitional states

#### Task 2.3: Add video control buttons
- [ ] Add "Start Video" button (green, with play icon)
- [ ] Add "Stop Video" button (red, with stop icon)
- [ ] Buttons should be disabled when not applicable
- [ ] Buttons placed below video area

#### Task 2.4: Add video status indicator
- [ ] Show current state: "Disconnected", "Connecting", "Streaming", "Error"
- [ ] Show resolution when streaming (e.g., "720p")
- [ ] Show frame rate if available (e.g., "15 fps")

#### Task 2.5: Wire up button actions to logging
- [ ] "Start Video" logs: `[timestamp] Starting video stream...`
- [ ] "Stop Video" logs: `[timestamp] Stopping video stream...`
- [ ] State changes logged: `[timestamp] Video state: Streaming`

### Acceptance Criteria
- [ ] Video placeholder area visible on P2P Test Screen
- [ ] Placeholder shows "No Video" text on black background
- [ ] Start Video button visible and tappable
- [ ] Stop Video button visible and tappable
- [ ] Buttons log their actions to the test log
- [ ] Video area maintains 16:9 aspect ratio

### Phone Testing Steps

1. **Build and run the app on iPhone**
2. **Navigate to P2P Test Screen**
3. **Verify video area visible:**
   - See black rectangle with "No Video" text
   - Rectangle should be ~16:9 aspect ratio
4. **Verify Start button:**
   - Tap "Start Video" button
   - See log entry: "Starting video stream..."
5. **Verify Stop button:**
   - Tap "Stop Video" button
   - See log entry: "Stopping video stream..."
6. **Verify status indicator:**
   - Shows "Disconnected" initially

### UI Mockup
```
┌─────────────────────────────────────┐
│         P2P Connection Test          │
├─────────────────────────────────────┤
│  Camera UID: OKB0379196OXYB         │
│  [Username: admin] [Password: ****] │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │         No Video            │    │  ← Video Area (16:9)
│  │                             │    │
│  └─────────────────────────────┘    │
│  Status: Disconnected               │
│                                     │
│  [▶ Start Video]  [⬛ Stop Video]   │  ← Control Buttons
├─────────────────────────────────────┤
│  [Fetch&Cache] [DirectLAN] [Offline]│
│  [Cloud P2P] [Full SDK Test]        │
├─────────────────────────────────────┤
│  Logs appear here...                │
│  ...                                │
└─────────────────────────────────────┘
```

### Technical Notes
- Use `AspectRatio(aspectRatio: 16/9, child: Container(...))` for video area
- Video buttons should be separate from connection buttons
- State management: add `_isVideoStreaming` boolean to state

### Files to Modify
- `lib/screens/p2p_test_screen.dart` - Add video UI widgets

---

## Story VS-003: Initialize Video Player After Connection

**Story ID**: VS-003
**Points**: 5
**Priority**: P0 - Critical Path
**Sprint**: 1
**Depends On**: VS-002

### User Story
As a user, when I tap "Start Video" after connecting to the camera, the video player should initialize and prepare to receive the video stream.

### Background
After the P2P connection is established (which we have working), we need to:
1. Create a video player instance
2. Associate it with the connected camera
3. Configure video parameters
4. Prepare the native rendering surface

### Detailed Tasks

#### Task 3.1: Import and access AppPlayerPlugin
- [ ] Verify `AppPlayerPlugin` Dart bindings exist
- [ ] Import into `p2p_test_screen.dart`
- [ ] Create player instance variable in state

#### Task 3.2: Create player after connection success
- [ ] After "SUCCESS" in connection, enable video buttons
- [ ] On "Start Video" tap, call player creation method
- [ ] Pass the client pointer from successful connection
- [ ] Log player creation result

#### Task 3.3: Configure video parameters
- [ ] Set video quality (start with default/medium)
- [ ] Set video resolution if configurable
- [ ] Set buffer size if configurable
- [ ] Log configuration values

#### Task 3.4: Create native rendering surface
- [ ] If using Texture: register texture with Flutter engine
- [ ] If using PlatformView: create native view controller
- [ ] Bind surface to player
- [ ] Log surface creation result

#### Task 3.5: Handle initialization errors
- [ ] Catch and display player creation errors
- [ ] Catch and display configuration errors
- [ ] Catch and display surface creation errors
- [ ] Show user-friendly error messages
- [ ] Log detailed error info for debugging

#### Task 3.6: Implement player state tracking
- [ ] Add enum: `VideoPlayerState { none, initializing, ready, playing, error }`
- [ ] Update state throughout initialization
- [ ] Update UI based on state
- [ ] Log state transitions

#### Task 3.7: Implement resource cleanup *(NEW - CRITICAL from feedback)*
> **Memory Leak Prevention**: Native SDK resources must be properly released
- [ ] Identify SDK cleanup method (`player.destroy()` or `player.dispose()`)
- [ ] Call cleanup in widget's `dispose()` method
- [ ] Call cleanup when "Stop Video" is pressed
- [ ] Test: Start/stop video 10+ times without memory growth
- [ ] Add `@override dispose()` with cleanup logging

#### Task 3.8: Ensure initialization idempotency *(NEW from feedback)*
> **Prevent duplicate players**: Tapping "Start Video" multiple times must be safe
- [ ] Check `_playerState` before creating new player
- [ ] If already initializing/ready/playing, ignore tap
- [ ] Disable button during initialization
- [ ] Log warning if duplicate start attempted

### Acceptance Criteria
- [ ] Video player initializes without crash after successful connection
- [ ] Player state logged: "initializing" → "ready" (or "error")
- [ ] Native rendering surface created
- [ ] Errors handled gracefully with user-visible message
- [ ] Start Video button only enabled after connection
- [ ] Status shows "Ready" after successful initialization

### Phone Testing Steps

1. **Connect to camera first:**
   - Reset camera (for admin/admin password)
   - Fetch & Cache credentials (if not cached)
   - Tap "Offline" with admin/admin
   - Wait for "SUCCESS" message

2. **Initialize video player:**
   - Tap "Start Video" button
   - Watch log for initialization messages

3. **Verify success case:**
   - Log shows: "Initializing video player..."
   - Log shows: "Player created with client pointer: XXXXX"
   - Log shows: "Video surface created"
   - Log shows: "Video player ready"
   - Status shows: "Ready"

4. **Verify error handling (disconnect camera to test):**
   - If camera disconnected, tap "Start Video"
   - Should see error message, not crash
   - Log shows error details

### Technical Notes
- Player needs the `clientPtr` from successful P2P connection
- Must store `clientPtr` in state after connection succeeds
- Player initialization may be async - handle appropriately
- Native texture ID needed for Flutter Texture widget

### Code Pattern (Expected)
```dart
// After connection success, store client pointer
int? _clientPtr;
int? _textureId;
VideoPlayerState _playerState = VideoPlayerState.none;

Future<void> _startVideo() async {
  if (_clientPtr == null) {
    _log('ERROR: Not connected');
    return;
  }

  setState(() => _playerState = VideoPlayerState.initializing);
  _log('Initializing video player...');

  try {
    // Create player
    final player = await AppPlayerPlugin.create(_clientPtr!);
    _log('Player created');

    // Create texture
    _textureId = await player.createTexture();
    _log('Texture created: $_textureId');

    setState(() => _playerState = VideoPlayerState.ready);
    _log('Video player ready');
  } catch (e) {
    setState(() => _playerState = VideoPlayerState.error);
    _log('ERROR: Failed to initialize player: $e');
  }
}
```

### Files to Modify
- `lib/screens/p2p_test_screen.dart` - Add player initialization logic

---

## Story VS-004: Display Live Video Stream

**Story ID**: VS-004
**Points**: 8
**Priority**: P0 - Critical Path
**Sprint**: 2
**Depends On**: VS-003

### User Story
As a user, I want to see live video from my camera displayed in the app so that I can view what the camera sees in real-time.

### Background
This is the KEY MILESTONE of the epic. Once video displays, we have proven end-to-end functionality:
- Connection ✅
- Authentication ✅
- Video stream reception ✅
- Video rendering ✅

### Detailed Tasks

#### Task 4.1: Start video stream from SDK
- [ ] Call the SDK method to begin streaming
- [ ] Pass quality/resolution parameters
- [ ] Handle stream start confirmation
- [ ] Log streaming start

#### Task 4.2: Receive video frames
- [ ] Set up frame callback/listener
- [ ] Receive first frame (log this milestone!)
- [ ] Track frame count and rate
- [ ] Log frame statistics periodically

#### Task 4.3: Render frames to Flutter Texture
- [ ] Bind texture ID to Texture widget
- [ ] Update texture with incoming frames
- [ ] Handle frame format conversion if needed
- [ ] Maintain proper frame timing

#### Task 4.4: Display video in UI
- [ ] Replace "No Video" placeholder with Texture widget
- [ ] Ensure video fills the container properly
- [ ] Handle aspect ratio correctly
- [ ] Add visual indicator that video is live

#### Task 4.5: Implement stop video
- [ ] Call SDK method to stop streaming
- [ ] Release texture resources
- [ ] Return to placeholder state
- [ ] Log stream stop

#### Task 4.6: Handle stream interruptions
- [ ] Detect if stream stops unexpectedly
- [ ] Show reconnection message
- [ ] Attempt automatic reconnection (optional)
- [ ] Update UI appropriately

#### Task 4.7: Handle color space conversion *(NEW from feedback)*
> **Potential bottleneck**: Camera frames often YUV, Flutter Texture may need RGB
- [ ] Identify frame format from SDK (YUV420, NV12, RGB, etc.)
- [ ] Determine if SDK handles conversion or we need to
- [ ] If manual conversion needed: implement efficiently (consider GPU shader)
- [ ] Benchmark: conversion should not exceed 5ms per frame

#### Task 4.8: Handle app lifecycle events *(NEW - CRITICAL from feedback)*
> **Common crash point**: P2P connections typically fail when app backgrounds
- [ ] Add `WidgetsBindingObserver` to widget
- [ ] On `paused` (background): pause video stream, log event
- [ ] On `resumed` (foreground): check connection, restart stream if needed
- [ ] On `detached` (terminated): cleanup resources
- [ ] Test: background app for 30 seconds, return, verify recovery

### Acceptance Criteria
- [ ] Live video from camera displays in the app
- [ ] Video updates continuously (not frozen frame)
- [ ] Can visually verify camera view (point at something recognizable)
- [ ] Frame rate logged and reasonable (>10 fps)
- [ ] Stop button stops the video and returns to placeholder
- [ ] No memory leaks (can start/stop multiple times)

### Phone Testing Steps

1. **Setup:**
   - Ensure camera is reset (admin/admin)
   - Ensure credentials are cached
   - Connect to camera with "Offline" button
   - See "SUCCESS"

2. **Start video stream:**
   - Tap "Start Video"
   - Watch log for initialization
   - Wait for "Video streaming started"

3. **Verify live video - CRITICAL TESTS:**

   **Test A: Movement**
   - Wave your hand in front of camera
   - Verify you see hand movement in app (< 1 second delay)

   **Test B: Time verification**
   - Point camera at a clock
   - Verify time shown matches actual time

   **Test C: Self verification**
   - Point camera at yourself
   - Verify you see yourself

   **Test D: Color verification**
   - Point camera at something colorful
   - Verify colors are accurate

4. **Verify frame rate:**
   - Log should show frame statistics
   - Expect 10-30 fps depending on quality

5. **Stop video:**
   - Tap "Stop Video"
   - Video should stop
   - Placeholder should return
   - No crash, no frozen frame

6. **Restart video:**
   - Tap "Start Video" again
   - Video should resume
   - Verify no memory issues (repeat 3-5 times)

### Visual Verification Checklist
| Test | Expected | Pass/Fail |
|------|----------|-----------|
| Video area shows live feed | Moving image, not static | |
| Hand wave visible | Movement within 1 second | |
| Clock time accurate | Matches real time ±2 sec | |
| Colors correct | Not too dark/bright/wrong | |
| Aspect ratio correct | No stretching/squishing | |
| Stop works | Returns to placeholder | |
| Restart works | Video resumes | |
| **Background/foreground** *(NEW)* | App recovers after 30s background | |

### Technical Notes
- This is the most complex story - may need debugging
- Frame rate depends on camera quality settings
- Network bandwidth affects quality
- Native texture binding is platform-specific

### Potential Issues and Solutions
| Issue | Solution |
|-------|----------|
| Black screen | Check texture binding, check frame callback |
| Frozen frame | Check frame update loop, check threading |
| Wrong colors | Check color space conversion (YUV→RGB) |
| Stretched video | Check aspect ratio handling |
| Low frame rate | Reduce quality, check network |
| Crash on start | Check null pointers, check initialization order |

### Files to Modify
- `lib/screens/p2p_test_screen.dart` - Video streaming logic
- Possibly platform-specific files for texture handling

---

## Story VS-005: Add Video Quality Controls

**Story ID**: VS-005
**Points**: 3
**Priority**: P1 - Important
**Sprint**: 2
**Depends On**: VS-004

### User Story
As a user, I want to adjust video quality so that I can balance between video clarity and network bandwidth usage.

### Background
Different use cases need different quality:
- High quality: When viewing details, good network
- Low quality: When bandwidth limited, viewing on small screen
- The camera likely supports multiple resolution/quality levels

### Detailed Tasks

#### Task 5.1: Identify available quality options
- [ ] Query SDK for supported quality levels
- [ ] Document each level (resolution, bitrate, fps)
- [ ] Determine default quality
- [ ] Log available options

#### Task 5.2: Create quality selector UI
- [ ] Add dropdown or segmented control
- [ ] Options: "Low (480p)", "Medium (720p)", "High (1080p)"
- [ ] Show current selection
- [ ] Place near video controls

#### Task 5.3: Implement quality change
- [ ] Call SDK method to change quality
- [ ] Handle quality change during active stream
- [ ] May need to restart stream for some changes
- [ ] Log quality changes

#### Task 5.4: Display current quality info
- [ ] Show resolution on screen (e.g., "1280x720")
- [ ] Show bitrate if available
- [ ] Show actual fps being received
- [ ] Update in real-time

### Acceptance Criteria
- [ ] At least 2 quality levels selectable
- [ ] Quality change takes effect (visible difference)
- [ ] Current quality displayed on screen
- [ ] Quality persists across stream stop/start
- [ ] Works without crash

### Phone Testing Steps

1. **Start video stream at default quality**
2. **Note current quality (should be shown)**
3. **Change to LOW quality:**
   - Select "Low" option
   - Video should become less sharp/smaller
   - Log shows: "Quality changed to 480p"
4. **Change to HIGH quality:**
   - Select "High" option
   - Video should become sharper/larger
   - Log shows: "Quality changed to 1080p"
5. **Verify quality indicator updates**
6. **Stop and restart - verify quality persists**

### UI Addition
```
┌─────────────────────────────────────┐
│  Video Area                         │
│  ┌─────────────────────────────┐    │
│  │      [Live Video Feed]      │    │
│  └─────────────────────────────┘    │
│  Resolution: 1280x720  FPS: 25      │
│  Quality: [Low ▼] [Medium] [High]   │  ← New quality selector
│  [▶ Start Video]  [⬛ Stop Video]   │
└─────────────────────────────────────┘
```

---

## Story VS-006: Capture Single Frame (Screenshot)

**Story ID**: VS-006
**Points**: 3
**Priority**: P1 - Important
**Sprint**: 2
**Depends On**: VS-004

### User Story
As a user, I want to capture a snapshot from the video stream so that I can save a still image of what the camera sees.

### Background
Capturing frames is essential for:
- Taking screenshots for records
- Sending to AI for analysis (next stories)
- Debugging video issues

### Detailed Tasks

#### Task 6.1: Add capture button to UI
- [ ] Add "📷 Capture" button near video controls
- [ ] Button only enabled during active streaming
- [ ] Visual feedback when pressed (flash effect)

#### Task 6.2: Extract current frame from stream
- [ ] Get raw frame data from player/texture
- [ ] Convert to standard image format (JPEG or PNG)
- [ ] Handle frame timing (capture cleanly)
- [ ] Log capture action

#### Task 6.3: Show thumbnail preview
- [ ] Display small preview of captured frame
- [ ] Show for 2-3 seconds after capture
- [ ] Show timestamp on thumbnail
- [ ] Fade out automatically

#### Task 6.4: Save to device photo library *(Enhanced from feedback)*
- [ ] **Show pre-prompt dialog before iOS permission** *(NEW)*
  - Display friendly dialog: "To save screenshots, this app needs access to your Photos"
  - Explain why permission is needed (increases grant rate)
  - Only then trigger native iOS permission dialog
- [ ] Request photo library permission
- [ ] **Save asynchronously** *(NEW)* - Don't block UI during save
- [ ] Show success/failure message
- [ ] Log save result

#### Task 6.5: Store in app memory for later use
- [ ] Keep last captured frame in memory
- [ ] Make available for Gemini analysis (later stories)
- [ ] Clear on new capture
- [ ] Show indicator that frame is available

### Acceptance Criteria
- [ ] Capture button visible during streaming
- [ ] Tapping capture extracts current frame
- [ ] Thumbnail preview shown briefly
- [ ] Image saved to device Photos app
- [ ] Can find and view image in Photos app
- [ ] Captured image is clear and correct

### Phone Testing Steps

1. **Start video stream**
2. **Point camera at something recognizable (your face, a sign, etc.)**
3. **Tap "Capture" button:**
   - See brief flash effect
   - See thumbnail preview appear
   - Log shows: "Frame captured: 1280x720"
4. **Verify thumbnail:**
   - Shows captured image
   - Disappears after 2-3 seconds
5. **Check Photos app:**
   - Open Photos app on iPhone
   - Find recently saved image
   - Verify it shows what camera was pointing at
6. **Repeat capture 3 times:**
   - All 3 images should save
   - No crashes

### Permission Note
First capture will prompt for Photos permission. User must "Allow" for save to work.

### UI Addition
```
│  [▶ Start Video]  [⬛ Stop]  [📷 Capture]  │
```

---

## Story VS-007: Extract Frame Data as Base64

**Story ID**: VS-007
**Points**: 3
**Priority**: P1 - Important
**Sprint**: 2
**Depends On**: VS-006

### User Story
As a developer, I need to convert captured frames to Base64 format so that I can send them to cloud APIs like Gemini Vision.

### Background
Cloud vision APIs (Gemini, GPT-4V, Claude) accept images as Base64-encoded strings. We need to:
- Convert image bytes to Base64
- Format appropriately for API calls
- Make data available for transmission

### Detailed Tasks

#### Task 7.1: Convert captured frame to Base64 *(Enhanced from feedback)*
> **Performance critical**: Encoding can cause UI jank if done on main thread
- [ ] Take captured frame image data
- [ ] **Resize image before encoding** *(NEW)* - 720p sufficient for AI analysis, reduces cost/latency
- [ ] **Run encoding in Isolate** *(NEW)* - Use `compute()` function to avoid UI freeze
- [ ] Encode as Base64 string
- [ ] Log Base64 length for verification
- [ ] Store in state for API use

#### Task 7.2: Display Base64 info in logs
- [ ] Log: "Frame encoded: [X] bytes → [Y] chars Base64"
- [ ] Log first 50 chars as preview (for debugging)
- [ ] Verify encoding is valid

#### Task 7.3: Add "Copy Base64" debug button
- [ ] Add button to copy Base64 to clipboard
- [ ] Show toast: "Copied to clipboard"
- [ ] Useful for manual API testing

#### Task 7.4: Validate Base64 data
- [ ] Decode Base64 back to image (in memory)
- [ ] Verify decoded image matches original
- [ ] Log validation result

#### Task 7.5: Implement background encoding helper *(NEW from feedback)*
```dart
// Example Isolate pattern for encoding
Future<String> encodeFrameInBackground(Uint8List frameData) async {
  return await compute(_encodeToBase64, frameData);
}

String _encodeToBase64(Uint8List data) {
  // Resize if needed, then encode
  return base64Encode(data);
}
```

### Acceptance Criteria
- [ ] Captured frame converted to Base64 string
- [ ] Base64 length logged (expect 50KB-500KB depending on quality)
- [ ] Can copy Base64 to clipboard
- [ ] Base64 decodes back to valid image

### Phone Testing Steps

1. **Capture a frame (from previous story)**
2. **Verify Base64 conversion:**
   - Log shows: "Frame encoded: 153,234 bytes → 204,312 chars Base64"
   - This confirms conversion worked
3. **Copy Base64:**
   - Tap "Copy Base64" button
   - See toast: "Copied to clipboard"
4. **Validate (optional advanced test):**
   - Paste Base64 into online decoder (base64decode.org)
   - Should show the captured image

### Technical Notes
- JPEG Base64 is smaller than PNG
- Typical size: 720p JPEG ≈ 100-200KB Base64
- Large Base64 strings may have clipboard limits

---

## Story VS-008: Send Frame to Gemini Vision API

**Story ID**: VS-008
**Points**: 5
**Priority**: P1 - Important
**Sprint**: 3
**Depends On**: VS-007

### User Story
As a user, I want to send a captured frame to Gemini AI so that I can get an intelligent description or analysis of what the camera sees.

### Background
Google's Gemini Vision API can analyze images and provide:
- Object detection and description
- Scene understanding
- Text recognition (OCR)
- Custom analysis based on prompts

This enables smart camera applications.

### Detailed Tasks

#### Task 8.1: Set up Gemini API configuration
- [ ] Create config file for API key
- [ ] Add API key input field in app (or use environment)
- [ ] Document how to get Gemini API key
- [ ] Handle missing API key gracefully

#### Task 8.2: Implement Gemini API client
- [ ] Add HTTP client (dio or http package)
- [ ] Implement Gemini Vision API endpoint
- [ ] Format request with Base64 image
- [ ] Add default prompt: "Describe what you see in this image"

#### Task 8.3: Add "Analyze with Gemini" button
- [ ] Add button near capture button
- [ ] Only enabled when frame is captured
- [ ] Show loading state during API call
- [ ] Disable during request

#### Task 8.4: Send frame and receive response
- [ ] Send Base64 image to Gemini
- [ ] Set timeout (30 seconds)
- [ ] Parse response
- [ ] Handle errors (rate limit, invalid key, etc.)

#### Task 8.5: Display Gemini response
- [ ] Show response text in dedicated area
- [ ] Handle long responses (scrollable)
- [ ] Show timestamp of analysis
- [ ] Log full response

### Acceptance Criteria
- [ ] Can configure Gemini API key
- [ ] "Analyze" button sends captured frame to Gemini
- [ ] Response displayed in app within 30 seconds
- [ ] Response makes sense for the image
- [ ] Errors handled with user-friendly messages

### Phone Testing Steps

1. **Setup:**
   - Obtain Gemini API key from Google AI Studio
   - Enter API key in app settings (or config)

2. **Capture and analyze:**
   - Start video stream
   - Point camera at a recognizable object (coffee cup, book, etc.)
   - Tap "Capture"
   - Tap "Analyze with Gemini"

3. **Verify response:**
   - Loading indicator appears
   - Within 10-30 seconds, response appears
   - Response describes what camera showed
   - Example: "The image shows a white coffee mug on a wooden desk"

4. **Test various objects:**

   | Point Camera At | Expected Response Contains |
   |-----------------|---------------------------|
   | Coffee cup | "cup", "mug", "coffee" |
   | Book | "book", title if visible |
   | Person | "person", "man"/"woman" |
   | Text/sign | Actual text content |
   | Empty room | "room", furniture description |

5. **Test error handling:**
   - Remove API key → should show "API key required"
   - Invalid API key → should show "Invalid API key"
   - No network → should show "Network error"

### API Key Note
```
To get a Gemini API key:
1. Go to https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key
4. Paste in app settings
```

### UI Addition
```
│  [📷 Capture]  [🤖 Analyze with Gemini]  │
│                                          │
│  Gemini says:                            │
│  ┌────────────────────────────────────┐  │
│  │ "The image shows a white coffee   │  │
│  │ mug sitting on a wooden desk.     │  │
│  │ The mug appears to be ceramic..." │  │
│  └────────────────────────────────────┘  │
```

---

## Story VS-009: Continuous Frame Analysis Mode

**Story ID**: VS-009
**Points**: 5
**Priority**: P2 - Nice to Have
**Sprint**: 3
**Depends On**: VS-008

### User Story
As a user, I want the app to automatically analyze frames at regular intervals so that I can get continuous AI monitoring without manual interaction.

### Background
For applications like:
- Security monitoring ("Alert me when person detected")
- Quality control ("Check if product is defective")
- Accessibility ("Describe surroundings continuously")

We need automated, continuous analysis.

### Detailed Tasks

#### Task 9.1: Add auto-analyze toggle
- [ ] Add switch/toggle: "Auto Analyze"
- [ ] When enabled, starts continuous mode
- [ ] When disabled, stops
- [ ] Save preference

#### Task 9.2: Implement interval timer
- [ ] Default interval: 5 seconds
- [ ] Make interval configurable (3s, 5s, 10s, 30s)
- [ ] Timer captures and sends frame automatically
- [ ] Cancel timer when toggled off

#### Task 9.3: Rate limiting and request overlap prevention *(Enhanced from feedback)*
> **Important**: If API takes longer than interval, don't overlap requests
- [ ] Track API calls per minute
- [ ] Respect Gemini rate limits
- [ ] Show warning if rate limited
- [ ] Pause auto-analysis if rate limited
- [ ] **Prevent request overlap** *(NEW)*:
  - Track if request is in-flight (`_isAnalyzing` flag)
  - Don't send new request until previous completes
  - Logic: "Wait for response, THEN wait interval, THEN send next"
  - NOT: "Send every N seconds regardless of response"

#### Task 9.4: Display rolling results
- [ ] Show last N analysis results (e.g., last 5)
- [ ] Each result timestamped
- [ ] Scrollable list
- [ ] Clear option

#### Task 9.5: Add optional alert conditions
- [ ] Basic keyword detection in response
- [ ] Example: Alert if "person" detected
- [ ] Visual/sound notification
- [ ] (Keep simple for MVP)

#### Task 9.6: Auto-pause on app background *(NEW from feedback)*
> **Resource management**: Don't waste API calls when user isn't watching
- [ ] Detect app entering background
- [ ] Automatically pause continuous analysis
- [ ] Resume when app returns to foreground (optional: ask user)
- [ ] Log pause/resume events

### Acceptance Criteria
- [ ] Auto-analyze toggle works
- [ ] Frames analyzed at selected interval
- [ ] Results accumulate in scrollable list
- [ ] Rate limits respected
- [ ] Can stop at any time
- [ ] Doesn't crash over extended period (5+ minutes)

### Phone Testing Steps

1. **Enable auto-analyze:**
   - Start video stream
   - Toggle "Auto Analyze" ON
   - Set interval to 5 seconds

2. **Observe automatic analysis:**
   - Every 5 seconds, see "Analyzing..."
   - New result appears
   - Results accumulate in list

3. **Change scene:**
   - Move camera to different objects
   - See descriptions change accordingly

4. **Verify timing:**
   - Use stopwatch to verify ~5 second intervals
   - May vary slightly due to API response time

5. **Disable and verify stop:**
   - Toggle "Auto Analyze" OFF
   - Analyses should stop
   - Existing results remain

6. **Extended test:**
   - Run for 5 minutes
   - Should continue working
   - Monitor for crashes or memory issues

### Cost Consideration
Continuous Gemini calls cost money. Add warning:
> "Auto-analysis sends frames to Gemini every X seconds. API charges may apply."

---

## Story VS-010: Shared WiFi Network Testing

**Story ID**: VS-010
**Points**: 3
**Priority**: P0 - Critical Path
**Sprint**: 3
**Depends On**: VS-004

### User Story
As a user, I want to stream video from my camera when both the camera and phone are connected to my home WiFi router so that I can have internet access while viewing the camera.

### Background
Two network configurations:
1. **Camera AP mode**: Phone connects to camera's WiFi → No internet on phone
2. **Shared WiFi**: Both connect to home router → Phone has internet

Option 2 is preferred for Gemini integration since phone needs internet.

### Detailed Tasks

#### Task 10.1: Configure camera on home WiFi
- [ ] Use official Veepa app to connect camera to home WiFi
- [ ] Note camera's IP on home network
- [ ] Verify camera online in official app

#### Task 10.2: Connect phone to same WiFi
- [ ] Connect iPhone to home WiFi (same as camera)
- [ ] Verify phone has internet (open browser)
- [ ] Note phone's IP

#### Task 10.3: Test P2P connection
- [ ] Use cached credentials
- [ ] Try "Offline" button
- [ ] Verify connection succeeds
- [ ] Log connection mode

#### Task 10.4: Test video streaming
- [ ] Start video stream
- [ ] Verify video displays
- [ ] Check latency (should be low on local network)
- [ ] Log frame rate

#### Task 10.5: Test simultaneous internet
- [ ] While video streaming, open Safari
- [ ] Verify can browse internet
- [ ] Try Gemini analysis while streaming
- [ ] Verify both work together

#### Task 10.6: Measure and document performance
- [ ] Measure video latency (time from movement to display)
- [ ] Measure Gemini response time
- [ ] Document any issues
- [ ] Compare to camera AP mode

#### Task 10.7: Test network transitions *(NEW from feedback)*
> **Edge case**: What happens if network changes during streaming?
- [ ] While streaming on WiFi, turn WiFi off on phone
- [ ] Verify app handles disconnection gracefully (no crash)
- [ ] Verify error message is shown
- [ ] Test reconnection after re-enabling WiFi
- [ ] Document behavior

### Future Enhancement Note *(from feedback)*
> **mDNS/Bonjour Discovery**: Currently the user needs to know the camera IP. Future work could use mDNS to auto-discover camera on local network, improving UX. Out of scope for this epic.

### Acceptance Criteria
- [ ] Camera connects to home WiFi router
- [ ] Phone connects to same WiFi
- [ ] P2P connection succeeds
- [ ] Video streams successfully
- [ ] Phone maintains internet access during streaming
- [ ] Can analyze frames with Gemini while streaming
- [ ] Latency acceptable (<500ms for video, <30s for Gemini)

### Phone Testing Steps

1. **Setup network:**
   - Connect camera to home WiFi (via official app)
   - Connect phone to same home WiFi
   - Verify phone has internet (load google.com)

2. **Setup camera:**
   - Reset camera to get admin/admin password
   - Or note password set in official app

3. **Connect from our app:**
   - Open VeepaPOC
   - Credentials should be cached
   - Tap "Offline" with admin/admin (or known password)
   - Verify "SUCCESS"

4. **Test video:**
   - Tap "Start Video"
   - Verify video displays
   - Wave hand - verify low latency

5. **Test internet simultaneous:**
   - While video playing, switch to Safari
   - Load a website
   - Switch back to app - video should still work
   - (May need split view or quick switch)

6. **Test Gemini integration:**
   - Capture frame while on shared WiFi
   - Tap "Analyze with Gemini"
   - Should work since phone has internet

7. **Document results:**
   - Video latency: _____ ms
   - Gemini response time: _____ seconds
   - Any issues: _____

### Network Diagram
```
┌──────────────────────────────────────────────────────────────┐
│                     Home WiFi Router                          │
│                    (e.g., 192.168.1.1)                        │
└───────────────┬──────────────────────────┬───────────────────┘
                │                          │
                │ WiFi                     │ WiFi
                │                          │
        ┌───────▼───────┐          ┌───────▼───────┐
        │    Veepa      │          │    iPhone     │
        │    Camera     │◄────────►│    (App)      │────► Internet
        │ 192.168.1.50  │  P2P     │ 192.168.1.100 │      (Gemini)
        └───────────────┘  Stream  └───────────────┘
```

### Important Note
After connecting camera to home WiFi, it may no longer broadcast its AP network. This is normal - you don't need the AP when using shared WiFi.

---

# Summary

## Story List

| ID | Story | Points | Priority | Sprint | Depends On |
|----|-------|--------|----------|--------|------------|
| VS-001 | Investigate SDK Video Player API | 2 | P0 | 1 | - |
| VS-002 | Add Video Player Widget to Test Screen | 3 | P0 | 1 | VS-001 |
| VS-003 | Initialize Video Player After Connection | 5 | P0 | 1 | VS-002 |
| VS-004 | Display Live Video Stream | 8 | P0 | 2 | VS-003 |
| VS-005 | Add Video Quality Controls | 3 | P1 | 2 | VS-004 |
| VS-006 | Capture Single Frame (Screenshot) | 3 | P1 | 2 | VS-004 |
| VS-007 | Extract Frame Data as Base64 | 3 | P1 | 2 | VS-006 |
| VS-008 | Send Frame to Gemini Vision API | 5 | P1 | 3 | VS-007 |
| VS-009 | Continuous Frame Analysis Mode | 5 | P2 | 3 | VS-008 |
| VS-010 | Shared WiFi Network Testing | 3 | P0 | 3 | VS-004 |

**Total Points**: 40

## Critical Path

```
VS-001 → VS-002 → VS-003 → VS-004 (KEY MILESTONE) → VS-010
                              ↓
                          VS-005
                          VS-006 → VS-007 → VS-008 → VS-009
```

## Sprint Plan

**Sprint 1 (Foundation)**: VS-001, VS-002, VS-003 = 10 points
**Sprint 2 (Video + Capture)**: VS-004, VS-005, VS-006, VS-007 = 17 points
**Sprint 3 (Cloud + Testing)**: VS-008, VS-009, VS-010 = 13 points

---

## File Locations

- **This Epic**: `/Users/mpriessner/windsurf_repos/VeepaCameraPOC/docs/stories/EPIC_VIDEO_STREAMING.md`
- **Main Analysis Doc**: `/Users/mpriessner/windsurf_repos/VeepaCameraPOC/docs/CAMERA_CONNECTION_ANALYSIS.md`
- **App Code**: `/Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/`
- **SDK Code**: `/Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/sdk/`

---

## Feedback Incorporation Log

### Review Date: January 16, 2026

This epic was reviewed by two AI assistants (Gemini and another). Below is a summary of their feedback and how it was incorporated:

#### Critical Changes Made

| Feedback | Source | Change Made |
|----------|--------|-------------|
| Raw frame access must be priority #1 | Both | VS-001 Task 1.4 marked as PRIORITY #1 |
| App lifecycle handling for P2P | Both | VS-004 Task 4.8 added |
| Resource cleanup (dispose) | Gemini | VS-003 Tasks 3.7, 3.8 added |
| Color space conversion | Gemini | VS-004 Task 4.7 added |
| Isolate for Base64 encoding | Gemini | VS-007 Task 7.1 enhanced, Task 7.5 added |
| Request overlap prevention | Gemini | VS-009 Task 9.3 enhanced |

#### Good Suggestions Incorporated

| Feedback | Change Made |
|----------|-------------|
| Descriptive placeholder states | VS-002 Task 2.2 enhanced |
| Permission pre-prompt dialog | VS-006 Task 6.4 enhanced |
| Image resizing before encoding | VS-007 Task 7.1 enhanced |
| Network transition testing | VS-010 Task 10.7 added |
| Check lipo -info for arch | VS-001 Task 1.6 added |
| Threading model investigation | VS-001 Task 1.5 added |
| Auto-pause on background | VS-009 Task 9.6 added |

#### Noted for Future (Out of Scope)

| Suggestion | Notes |
|------------|-------|
| mDNS/Bonjour for camera discovery | Future epic, noted in VS-010 |
| FFI for high-FPS frame passing | Only if EventChannel insufficient |

### Feedback Sources

- `docs/stories/EPIC_VIDEO_STREAMING_FEEDBACK.md` - Gemini feedback
- `docs/feedback_for_veepa_poc.md` - Second AI review

---

*Epic created: January 16, 2026*
*Author: Claude (AI Assistant)*
*Reviewed: January 16, 2026 (incorporated feedback from Gemini + second AI)*
*Status: Ready for implementation*
