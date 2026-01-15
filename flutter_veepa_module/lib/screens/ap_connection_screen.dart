import 'dart:async';
import 'package:flutter/material.dart';
import '../services/wifi_discovery_service.dart';
import '../services/ap_connection_monitor.dart';
import '../utils/wifi_settings_launcher.dart';

/// Screen for guiding user to connect to camera's WiFi AP
class APConnectionScreen extends StatefulWidget {
  final String? expectedSSIDPrefix;
  final Duration timeout;
  final VoidCallback? onConnected;
  final VoidCallback? onTimeout;

  const APConnectionScreen({
    super.key,
    this.expectedSSIDPrefix,
    this.timeout = const Duration(minutes: 2),
    this.onConnected,
    this.onTimeout,
  });

  @override
  State<APConnectionScreen> createState() => _APConnectionScreenState();
}

class _APConnectionScreenState extends State<APConnectionScreen> {
  final WifiDiscoveryService _wifiService = WifiDiscoveryService();
  Timer? _timeoutTimer;
  bool _isWaiting = true;
  String _statusMessage = 'Waiting for connection...';

  @override
  void initState() {
    super.initState();
    _setupWifiMonitoring();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _wifiService.onVeepaAPDetected = null;
    _wifiService.stopMonitoring();
    super.dispose();
  }

  void _setupWifiMonitoring() {
    _wifiService.onVeepaAPDetected = _onVeepaAPConnected;
    _wifiService.startMonitoring();

    // Check if already connected
    if (_wifiService.isConnectedToVeepaAP) {
      _onVeepaAPConnected();
    }
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(widget.timeout, _onTimeout);
  }

  void _onVeepaAPConnected() {
    if (!mounted) return;

    _timeoutTimer?.cancel();
    setState(() {
      _isWaiting = false;
      _statusMessage = 'Connected to camera WiFi!';
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        widget.onConnected?.call();
        Navigator.of(context).pop(true);
      }
    });
  }

  void _onTimeout() {
    if (!mounted) return;

    setState(() {
      _isWaiting = false;
      _statusMessage = 'Connection timed out';
    });

    widget.onTimeout?.call();
  }

  Future<void> _openWifiSettings() async {
    final opened = await WifiSettingsLauncher.openWifiSettings();

    if (!opened && mounted) {
      // Fallback: Show instructions if we can't open settings
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Open WiFi Settings'),
          content: const Text(
            'Please open your device Settings app and navigate to WiFi to connect to the camera network.\n\n'
            'Look for a network starting with "VEEPA_" or "VSTC_".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Camera'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // WiFi icon
              Icon(
                _isWaiting ? Icons.wifi_find : Icons.wifi,
                size: 100,
                color: _isWaiting ? Colors.orange : Colors.green,
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                _isWaiting ? 'Connect to Camera WiFi' : _statusMessage,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Instructions
              if (_isWaiting) ...[
                const Text(
                  'Your camera creates its own WiFi network for initial setup.\n\n'
                  '1. Open your device WiFi settings\n'
                  '2. Find a network starting with "VEEPA_" or "VSTC_"\n'
                  '3. Connect to it (no password needed)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 32),

                // Open WiFi settings button
                ElevatedButton.icon(
                  onPressed: _openWifiSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Open WiFi Settings'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Status indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _statusMessage,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],

              // Success state
              if (!_isWaiting && _wifiService.isConnectedToVeepaAP)
                const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green,
                ),

              const Spacer(),

              // Current WiFi info
              if (_wifiService.currentWifi.isConnected)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi,
                        color: _wifiService.isConnectedToVeepaAP
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Network',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _wifiService.currentWifi.ssid ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
