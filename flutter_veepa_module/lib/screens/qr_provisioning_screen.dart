import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:veepa_camera_poc/services/wifi_qr_generator_service.dart';
import 'package:veepa_camera_poc/services/hello_api_service.dart';
import 'package:veepa_camera_poc/screens/p2p_test_screen.dart';
import 'package:veepa_camera_poc/widgets/masked_qr_widget.dart';

/// QR Code WiFi Provisioning Screen
///
/// This screen implements the official Veepa SDK flow for initial camera WiFi setup:
/// 1. Get current WiFi info (SSID, BSSID)
/// 2. User enters WiFi password
/// 3. Generate QR code with credentials
/// 4. User shows QR to camera
/// 5. Poll cloud API for camera registration
/// 6. Navigate to camera view on success
class QrProvisioningScreen extends StatefulWidget {
  const QrProvisioningScreen({super.key});

  @override
  State<QrProvisioningScreen> createState() => _QrProvisioningScreenState();
}

class _QrProvisioningScreenState extends State<QrProvisioningScreen> {
  final _passwordController = TextEditingController();
  final _qrGenerator = WifiQRGeneratorService();
  // Use your REAL user ID for cloud polling (matches official app)
  final _helloApi = HelloApiService(userId: '303628825');

  // WiFi info
  String _wifiSsid = '';
  String _wifiBssid = '';
  bool _isLoadingWifiInfo = true;
  String? _wifiError;

  // QR state - multi-frame support
  List<String> _qrFrames = [];
  int _currentFrameIndex = 0;
  Timer? _frameTimer;
  bool _isShowingQr = false;

  // QR mode: 0 = Single QR (SDK), 1 = Multi-frame, 2 = Official Pattern, 3 = Images
  int _qrMode = 3;  // Default to Images (exact screenshots from official app)

  // Image assets for mode 3 (exact screenshots from official app)
  static const List<String> _imageAssets = [
    'assets/qr_images/frame1_full.png',
    'assets/qr_images/frame2_userid1.png',
    'assets/qr_images/frame3_userid2.png',
    'assets/qr_images/frame4_ssid.png',
    'assets/qr_images/frame5_password.png',
  ];

  // For image mode: show full frame once, then cycle through rest
  bool _hasShownFullFrame = false;

  // Polling state
  bool _isPolling = false;
  int _pollCount = 0;
  Timer? _pollTimer;
  String? _foundCameraUid;

  @override
  void initState() {
    super.initState();
    _getWifiInfo();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _pollTimer?.cancel();
    _frameTimer?.cancel();
    super.dispose();
  }

