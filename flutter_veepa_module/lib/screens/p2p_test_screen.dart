import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/sdk/app_p2p_api.dart';
import 'package:veepa_camera_poc/sdk/app_player.dart';
import 'package:veepa_camera_poc/sdk/camera_device/camera_device.dart';
import 'package:veepa_camera_poc/sdk/camera_device/commands/status_command.dart';
import 'package:veepa_camera_poc/sdk/camera_device/commands/video_command.dart';
import 'package:veepa_camera_poc/sdk/camera_device/commands/wakeup_command.dart';
import 'package:veepa_camera_poc/sdk/p2p_device/p2p_device.dart';
import 'package:veepa_camera_poc/sdk/device_wakeup_server.dart';
import '../models/p2p_credentials.dart';
import '../services/p2p_credential_cache.dart';
import '../services/p2p_credential_fetcher.dart';

/// Video player state for UI
enum VideoPlayerState {
  disconnected,   // No connection
  connecting,     // P2P connecting
  authenticating, // Logging in
  ready,          // Connected, ready to stream
  starting,       // Starting video stream
  streaming,      // Video is playing
  error,          // Error occurred
}

class P2PTestScreen extends StatefulWidget {
  const P2PTestScreen({super.key});

  @override
  State<P2PTestScreen> createState() => _P2PTestScreenState();
}

