import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:veepa_camera_poc/models/connection_state.dart';
import 'package:veepa_camera_poc/models/player_state.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';

/// Manages video playback from Veepa camera
class VeepaPlayerService extends ChangeNotifier {
  static final VeepaPlayerService _instance = VeepaPlayerService._internal();
  factory VeepaPlayerService() => _instance;
  VeepaPlayerService._internal();

  /// Configuration
  static const Duration bufferingTimeout = Duration(seconds: 10);
  static const int targetFrameRate = 15;

  /// Player state
  PlayerState _state = PlayerState.stopped;
  PlayerState get state => _state;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Current device
  DiscoveredDevice? _device;
  DiscoveredDevice? get device => _device;

  /// Frame rate monitoring
  int _frameCount = 0;
  DateTime? _frameCountStart;
  double _currentFPS = 0;
  double get currentFPS => _currentFPS;

  /// State stream for external listeners
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  Stream<PlayerState> get stateStream => _stateController.stream;

  /// Frame callback for video texture
  void Function(Uint8List frameData, int width, int height)? onFrameReceived;

  /// Timers
  Timer? _bufferingTimer;
  Timer? _fpsTimer;

  /// Connection manager reference
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  /// SDK Player reference (placeholder for actual SDK)
  dynamic _sdkPlayer;

  /// Start video playback for device
  Future<bool> start(DiscoveredDevice device) async {
    if (_state.isActive) {
      debugPrint('[VeepaPlayer] Already active, stopping first');
      await stop();
    }

    // Verify connection is active FIRST before changing state
    if (!_connectionManager.state.isConnected) {
      _errorMessage = 'Not connected to camera';
      _updateState(PlayerState.error);
      return false;
    }

    _device = device;
    _errorMessage = null;
    _updateState(PlayerState.buffering);

    // Start buffering timeout
    _startBufferingTimeout();

    try {

      // Initialize SDK player
      await _initializePlayer();

      // Start stream
      await _startStream();

      // Start FPS monitoring
      _startFPSMonitoring();

      return true;
    } catch (e) {
      _cancelBufferingTimeout();
      _errorMessage = e.toString();
      _updateState(PlayerState.error);
      return false;
    }
  }

  /// Initialize the SDK player
  Future<void> _initializePlayer() async {
    debugPrint('[VeepaPlayer] Initializing player...');

    // POC: Simulated player initialization
    // TODO: Replace with actual SDK player initialization
    // final p2pApi = VeepaSDKManager().p2pApi;
    // _sdkPlayer = AppPlayer(p2pApi);

    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint('[VeepaPlayer] Player initialized');
  }

  /// Start the video stream
  Future<void> _startStream() async {
    debugPrint('[VeepaPlayer] Starting stream from ${_device?.name}');
    debugPrint('[VeepaPlayer] Device IP: ${_device?.ipAddress}');

    // POC: Simulate first frame after delay
    // TODO: Replace with actual SDK stream start
    // await _sdkPlayer.start(
    //   videoSource: LiveVideoSource(deviceId: _device!.deviceId),
    //   onFrame: _handleFrameReceived,
    //   onError: _handleStreamError,
    // );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_state == PlayerState.buffering) {
        _cancelBufferingTimeout();
        _updateState(PlayerState.playing);
        debugPrint('[VeepaPlayer] First frame received (simulated)');
      }
    });
  }

  /// Handle frame received from SDK
  void handleFrameReceived(Uint8List frameData, int width, int height) {
    // Update frame count for FPS calculation
    _frameCount++;

    // First frame - transition from buffering
    if (_state == PlayerState.buffering) {
      _cancelBufferingTimeout();
      _updateState(PlayerState.playing);
    }

    // Notify listeners
    onFrameReceived?.call(frameData, width, height);
  }

  /// Handle stream error
  void handleStreamError(dynamic error) {
    debugPrint('[VeepaPlayer] Stream error: $error');
    _errorMessage = error.toString();
    _updateState(PlayerState.error);
  }

  /// Stop video playback
  Future<void> stop() async {
    debugPrint('[VeepaPlayer] Stopping player');

    _cancelBufferingTimeout();
    _stopFPSMonitoring();

    try {
      // TODO: Replace with actual SDK stop
      // await _sdkPlayer?.stop();
      _sdkPlayer = null;
    } catch (e) {
      debugPrint('[VeepaPlayer] Error stopping: $e');
    }

    _device = null;
    _currentFPS = 0;
    _updateState(PlayerState.stopped);
  }

  /// Pause playback
  void pause() {
    if (_state != PlayerState.playing) return;

    debugPrint('[VeepaPlayer] Pausing');
    _updateState(PlayerState.paused);
  }

  /// Resume playback
  void resume() {
    if (_state != PlayerState.paused) return;

    debugPrint('[VeepaPlayer] Resuming');
    _updateState(PlayerState.playing);
  }

  /// Start buffering timeout
  void _startBufferingTimeout() {
    _cancelBufferingTimeout();
    _bufferingTimer = Timer(bufferingTimeout, () {
      if (_state == PlayerState.buffering) {
        _errorMessage = 'Buffering timeout - no video data received';
        _updateState(PlayerState.error);
      }
    });
  }

  /// Cancel buffering timeout
  void _cancelBufferingTimeout() {
    _bufferingTimer?.cancel();
    _bufferingTimer = null;
  }

  /// Start FPS monitoring
  void _startFPSMonitoring() {
    _frameCount = 0;
    _frameCountStart = DateTime.now();

    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateFPS();
    });
  }

  /// Stop FPS monitoring
  void _stopFPSMonitoring() {
    _fpsTimer?.cancel();
    _fpsTimer = null;
  }

  /// Calculate current FPS
  void _calculateFPS() {
    if (_frameCountStart == null) return;

    final elapsed = DateTime.now().difference(_frameCountStart!).inSeconds;
    if (elapsed > 0) {
      _currentFPS = _frameCount / elapsed;

      // Log if FPS is below target
      if (_currentFPS < targetFrameRate && _state == PlayerState.playing) {
        debugPrint('[VeepaPlayer] Low FPS: ${_currentFPS.toStringAsFixed(1)}');
      }
    }

    // Reset counter every 5 seconds for rolling average
    if (elapsed >= 5) {
      _frameCount = 0;
      _frameCountStart = DateTime.now();
    }

    notifyListeners();
  }

  /// Update player state
  void _updateState(PlayerState newState) {
    if (_state == newState) return;

    debugPrint('[VeepaPlayer] State: ${_state.name} -> ${newState.name}');
    _state = newState;
    _stateController.add(newState);
    notifyListeners();
  }

  /// Reset for testing
  void reset() {
    _cancelBufferingTimeout();
    _stopFPSMonitoring();
    _state = PlayerState.stopped;
    _errorMessage = null;
    _device = null;
    _currentFPS = 0;
    _frameCount = 0;
    _frameCountStart = null;
    _sdkPlayer = null;
    onFrameReceived = null;
  }

  @override
  void dispose() {
    _cancelBufferingTimeout();
    _stopFPSMonitoring();
    _stateController.close();
    _sdkPlayer = null;
    super.dispose();
  }
}