  Future<void> _getWifiInfo() async {
    setState(() {
      _isLoadingWifiInfo = true;
      _wifiError = null;
    });

    try {
      // Request location permission first (required for WiFi SSID on iOS)
      _log('Requesting location permission...');
      final locationStatus = await Permission.locationWhenInUse.request();
      _log('Location permission status: $locationStatus');

      if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
        setState(() {
          _wifiError = 'Location permission is required to detect WiFi network.\n\nPlease go to Settings > Privacy > Location Services and enable location for this app.';
          _isLoadingWifiInfo = false;
        });
        return;
      }

      // Check if connected to WiFi
      final result = await Connectivity().checkConnectivity();
      if (result != ConnectivityResult.wifi) {
        setState(() {
          _wifiError = 'Please connect to your WiFi network first';
          _isLoadingWifiInfo = false;
        });
        return;
      }

      // Get WiFi details (requires location permission on iOS)
      final info = NetworkInfo();
      final ssid = await info.getWifiName();
      final bssid = await info.getWifiBSSID();

      _log('WiFi info: SSID=$ssid, BSSID=$bssid');

      setState(() {
        _wifiSsid = ssid?.replaceAll('"', '') ?? '';
        _wifiBssid = bssid ?? '';
        _isLoadingWifiInfo = false;

        if (_wifiSsid.isEmpty) {
          _wifiError = 'Could not detect WiFi network name.\n\nPlease ensure:\n1. Location permission is granted\n2. You are connected to WiFi\n3. Try tapping Refresh below';
        }
      });
    } catch (e) {
      setState(() {
        _wifiError = 'Error getting WiFi info: $e';
        _isLoadingWifiInfo = false;
      });
      _log('Error getting WiFi info: $e');
    }
  }

  void _generateQrCode() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      _showError('Please enter your WiFi password');
      return;
    }

    if (password.length < 8) {
      _showError('WiFi password must be at least 8 characters');
      return;
    }

    try {
      List<String> frames;

      if (_qrMode == 0) {
        // OPTION A: Single QR (SDK documented format)
        // Format: {"BS":"bssid","P":"password","U":"15463733-OEM","RS":"ssid"}
        final singleFrameQR = _qrGenerator.generateOfficialVeepaQRData(
          ssid: _wifiSsid,
          password: password,
          bssid: _wifiBssid.isNotEmpty ? _wifiBssid : null,
          userId: '15463733-OEM',
        );
        frames = [singleFrameQR];
      } else if (_qrMode == 1) {
        // OPTION B: Multi-frame (earlier reverse-engineered format)
        // 6 frames cycling: Full(3x), BSSID+User+Region, SSID+Region, Password+Region
        frames = _qrGenerator.generateMultiFrameQRData(
          ssid: _wifiSsid,
          password: password,
          bssid: _wifiBssid,
          userId: '303628825',
          region: '3',
        );
      } else if (_qrMode == 2) {
        // OPTION C: Official Pattern (EXACT match from video recording)
        // 5 frames: Full(U empty), UserID x2, SSID+Region, Password+Region
        // Full shown ONCE, then cycle through rest (same as image mode)
        frames = _qrGenerator.generateOfficialPattern(
          ssid: _wifiSsid,
          password: password,
          bssid: _wifiBssid,
          userId: '303-62 88 25',
          region: '3',
        );
        _hasShownFullFrame = false; // Reset so full frame shows once
      } else {
        // OPTION D: Images (exact screenshots from official app)
        // Uses pre-captured QR images - no generation needed
        frames = _imageAssets;
        _hasShownFullFrame = false;
        _log('Using image assets from official app');
      }

      if (_qrMode != 3) {
        _log('Generated QR data:');
        for (int i = 0; i < frames.length; i++) {
          _log('  Frame $i: ${frames[i]}');
        }
      }

      setState(() {
        _qrFrames = frames;
        _currentFrameIndex = 0;
        _isShowingQr = true;
      });

      // Start frame alternation timer (~500ms like official app)
      _startFrameTimer();

      // Start polling for camera registration
      _startPolling();
    } catch (e) {
      _showError('Error generating QR code: $e');
    }
  }

  void _startFrameTimer() {
    _frameTimer?.cancel();
    _scheduleNextFrame();
  }

  void _scheduleNextFrame() {
    // For modes 2 & 3: Full shown once, then cycle UserID1→UserID2→SSID→Password
    // For other modes: cycle through all frames with pause after last
    final isLastFrame = _currentFrameIndex == _qrFrames.length - 1;
    final delay = isLastFrame ? 1000 : 500; // 1 second pause after last frame

    _frameTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        if (_qrMode == 2 || _qrMode == 3) {
          // Official Pattern & Image mode: Full shown ONCE, then cycle rest
          if (_currentFrameIndex == 0 && !_hasShownFullFrame) {
            // Just showed full frame, mark it as shown
            _hasShownFullFrame = true;
            _currentFrameIndex = 1; // Move to first user ID
          } else {
            // Cycle through frames 1-4 only (skip frame 0 after first time)
            _currentFrameIndex = _currentFrameIndex >= 4 ? 1 : _currentFrameIndex + 1;
          }
        } else {
          // Normal cycling for other modes
          _currentFrameIndex = (_currentFrameIndex + 1) % _qrFrames.length;
        }
      });
      _scheduleNextFrame();
    });
  }

  void _stopFrameTimer() {
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  Future<void> _startPolling() async {
    setState(() {
      _isPolling = true;
      _pollCount = 0;
    });

    _log('Starting cloud polling...');

    // Clear previous binding intent
    await _helloApi.confirmHello();

    // Poll every 2 seconds, up to 30 times (60 seconds)
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_pollCount >= 30) {
        timer.cancel();
        setState(() => _isPolling = false);
        _showError('Timeout: Camera not detected after 60 seconds. Please try again.');
        return;
      }

      setState(() => _pollCount++);
      _log('Poll attempt $_pollCount/30...');

      // Alternate between old and new device query formats
      final cameraUid = await _helloApi.queryAlternating(_pollCount);

      if (cameraUid != null) {
        timer.cancel();
        setState(() {
          _isPolling = false;
          _foundCameraUid = cameraUid;
        });
        _onCameraFound(cameraUid);
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    setState(() {
      _isPolling = false;
      _pollCount = 0;
    });
  }

  void _onCameraFound(String uid) {
    _log('Camera found! UID: $uid');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Camera Connected!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Camera UID: $uid'),
            const SizedBox(height: 12),
            const Text('The camera has connected to your WiFi and registered with the cloud.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const P2PTestScreen()),
              );
            },
            child: const Text('Go to Camera'),
          ),
        ],
      ),
    );
  }

  void _resetQrScreen() {
    _stopPolling();
    _stopFrameTimer();
    setState(() {
      _isShowingQr = false;
      _qrFrames = [];
      _currentFrameIndex = 0;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getFrameLabel(int index) {
    if (_qrMode == 3) {
      // Image mode (exact screenshots)
      switch (index) {
        case 0:
          return 'Full (shown once)';
        case 1:
          return 'User ID #1';
        case 2:
          return 'User ID #2';
        case 3:
          return 'SSID';
        case 4:
          return 'Password';
        default:
          return 'Frame ${index + 1}';
      }
    } else if (_qrMode == 2) {
      // Official Pattern (5 frames - decoded from official app)
      switch (index) {
        case 0:
          return 'Full (U empty)';
        case 1:
          return 'Full+UserID (M4)';
        case 2:
          return 'BS+U+A (M2)';
        case 3:
          return 'SSID+Region';
        case 4:
          return 'Password+Region';
        default:
          return 'Frame ${index + 1}';
      }
    } else if (_qrMode == 1) {
      // Multi-frame (6 frames)
      switch (index) {
        case 0:
        case 1:
        case 2:
          return 'Full Data';
        case 3:
          return 'BSSID + User';
        case 4:
          return 'Network Name';
        case 5:
          return 'Password';
        default:
          return 'Frame ${index + 1}';
      }
    } else {
      // Single QR
      return 'SDK Format';
    }
  }

  /// Get the QR version for each frame to match official app dimensions
  /// Based on user's measurements:
  /// - Full (frame 0): ~33 modules = Version 4
  /// - User ID #1 (frame 1): ~33 modules = Version 4
  /// - User ID #2 (frame 2): 29 modules = Version 3
  /// - SSID (frame 3): 29 modules = Version 3
  /// - Password (frame 4): 25 modules = Version 2
  int _getQrVersionForFrame(int frameIndex) {
    if (_qrMode == 2) {
      // Official Pattern mode - use exact versions from official app
      switch (frameIndex) {
        case 0: // Full data
          return 4; // 33x33 modules
        case 1: // User ID #1
          return 4; // 33x33 modules
        case 2: // User ID #2
          return 3; // 29x29 modules
        case 3: // SSID + Region
          return 3; // 29x29 modules
        case 4: // Password + Region
          return 2; // 25x25 modules
        default:
          return QrVersions.auto;
      }
    }
    // For other modes, use auto
    return QrVersions.auto;
  }

  /// Build QR code with specific mask pattern for Official Pattern mode
  Widget _buildMaskedQr(int frameIndex) {
    final config = WifiQRGeneratorService.getQrConfigForFrame(frameIndex);
    final typeNumber = config.$1;
    final maskPattern = config.$2;

    return MaskedQrWidget(
      data: _qrFrames[frameIndex],
      typeNumber: typeNumber,
      maskPattern: maskPattern,
      size: 300,
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
    );
  }

  void _log(String message) {
    debugPrint('[QrProvisioning] $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR WiFi Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isShowingQr) {
              _resetQrScreen();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: _isShowingQr ? _buildQrDisplay() : _buildWifiForm(),
      ),
    );
  }

  Widget _buildWifiForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Icon(Icons.qr_code_2, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'WiFi QR Provisioning',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a QR code for your camera to scan',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // WiFi Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildWifiInfoContent(),
            ),
          ),
          const SizedBox(height: 24),

          // Password Input
          if (!_isLoadingWifiInfo && _wifiError == null) ...[
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'WiFi Password',
                hintText: 'Enter your WiFi password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // QR Mode Toggle (3 options)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Code Mode:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Row 1: Single QR and Multi-Frame
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _qrMode = 0),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _qrMode == 0 ? Colors.blue : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.qr_code,
                                    size: 20,
                                    color: _qrMode == 0 ? Colors.white : Colors.blue),
                                  const SizedBox(height: 2),
                                  Text('Single',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _qrMode == 0 ? Colors.white : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    )),
                                  Text('(SDK)',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: _qrMode == 0 ? Colors.white70 : Colors.blue,
                                    )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _qrMode = 1),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _qrMode == 1 ? Colors.blue : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.flip,
                                    size: 20,
                                    color: _qrMode == 1 ? Colors.white : Colors.blue),
                                  const SizedBox(height: 2),
                                  Text('Multi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _qrMode == 1 ? Colors.white : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    )),
                                  Text('(6 frames)',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: _qrMode == 1 ? Colors.white70 : Colors.blue,
                                    )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _qrMode = 2),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _qrMode == 2 ? Colors.orange : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.verified,
                                    size: 20,
                                    color: _qrMode == 2 ? Colors.white : Colors.orange),
                                  const SizedBox(height: 2),
                                  Text('Official',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _qrMode == 2 ? Colors.white : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    )),
                                  Text('(gen)',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: _qrMode == 2 ? Colors.white70 : Colors.orange,
                                    )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _qrMode = 3),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _qrMode == 3 ? Colors.green : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green, width: 2),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.image,
                                    size: 20,
                                    color: _qrMode == 3 ? Colors.white : Colors.green),
                                  const SizedBox(height: 2),
                                  Text('Images',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _qrMode == 3 ? Colors.white : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    )),
                                  Text('(exact)',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: _qrMode == 3 ? Colors.white70 : Colors.green,
                                    )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Generate Button
            ElevatedButton.icon(
              onPressed: _wifiSsid.isNotEmpty ? _generateQrCode : null,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Before You Begin',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Make sure your camera is in QR scan mode (factory reset if needed)\n'
                  '2. The camera LED should indicate it\'s ready for WiFi setup\n'
                  '3. Keep your phone connected to your home WiFi',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiInfoContent() {
    if (_isLoadingWifiInfo) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Detecting WiFi network...'),
        ],
      );
    }

    if (_wifiError != null) {
      return Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            _wifiError!,
            style: TextStyle(color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _getWifiInfo,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.wifi, color: Colors.green),
          title: const Text('Network Name (SSID)'),
          subtitle: Text(
            _wifiSsid.isNotEmpty ? _wifiSsid : 'Not detected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _wifiSsid.isNotEmpty ? Colors.black : Colors.red,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.router, color: Colors.blue),
          title: const Text('BSSID'),
          subtitle: Text(
            _wifiBssid.isNotEmpty ? _wifiBssid : 'Not available (optional)',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        TextButton.icon(
          onPressed: _getWifiInfo,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildQrDisplay() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Instructions
                Text(
                  'Show these QR codes to your camera',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The codes alternate automatically - hold steady until camera responds',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // QR Code (alternating frames)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: _qrFrames.isNotEmpty
                      ? (_qrMode == 3
                          // Image mode: show actual screenshot images
                          ? Image.asset(
                              _qrFrames[_currentFrameIndex],
                              width: 260,
                              height: 260,
                              fit: BoxFit.contain,
                            )
                          : _qrMode == 2
                            // Official Pattern mode: use MaskedQrWidget with specific masks
                            ? _buildMaskedQr(_currentFrameIndex)
                            // Other modes: use standard qr_flutter
                            : QrImageView(
                                data: _qrFrames[_currentFrameIndex],
                                version: _getQrVersionForFrame(_currentFrameIndex),
                                size: 300,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.L,
                              ))
                      : const SizedBox(width: 260, height: 260),
                ),
                const SizedBox(height: 12),

                // Frame indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_qrFrames.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentFrameIndex
                            ? Colors.blue
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),

                // Frame label
                Text(
                  _getFrameLabel(_currentFrameIndex),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // Network info
                Text(
                  'Network: $_wifiSsid',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Polling status
                if (_isPolling) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          'Waiting for camera...',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_pollCount / 30 attempts (${_pollCount * 2}s / 60s)',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_foundCameraUid != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Text(
                          'Camera found!',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (!_isPolling)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startPolling,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Detection'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resetQrScreen,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