class _P2PTestScreenState extends State<P2PTestScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _usernameController =
      TextEditingController(text: 'admin');
  final TextEditingController _passwordController =
      TextEditingController(text: 'admin');

  bool _isRunning = false;
  int? _clientPtr;

  // Video player state
  VideoPlayerState _videoState = VideoPlayerState.disconnected;
  AppPlayerController? _playerController;
  int? _textureId;
  String _videoStatusMessage = 'Not connected';

  // Active video connection tracking
  int? _videoClientPtr;  // Separate from test clientPtr - kept alive for video
  bool _isVideoConnected = false;
  CameraDevice? _cameraDevice;  // For video streaming with startStream()

  final String _cameraUID = 'OKB0379196OXYB';

  final P2PCredentialCache _cache = P2PCredentialCache();
  final P2PCredentialFetcher _fetcher = P2PCredentialFetcher();

  P2PCredentials? _cachedCredentials;
  bool _loadingCache = true;

  @override
  void initState() {
    super.initState();
    _loadCacheStatus();
  }

  @override
  void dispose() {
    // Clean up video resources
    _cleanupVideoConnection();
    _usernameController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Clean up video connection and player resources
  Future<void> _cleanupVideoConnection() async {
    _log('Cleaning up video resources...');

    // Stop and dispose player
    if (_playerController != null) {
      try {
        await _playerController!.stop();
        _playerController!.dispose();
        _log('  Player disposed');
      } catch (e) {
        _log('  Player cleanup error: $e');
      }
      _playerController = null;
    }

    // Disconnect CameraDevice
    if (_cameraDevice != null) {
      try {
        await _cameraDevice!.disconnect();
        _log('  CameraDevice disconnected');
      } catch (e) {
        _log('  CameraDevice cleanup error: $e');
      }
      _cameraDevice = null;
    }

    // Disconnect P2P client (if using low-level API)
    if (_videoClientPtr != null && _videoClientPtr != 0) {
      try {
        await AppP2PApi().clientDisconnect(_videoClientPtr!);
        await AppP2PApi().clientDestroy(_videoClientPtr!);
        _log('  P2P client destroyed');
      } catch (e) {
        _log('  P2P cleanup error: $e');
      }
      _videoClientPtr = null;
    }

    _isVideoConnected = false;
    _textureId = null;
  }

  Future<void> _loadCacheStatus() async {
    setState(() => _loadingCache = true);
    final credentials = await _cache.loadCredentials(_cameraUID);
    setState(() {
      _cachedCredentials = credentials;
      _loadingCache = false;
    });
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.add('[$timestamp] $message');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runTest() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _log('=== P2P CONNECTION TEST (Direct LAN) ===');
    _log('Camera UID: $_cameraUID');
    _log('');

    try {
      _log('Step 1: Getting P2P API instance...');
      final api = AppP2PApi();
      _log('  OK - API instance obtained');

      _log('');
      _log('Step 2: Creating P2P client...');
      _log('  Calling clientCreate("$_cameraUID")');

      _clientPtr = await api.clientCreate(_cameraUID);

      if (_clientPtr == null || _clientPtr == 0) {
        _log('  FAILED - clientCreate returned: $_clientPtr');
        _log('');
        _log('ERROR: Could not create P2P client');
        return;
      }

      _log('  OK - Client pointer: $_clientPtr');

      _log('');
      _log('Step 3: Attempting P2P connection...');
      _log('  lanScan: true (search local network)');
      _log('  serverParam: "" (empty - no cloud)');
      _log('  connectType: 63 (LAN mode)');
      _log('');
      _log('  Connecting... (this may take up to 20 seconds)');

      final connectState = await api
          .clientConnect(
            _clientPtr!,
            true,
            '',
            connectType: 63,
            p2pType: 0,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              _log('  TIMEOUT after 20 seconds');
              return ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT;
            },
          );

      _log('');
      _log('  Result: ${connectState.name}');

      _log('');
      _log('=== INTERPRETATION ===');
      switch (connectState) {
        case ClientConnectState.CONNECT_STATUS_ONLINE:
          _log('SUCCESS! Direct LAN connection works!');
          break;
        case ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT:
          _log('Connection timed out.');
          _log('Camera may not support direct LAN without serverParam.');
          break;
        case ClientConnectState.CONNECT_STATUS_INVALID_ID:
          _log('Invalid camera ID - may need cloud lookup.');
          break;
        case ClientConnectState.CONNECT_STATUS_OFFLINE:
          _log('Camera offline - may need cloud server.');
          break;
        default:
          _log('Status: ${connectState.name}');
      }
    } catch (e) {
      _log('');
      _log('EXCEPTION: $e');
    } finally {
      if (_clientPtr != null && _clientPtr != 0) {
        _log('');
        _log('Cleaning up...');
        try {
          await AppP2PApi().clientDisconnect(_clientPtr!);
          await AppP2PApi().clientDestroy(_clientPtr!);
          _log('  Client destroyed');
        } catch (e) {
          _log('  Cleanup error: $e');
        }
      }

      _log('');
      _log('=== TEST COMPLETE ===');

      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _fetchAndCache() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _log('=== FETCH & CACHE CREDENTIALS ===');
    _log('Camera UID: $_cameraUID');
    _log('');

    try {
      _log('Step 1: Fetching clientId from vuid.eye4.cn...');
      final result = await _fetcher.fetchAllCredentials(_cameraUID);

      if (!result.isSuccess) {
        _log('');
        _log('FAILED: ${result.error}');
        _log('Failed at step: ${result.failedStep}');
        _log('');
        _log('Make sure you have internet connectivity.');
        return;
      }

      final credentials = result.credentials!;
      _log('  OK - clientId: ${credentials.maskedClientId}');
      _log('');
      _log('Step 2: ServiceParam fetched successfully');
      _log('  OK - serviceParam: ${credentials.maskedServiceParam}');

      if (credentials.supplier != null) {
        _log('  Supplier: ${credentials.supplier}');
      }
      if (credentials.cluster != null) {
        _log('  Cluster: ${credentials.cluster}');
      }

      _log('');
      _log('Step 3: Saving to local cache...');

      final saved = await _cache.saveCredentials(credentials);
      if (saved) {
        _log('  OK - Credentials cached successfully!');
        await _loadCacheStatus();
      } else {
        _log('  FAILED - Could not save to cache');
      }

      _log('');
      _log('=== FETCH COMPLETE ===');
      _log('');
      _log('You can now test offline P2P connection');
      _log('using "Test with Cache" button.');
    } catch (e) {
      _log('');
      _log('EXCEPTION: $e');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _testWithCache() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _log('=== TEST WITH CACHED CREDENTIALS ===');
    _log('Camera UID: $_cameraUID');
    _log('');

    final credentials = await _cache.loadCredentials(_cameraUID);

    if (credentials == null) {
      _log('ERROR: No cached credentials found');
      _log('');
      _log('Please fetch credentials first (requires internet)');
      _log('Use the "Fetch & Cache" button.');
      setState(() => _isRunning = false);
      return;
    }

    _log('Loaded cached credentials:');
    _log('  cameraUid: ${credentials.cameraUid}');
    _log('  clientId (FULL): ${credentials.clientId}');
    _log('  serviceParam (FULL): ${credentials.serviceParam}');
    _log('  supplier: ${credentials.supplier}');
    _log('  cluster: ${credentials.cluster}');
    _log('  cached: ${credentials.cacheAgeDescription}');
    _log('');

    int? clientPtr;
    try {
      _log('Step 1: Creating P2P client...');
      _log('  Using REAL clientId (not virtual UID)');
      clientPtr = await AppP2PApi().clientCreate(credentials.clientId);

      if (clientPtr == null || clientPtr == 0) {
        _log('  FAILED - Could not create client');
        return;
      }
      _log('  OK - Client pointer: $clientPtr');

      _log('');
      _log('Step 2: P2P Connection...');
      _log('  lanScan: true');
      _log('  serviceParam: (from cache)');
      _log('  connectType: 63 (LAN mode)');
      _updateVideoState(VideoPlayerState.connecting, 'Connecting to camera...');

      final connectResult = await AppP2PApi()
          .clientConnect(
            clientPtr,
            true,
            credentials.serviceParam,
            connectType: 63,
            p2pType: 0,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT,
          );

      _log('  Result: ${connectResult.name}');

      if (connectResult != ClientConnectState.CONNECT_STATUS_ONLINE) {
        _log('');
        _log('ERROR: P2P connection failed');
        _log('Cached credentials may be invalid or expired');
        return;
      }

      _log('');
      _log('Step 3: Login to camera...');
      _updateVideoState(VideoPlayerState.authenticating, 'Logging in...');
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      final actualUser = username.isEmpty ? 'admin' : username;
      final actualPass = password;  // Send exactly what user entered (even if empty)
      _log('  username: $actualUser');
      _log('  password: "${actualPass}" ${actualPass.isEmpty ? "(empty string)" : ""}');

      final loginResult = await AppP2PApi().clientLogin(
        clientPtr,
        actualUser,
        actualPass,
      );

      _log('  Login result: $loginResult');

      if (!loginResult) {
        _log('');
        _log('ERROR: Login failed - try password "admin"');
        _updateVideoState(VideoPlayerState.error, 'Login failed');
        return;
      }

      _log('');
      _log('Step 4: Checking connection mode...');
      final modeResult = await AppP2PApi().clientCheckMode(clientPtr);
      _log('  Mode: ${modeResult.mode.name}');

      if (modeResult.mode == ClientConnectMode.CONNECT_MODE_P2P) {
        _log('  DIRECT P2P CONNECTION!');
      } else if (modeResult.mode == ClientConnectMode.CONNECT_MODE_RELAY) {
        _log('  Using cloud relay (not direct)');
      }

      _log('');
      _log('=== SUCCESS ===');
      _log('Camera connected with cached credentials!');
      _log('Offline P2P connection is WORKING!');
      _updateVideoState(VideoPlayerState.ready, 'Connected - Ready to stream');
    } catch (e) {
      _log('');
      _log('EXCEPTION: $e');
      _updateVideoState(VideoPlayerState.error, 'Connection error');
    } finally {
      if (clientPtr != null && clientPtr != 0) {
        _log('');
        _log('Cleaning up...');
        await AppP2PApi().clientDisconnect(clientPtr);
        await AppP2PApi().clientDestroy(clientPtr);
        _log('  Client destroyed');
        // Reset video state since we disconnected
        _updateVideoState(VideoPlayerState.disconnected, 'Connection closed');
      }
      _log('');
      _log('=== TEST COMPLETE ===');
      setState(() => _isRunning = false);
    }
  }

  Future<void> _testWithCloud() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _log('=== TEST WITH CLOUD (connectType: 126) ===');
    _log('Camera UID: $_cameraUID');
    _log('This test uses cloud-assisted P2P connection.');
    _log('');

    final credentials = await _cache.loadCredentials(_cameraUID);

    if (credentials == null) {
      _log('ERROR: No cached credentials found');
      _log('Please fetch credentials first.');
      setState(() => _isRunning = false);
      return;
    }

    _log('Using cached credentials:');
    _log('  clientId: ${credentials.maskedClientId}');
    _log('  serviceParam: ${credentials.maskedServiceParam}');
    _log('');

    int? clientPtr;
    try {
      _log('Step 1: Creating P2P client...');
      clientPtr = await AppP2PApi().clientCreate(credentials.clientId);

      if (clientPtr == null || clientPtr == 0) {
        _log('  FAILED - Could not create client');
        return;
      }
      _log('  OK - Client pointer: $clientPtr');

      _log('');
      _log('Step 2: P2P Connection (CLOUD MODE)...');
      _log('  lanScan: true');
      _log('  serviceParam: (from cache)');
      _log('  connectType: 126 (CLOUD P2P mode)');
      _log('  Connecting... (may take 20+ seconds)');

      final connectResult = await AppP2PApi()
          .clientConnect(
            clientPtr,
            true,
            credentials.serviceParam,
            connectType: 126,
            p2pType: 0,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT,
          );

      _log('  Result: ${connectResult.name}');

      if (connectResult != ClientConnectState.CONNECT_STATUS_ONLINE) {
        _log('');
        _log('ERROR: P2P connection failed');
        if (connectResult == ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT) {
          _log('Timeout - check internet connectivity');
        }
        return;
      }

      _log('');
      _log('Step 3: Login to camera...');
      final password = _passwordController.text.trim();
      _log('  username: admin');
      _log('  password: ${password.isEmpty ? "(empty)" : "****"}');

      final loginResult = await AppP2PApi().clientLogin(
        clientPtr,
        'admin',
        password.isEmpty ? 'admin' : password,
      );

      _log('  Login result: $loginResult');

      if (!loginResult) {
        _log('');
        _log('ERROR: Login failed');
        _log('Check if password is correct');
        return;
      }

      _log('');
      _log('Step 4: Checking connection mode...');
      final modeResult = await AppP2PApi().clientCheckMode(clientPtr);
      _log('  Mode: ${modeResult.mode.name}');

      if (modeResult.mode == ClientConnectMode.CONNECT_MODE_P2P) {
        _log('  Direct P2P tunnel established!');
      } else if (modeResult.mode == ClientConnectMode.CONNECT_MODE_RELAY) {
        _log('  Using cloud relay');
      }

      _log('');
      _log('=== SUCCESS ===');
      _log('Camera connected via cloud!');
      _log('Connection is ready for video streaming.');
    } catch (e) {
      _log('');
      _log('EXCEPTION: $e');
    } finally {
      if (clientPtr != null && clientPtr != 0) {
        _log('');
        _log('Cleaning up...');
        await AppP2PApi().clientDisconnect(clientPtr);
        await AppP2PApi().clientDestroy(clientPtr);
        _log('  Client destroyed');
      }
      _log('');
      _log('=== TEST COMPLETE ===');
      setState(() => _isRunning = false);
    }
  }

  Future<void> _testWithCameraDevice() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _log('=== TEST WITH CAMERADEVICE CLASS ===');
    _log('This uses the high-level SDK class like the official app.');
    _log('');

    CameraDevice? device;
    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      final user = username.isEmpty ? 'admin' : username;
      final pwd = password.isEmpty ? 'admin' : password;

      _log('Step 1: Creating CameraDevice...');
      _log('  UID: $_cameraUID');
      _log('  Username: $user');
      _log('  Password: ****');

      device = CameraDevice(_cameraUID, 'TestCamera', user, pwd, 'QW6-T');
      _log('  OK - CameraDevice created');

      _log('');
      _log('Step 2: Getting client pointer...');
      await device.getClientPtr();
      _log('  OK - Client pointer obtained');

      _log('');
      _log('Step 3: Setting up listeners (like official SDK)...');

      // Remove any old listeners first (idempotent)
      device.removeListener(_statusListener);
      device.removeListener(_connectStateListener);
      device.removeListener(_wakeupStateListener);

      // Add listeners before connect (required by SDK)
      device.addListener<StatusChanged>(_statusListener);
      device.addListener<CameraConnectChanged>(_connectStateListener);
      device.addListener<WakeupStateChanged>(_wakeupStateListener);
      _log('  OK - Listeners registered');

      _log('');
      _log('Step 4: Connecting (this handles everything internally)...');
      _log('  - Fetches service params from cloud');
      _log('  - Selects connect type');
      _log('  - Performs P2P connection');
      _log('  - Logs in automatically');
      _log('  Connecting... (may take 45+ seconds)');

      final connectState = await device.connect().timeout(
        const Duration(seconds: 60),
        onTimeout: () => CameraConnectState.timeout,
      );

      _log('');
      _log('  Result: ${connectState.name}');

      // Manually trigger state listeners like official SDK does
      _connectStateListener(device, connectState);
      _wakeupStateListener(device, device.wakeupState);

      _log('');
      _log('Step 5: Requesting wakeup status...');
      device.requestWakeupStatus();
      _log('  OK - Wakeup status requested');

      if (connectState == CameraConnectState.connected) {
        _log('');
        _log('Step 6: Verifying connection with getParams...');
        final params = await device.getParams(cache: false);
        if (params != null) {
          _log('  OK - getParams succeeded');
        } else {
          _log('  WARNING - getParams returned null');
        }

        _log('');
        _log('=== SUCCESS ===');
        _log('Camera connected using CameraDevice class!');
        _log('');
        _log('Getting device status...');
        final status = await device.getStatus(cache: false);
        if (status != null) {
          _log('  P2P Status: ${status.p2pstatus}');
          _log('  Battery: ${status.batteryRate}%');
        }
      } else {
        _log('');
        _log('ERROR: Connection failed');
        switch (connectState) {
          case CameraConnectState.timeout:
            _log('Timeout - camera may be offline or unreachable');
            _log('');
            _log('Possible causes:');
            _log('  1. Camera not registered in official app');
            _log('  2. Camera is in sleep/deep sleep mode');
            _log('  3. Network connectivity issues');
            _log('  4. Firewall blocking P2P traffic');
            break;
          case CameraConnectState.password:
            _log('Wrong password');
            break;
          case CameraConnectState.offline:
            _log('Camera is offline');
            break;
          case CameraConnectState.maxUser:
            _log('Max users reached');
            break;
          default:
            _log('State: ${connectState.name}');
        }
      }
    } catch (e) {
      _log('');
      _log('EXCEPTION: $e');
    } finally {
      if (device != null) {
        _log('');
        _log('Cleaning up...');
        device.removeListener(_statusListener);
        device.removeListener(_connectStateListener);
        device.removeListener(_wakeupStateListener);
        await device.disconnect();
        _log('  Disconnected and listeners removed');
      }
      _log('');
      _log('=== TEST COMPLETE ===');
      setState(() => _isRunning = false);
    }
  }

  // Listener callbacks matching official SDK pattern
  void _statusListener(P2PBasisDevice device, StatusResult? result) {
    if (result == null) return;
    _log('  [Status] P2P: ${result.p2pstatus}, Battery: ${result.batteryRate}%');
  }

  void _connectStateListener(CameraDevice device, CameraConnectState state) {
    _log('  [ConnectState] ${state.name}');
  }

  void _wakeupStateListener(P2PBasisDevice device, DeviceWakeupState? state) {
    if (state != null) {
      _log('  [WakeupState] ${state.name}');
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will remove cached credentials.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cache.clearCredentials(_cameraUID);
      await _loadCacheStatus();
      _log('Cache cleared');
    }
  }

  Future<void> _showManualEntryDialog() async {
    final clientIdController = TextEditingController();
    final serviceParamController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Credential Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter credentials obtained from Veepa or network capture:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: clientIdController,
                decoration: const InputDecoration(
                  labelText: 'Client ID (real device ID)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: serviceParamController,
                decoration: const InputDecoration(
                  labelText: 'Service Parameter (initstring)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final clientId = clientIdController.text.trim();
      final serviceParam = serviceParamController.text.trim();

      if (clientId.isEmpty || serviceParam.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Both fields are required')),
          );
        }
        return;
      }

      final credentials = P2PCredentials(
        cameraUid: _cameraUID,
        clientId: clientId,
        serviceParam: serviceParam,
        cachedAt: DateTime.now(),
      );

      final validationError = credentials.validate();
      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid: $validationError')),
          );
        }
        return;
      }

      await _cache.saveCredentials(credentials);
      await _loadCacheStatus();
      _log('Manual credentials saved to cache');
    }
  }

  /// VS-001 Smoke Test: Verify Video Player SDK is accessible
  Future<void> _testVideoPlayerSDK() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _log('=== VIDEO PLAYER SDK SMOKE TEST ===');
    _log('Testing if video player can be instantiated...');
    _log('');

    try {
      // Test 1: Create AppPlayerController
      _log('Step 1: Creating AppPlayerController...');
      final controller = AppPlayerController(
        changeCallback: (userData, videoStatus, voiceStatus, recordStatus, touchType) {
          _log('  Callback received: video=$videoStatus, voice=$voiceStatus');
        },
      );
      _log('  OK - Controller created');

      // Test 2: Call create() to get textureId
      _log('');
      _log('Step 2: Calling controller.create()...');
      final created = await controller.create();
      _log('  Result: $created');
      _log('  textureId: ${controller.textureId}');
      _log('  playerId: ${controller.playerId}');
      _log('  isCreated: ${controller.isCreated}');

      if (created && controller.textureId > 0) {
        _log('');
        _log('SUCCESS! Video Player SDK is working.');
        _log('');
        _log('Available video source types:');
        _log('  - LiveVideoSource(clientPtr) for live streaming');
        _log('  - FileVideoSource(path) for file playback');
        _log('');
        _log('Key methods available:');
        _log('  - setVideoSource()');
        _log('  - start() / stop() / pause() / resume()');
        _log('  - screenshot(filePath) for frame capture');
        _log('  - dispose() for cleanup');
      } else {
        _log('');
        _log('WARNING: create() returned $created but textureId=${controller.textureId}');
      }

      // Test 3: Cleanup
      _log('');
      _log('Step 3: Disposing controller...');
      controller.dispose();
      _log('  OK - Controller disposed');

      _log('');
      _log('=== SMOKE TEST COMPLETE ===');
    } catch (e, stackTrace) {
      _log('');
      _log('ERROR: $e');
      _log('Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      _log('');
      _log('This might mean:');
      _log('  - Native library not linked properly');
      _log('  - Running on simulator (arm64 only)');
      _log('  - Missing SDK initialization');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  /// Build the video player area with placeholder/video display
  Widget _buildVideoPlayer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 140, // Video player height
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: _buildVideoContent(),
    );
  }

  Widget _buildVideoContent() {
    // If we have a valid texture and are streaming, show the video
    // Note: textureId 0 is valid in Flutter
    if (_videoState == VideoPlayerState.streaming && _textureId != null) {
      return Texture(textureId: _textureId!);
    }

    // Otherwise show placeholder with status
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildVideoStateIcon(),
            const SizedBox(height: 12),
            Text(
              _getVideoStateLabel(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_videoStatusMessage.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _videoStatusMessage,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoStateIcon() {
    switch (_videoState) {
      case VideoPlayerState.disconnected:
        return Icon(Icons.videocam_off, size: 48, color: Colors.grey.shade600);
      case VideoPlayerState.connecting:
      case VideoPlayerState.authenticating:
      case VideoPlayerState.starting:
        return const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            color: Colors.white54,
            strokeWidth: 3,
          ),
        );
      case VideoPlayerState.ready:
        return Icon(Icons.play_circle_outline, size: 48, color: Colors.green.shade400);
      case VideoPlayerState.streaming:
        return Icon(Icons.fiber_manual_record, size: 48, color: Colors.red.shade400);
      case VideoPlayerState.error:
        return Icon(Icons.error_outline, size: 48, color: Colors.red.shade400);
    }
  }

  String _getVideoStateLabel() {
    switch (_videoState) {
      case VideoPlayerState.disconnected:
        return 'No Video';
      case VideoPlayerState.connecting:
        return 'Connecting...';
      case VideoPlayerState.authenticating:
        return 'Authenticating...';
      case VideoPlayerState.ready:
        return 'Ready to Stream';
      case VideoPlayerState.starting:
        return 'Starting Stream...';
      case VideoPlayerState.streaming:
        return 'Live';
      case VideoPlayerState.error:
        return 'Error';
    }
  }

  /// Mini button for compact test button row
  Widget _miniButton(String label, Color color, VoidCallback? onPressed) {
    return Expanded(
      child: SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            textStyle: const TextStyle(fontSize: 11),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  /// Build compact debug info panel
  Widget _buildVideoDebugInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${_videoState.name} | ptr: ${_videoClientPtr ?? "-"} | tex: ${_textureId ?? "-"} | $_videoStatusMessage',
        style: TextStyle(
          color: _videoState == VideoPlayerState.error
              ? Colors.red.shade300
              : Colors.grey.shade400,
          fontSize: 10,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Build video control buttons
  Widget _buildVideoControls() {
    final bool isDisconnected = _videoState == VideoPlayerState.disconnected;
    final bool canConnect = isDisconnected && !_isRunning;
    final bool canDisconnect = _isVideoConnected;
    final bool canStart = _videoState == VideoPlayerState.ready;
    final bool canStop = _videoState == VideoPlayerState.streaming ||
                         _videoState == VideoPlayerState.starting;
    final bool isConnecting = _videoState == VideoPlayerState.connecting ||
                              _videoState == VideoPlayerState.authenticating;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Connect / Disconnect row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canConnect ? _connectForVideo : null,
                  icon: isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.link, size: 18),
                  label: Text(isConnecting ? 'Connecting...' : 'Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canDisconnect ? _disconnectVideo : null,
                  icon: const Icon(Icons.link_off, size: 18),
                  label: const Text('Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Start / Stop row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canStart && !_isRunning ? _startVideo : null,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canStop ? _stopVideo : null,
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Stop Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Connect to camera and prepare for video streaming using low-level P2P API
  Future<void> _connectForVideo() async {
    if (_isRunning || _isVideoConnected) return;

    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _log('=== CONNECT FOR VIDEO ===');
    _log('Camera UID: $_cameraUID');
    _log('');

    final credentials = await _cache.loadCredentials(_cameraUID);

    if (credentials == null) {
      _log('ERROR: No cached credentials found');
      _log('Use "Fetch & Cache" first (requires internet)');
      _updateVideoState(VideoPlayerState.error, 'No credentials');
      setState(() => _isRunning = false);
      return;
    }

    final password = _passwordController.text.trim();
    final actualPass = password.isEmpty ? 'admin' : password;

    _log('Using cached credentials...');
    _log('  clientId: ${credentials.maskedClientId}');
    _updateVideoState(VideoPlayerState.connecting, 'Connecting...');

    try {
      // Step 1: Create P2P client with cached clientId
      _log('');
      _log('Step 1: Creating P2P client...');
      final clientPtr = await AppP2PApi().clientCreate(credentials.clientId);

      if (clientPtr == null || clientPtr == 0) {
        _log('  FAILED - Could not create client');
        _updateVideoState(VideoPlayerState.error, 'Client create failed');
        setState(() => _isRunning = false);
        return;
      }
      _log('  OK - clientPtr: $clientPtr');
      _videoClientPtr = clientPtr;

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
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT,
          );

      _log('  Result: ${connectResult.name}');

      if (connectResult != ClientConnectState.CONNECT_STATUS_ONLINE) {
        _log('  ERROR: P2P connection failed');
        _updateVideoState(VideoPlayerState.error, 'P2P connect failed');
        await _cleanupVideoConnection();
        return;
      }

      // Step 3: Login
      _log('');
      _log('Step 3: Logging in...');
      _updateVideoState(VideoPlayerState.authenticating, 'Authenticating...');

      final loginResult = await AppP2PApi().clientLogin(
        clientPtr,
        'admin',
        actualPass,
      );
      _log('  Login: $loginResult');

      if (!loginResult) {
        _log('  ERROR: Login failed');
        _updateVideoState(VideoPlayerState.error, 'Login failed');
        await _cleanupVideoConnection();
        return;
      }

      // Step 3b: Set up command listener (like CameraDevice does)
      _log('  Setting up command listener...');
      AppP2PApi().setCommandListener(clientPtr, _onCameraCommand);

      // Step 4: Create Video Player
      _log('');
      _log('Step 4: Creating video player...');

      _playerController = AppPlayerController(
        changeCallback: (userData, videoStatus, voiceStatus, recordStatus, touchType) {
          _log('  Player status: $videoStatus');
          if (videoStatus == VideoStatus.PLAY && mounted) {
            setState(() {
              _textureId = _playerController?.textureId;
            });
          }
        },
      );

      final created = await _playerController!.create();
      _log('  Player created: $created');
      _log('  textureId: ${_playerController!.textureId}');

      if (!created) {
        _log('  ERROR: Player creation failed');
        _updateVideoState(VideoPlayerState.error, 'Player failed');
        await _cleanupVideoConnection();
        return;
      }

      // Step 5: Set video source
      _log('');
      _log('Step 5: Setting video source...');
      final videoSource = LiveVideoSource(_videoClientPtr!);
      final sourceSet = await _playerController!.setVideoSource(videoSource);
      _log('  Video source set: $sourceSet');

      if (!sourceSet) {
        _log('  ERROR: Could not set video source');
        _updateVideoState(VideoPlayerState.error, 'Source failed');
        await _cleanupVideoConnection();
        return;
      }

      // Success!
      _isVideoConnected = true;
      _textureId = _playerController!.textureId;

      _log('');
      _log('=== CONNECTED ===');
      _log('clientPtr: $_videoClientPtr');
      _log('textureId: $_textureId');
      _log('Ready to stream video!');

      _updateVideoState(VideoPlayerState.ready, 'Ready - Tap Start Video');

    } catch (e) {
      _log('');
      _log('EXCEPTION: $e');
      _updateVideoState(VideoPlayerState.error, 'Connection error');
      await _cleanupVideoConnection();
    } finally {
      setState(() => _isRunning = false);
    }
  }


  /// Start video streaming (requires connection first)
  Future<void> _startVideo() async {
    if (!_isVideoConnected || _playerController == null || _videoClientPtr == null) {
      _log('ERROR: Not connected. Use "Connect" first.');
      return;
    }

    _log('Starting video stream...');
    _updateVideoState(VideoPlayerState.starting, 'Starting stream...');

    try {
      // Add callbacks BEFORE starting (to catch early events)
      _playerController!.addProgressChangeCallback(_onVideoProgress);
      _playerController!.addHeadInfoCallback(_onHeadInfo);
      _frameCount = 0;

      // Step 1: Send livestream CGI FIRST (tell camera to start sending)
      // Use substream=4 (low/480p) for faster initial streaming
      _log('  Step 1: Sending livestream CGI (low res)...');
      final cgiResult = await AppP2PApi().clientWriteCgi(
        _videoClientPtr!,
        'livestream.cgi?streamid=10&substream=4&',
      );
      _log('  CGI result: $cgiResult');

      // Step 2: Wait for camera to start preparing stream
      _log('  Step 2: Waiting for camera...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 3: Start the player
      _log('  Step 3: Starting player...');
      final started = await _playerController!.start();
      _log('  Player started: $started');

      if (!started) {
        _log('  ERROR: Player failed to start');
        _updateVideoState(VideoPlayerState.error, 'Player start failed');
        return;
      }

      // Step 4: Start voice (some cameras need audio channel open)
      _log('  Step 4: Starting voice...');
      await _playerController!.startVoice();

      setState(() {
        _textureId = _playerController!.textureId;
      });

      _updateVideoState(VideoPlayerState.streaming, 'Live');
      _log('');
      _log('=== STREAMING ===');
      _log('textureId: $_textureId');
      _log('Frames should appear below...');
    } catch (e) {
      _log('ERROR: $e');
      _updateVideoState(VideoPlayerState.error, 'Stream error');
    }
  }

  int _frameCount = 0;

  void _onVideoProgress(dynamic userData, int totalSec, int playSec,
      int progress, int loadState, int velocity, int timestamp) {
    _frameCount++;
    // Log every frame initially, then every 30th
    if (_frameCount <= 5 || _frameCount % 30 == 0) {
      _log('Frame #$_frameCount: load=$loadState vel=$velocity ts=$timestamp');
    }
  }

  void _onHeadInfo(dynamic userData, int resolution, int channel, int type) {
    _log('VIDEO HEAD: res=$resolution ch=$channel type=$type');
  }

  void _onCameraCommand(int cmd, Uint8List data) {
    // Log commands from camera (24631 = livestream response)
    final dataStr = data.length > 50 ? '${data.length} bytes' : String.fromCharCodes(data);
    _log('CMD $cmd: $dataStr');
  }

  /// Stop video streaming
  Future<void> _stopVideo() async {
    if (_playerController == null) return;

    _log('Stopping video stream...');

    try {
      await _playerController!.stop();
      _log('  Player stopped');
      _updateVideoState(VideoPlayerState.ready, 'Stream stopped');
    } catch (e) {
      _log('ERROR stopping: $e');
    }
  }

  /// Disconnect from camera and cleanup
  Future<void> _disconnectVideo() async {
    _log('Disconnecting...');
    await _cleanupVideoConnection();
    _updateVideoState(VideoPlayerState.disconnected, 'Disconnected');
    _log('Disconnected.');
  }

  /// Update video state (called from connection methods)
  void _updateVideoState(VideoPlayerState state, [String? message]) {
    if (mounted) {
      setState(() {
        _videoState = state;
        if (message != null) {
          _videoStatusMessage = message;
        }
      });
    }
  }

  Widget _buildCacheStatus() {
    if (_loadingCache) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Loading cache...', style: TextStyle(color: Colors.grey)),
      );
    }

    if (_cachedCredentials == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No credentials cached. Fetch credentials first.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text('Credentials Cached',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: _clearCache,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                ),
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Client ID: ${_cachedCredentials!.maskedClientId}',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          Text('Cached: ${_cachedCredentials!.cacheAgeDescription}',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Connection Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Manual Entry',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Camera UID: $_cameraUID',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'admin or email',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'password',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildCacheStatus(),
          ),

          // Compact test buttons - 4 in a row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    _miniButton('Fetch', Colors.green, _isRunning ? null : _fetchAndCache),
                    const SizedBox(width: 4),
                    _miniButton('LAN', Colors.deepPurple, _isRunning ? null : _runTest),
                    const SizedBox(width: 4),
                    _miniButton('Offline', Colors.orange,
                        (_isRunning || _cachedCredentials == null) ? null : _testWithCache),
                    const SizedBox(width: 4),
                    _miniButton('Cloud', Colors.blue,
                        (_isRunning || _cachedCredentials == null) ? null : _testWithCloud),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _miniButton('Full SDK', Colors.teal, _isRunning ? null : _testWithCameraDevice),
                    const SizedBox(width: 4),
                    _miniButton('Player SDK', Colors.deepPurple, _isRunning ? null : _testVideoPlayerSDK),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Video Player Section
          _buildVideoPlayer(),
          const SizedBox(height: 4),
          _buildVideoControls(),
          _buildVideoDebugInfo(),

          const SizedBox(height: 2),

          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Press a button to start\n\nLogs will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _isRunning
                      ? Stack(
                          children: [
                            _buildLogList(),
                            const Positioned(
                              bottom: 8,
                              right: 8,
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white30,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildLogList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        Color color = Colors.white;
        if (log.contains('ERROR') || log.contains('FAILED')) {
          color = Colors.red.shade300;
        } else if (log.contains('SUCCESS') || log.contains('OK')) {
          color = Colors.green.shade300;
        } else if (log.contains('Step')) {
          color = Colors.cyan.shade300;
        } else if (log.contains('===')) {
          color = Colors.yellow.shade300;
        }
        return Text(
          log,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: color,
          ),
        );
      },
    );
  }
}
