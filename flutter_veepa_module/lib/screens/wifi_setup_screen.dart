import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/sdk/app_p2p_api.dart';
import '../models/p2p_credentials.dart';
import '../services/p2p_credential_cache.dart';

/// WiFi network information parsed from scan results
class WifiNetwork {
  final String ssid;
  final int signal;
  final String security;
  final int channel;

  WifiNetwork({
    required this.ssid,
    required this.signal,
    required this.security,
    required this.channel,
  });

  /// Signal strength as bars (0-4)
  int get signalBars {
    if (signal >= 80) return 4;
    if (signal >= 60) return 3;
    if (signal >= 40) return 2;
    if (signal >= 20) return 1;
    return 0;
  }

  /// Whether network is open (no password)
  bool get isOpen => security.toLowerCase() == 'open' || security.isEmpty;
}

/// WiFi Setup Screen - Story 1: WiFi Network Scanner
class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen({super.key});

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  final P2PCredentialCache _cache = P2PCredentialCache();

  // Connection state
  bool _isConnecting = false;
  bool _isConnected = false;
  int? _clientPtr;
  P2PCredentials? _credentials;

  // WiFi scan state
  bool _isScanning = false;
  List<WifiNetwork> _networks = [];
  String? _scanError;

  final String _cameraUID = 'OKB0379196OXYB';
  final String _defaultPassword = '888888';

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    _disconnect();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _loadCredentials() async {
    _credentials = await _cache.loadCredentials(_cameraUID);
    if (_credentials != null) {
      _log('Loaded cached credentials');
    }
  }

  /// Connect to camera in AP mode (direct WiFi connection)
  Future<void> _connectToCamera() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
      _logs.clear();
    });

    _log('=== CONNECTING TO CAMERA ===');
    _log('Make sure your phone is connected to the camera WiFi hotspot');
    _log('(e.g., @MC-0379196)');
    _log('');

    try {
      // Create P2P client
      _log('Step 1: Creating P2P client...');

      // Use cached clientId if available, otherwise use virtual UID
      final deviceId = _credentials?.clientId ?? _cameraUID;
      _clientPtr = await AppP2PApi().clientCreate(deviceId);

      if (_clientPtr == null || _clientPtr == 0) {
        _log('ERROR: Failed to create client');
        setState(() => _isConnecting = false);
        return;
      }
      _log('  OK - clientPtr: $_clientPtr');

      // Connect with LAN mode (direct WiFi)
      _log('');
      _log('Step 2: Connecting (AP mode)...');
      _log('  lanScan: true');
      _log('  connectType: 63 (LAN/AP mode)');

      final serviceParam = _credentials?.serviceParam ?? '';
      final connectState = await AppP2PApi()
          .clientConnect(
            _clientPtr!,
            true,
            serviceParam,
            connectType: 63,
            p2pType: 0,
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT,
          );

      _log('  Result: ${connectState.name}');

      if (connectState != ClientConnectState.CONNECT_STATUS_ONLINE) {
        _log('');
        _log('ERROR: Connection failed');
        _log('Make sure phone is connected to camera WiFi');
        await _cleanup();
        setState(() => _isConnecting = false);
        return;
      }

      // Login
      _log('');
      _log('Step 3: Logging in...');
      final loginResult = await AppP2PApi().clientLogin(
        _clientPtr!,
        'admin',
        _defaultPassword,
      );
      _log('  Login: $loginResult');

      if (!loginResult) {
        _log('ERROR: Login failed');
        await _cleanup();
        setState(() => _isConnecting = false);
        return;
      }

      // Set up command listener to receive CGI responses
      AppP2PApi().setCommandListener(_clientPtr!, _onCommand);

      _log('');
      _log('=== CONNECTED ===');
      _log('Ready to scan WiFi networks');

      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });
    } catch (e) {
      _log('EXCEPTION: $e');
      await _cleanup();
      setState(() => _isConnecting = false);
    }
  }

  /// Disconnect from camera
  Future<void> _disconnect() async {
    await _cleanup();
    setState(() {
      _isConnected = false;
      _networks = [];
    });
  }

  Future<void> _cleanup() async {
    if (_clientPtr != null && _clientPtr != 0) {
      AppP2PApi().removeCommandListener(_clientPtr!);
      await AppP2PApi().clientDisconnect(_clientPtr!);
      await AppP2PApi().clientDestroy(_clientPtr!);
      _clientPtr = null;
    }
  }

  /// Buffer to accumulate command responses
  final StringBuffer _responseBuffer = StringBuffer();

  /// Handle CGI command responses from camera
  void _onCommand(int cmd, Uint8List data) {
    try {
      final response = String.fromCharCodes(data);
      _log('CMD $cmd: ${response.length > 100 ? '${response.substring(0, 100)}...' : response}');

      // Accumulate response data
      _responseBuffer.write(response);

      // Check if we have WiFi scan results
      if (_responseBuffer.toString().contains('ap_ssid[')) {
        _parseWifiScanResults(_responseBuffer.toString());
        _responseBuffer.clear();
      }
    } catch (e) {
      _log('CMD $cmd: ${data.length} bytes (binary)');
    }
  }

  /// Scan for available WiFi networks
  Future<void> _scanNetworks() async {
    if (!_isConnected || _clientPtr == null) {
      _log('ERROR: Not connected to camera');
      return;
    }

    setState(() {
      _isScanning = true;
      _scanError = null;
      _networks = [];
    });

    _log('');
    _log('=== SCANNING WIFI NETWORKS ===');

    try {
      // Step 1: Send scan command
      _log('Step 1: Sending wifi_scan.cgi...');
      _responseBuffer.clear();

      final scanSent = await AppP2PApi().clientWriteCgi(
        _clientPtr!,
        'wifi_scan.cgi?',
      );
      _log('  Sent: $scanSent');

      if (!scanSent) {
        setState(() {
          _isScanning = false;
          _scanError = 'Failed to send scan command';
        });
        return;
      }

      // Step 2: Wait for camera to scan
      _log('');
      _log('Step 2: Waiting for scan (3 seconds)...');
      await Future.delayed(const Duration(seconds: 3));

      // Step 3: Get results
      _log('');
      _log('Step 3: Sending get_wifi_scan_result.cgi...');
      _responseBuffer.clear();

      final resultSent = await AppP2PApi().clientWriteCgi(
        _clientPtr!,
        'get_wifi_scan_result.cgi?',
      );
      _log('  Sent: $resultSent');

      if (!resultSent) {
        setState(() {
          _isScanning = false;
          _scanError = 'Failed to get scan results';
        });
        return;
      }

      // Wait for response to come in via command listener
      _log('');
      _log('Waiting for results...');
      await Future.delayed(const Duration(seconds: 2));

      // Check if we got results
      if (_networks.isEmpty && _responseBuffer.isNotEmpty) {
        _parseWifiScanResults(_responseBuffer.toString());
      }

      if (_networks.isEmpty) {
        _log('No networks found (or response not received yet)');
        setState(() => _scanError = 'No networks found');
      } else {
        _log('');
        _log('=== SCAN COMPLETE ===');
        _log('Found ${_networks.length} network(s)');
      }
    } catch (e) {
      _log('EXCEPTION: $e');
      setState(() => _scanError = 'Scan failed: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  /// Parse WiFi scan results from CGI response
  /// Expected format: ap_ssid[0]="NetworkName"; ap_signal[0]=80; ap_security[0]="WPA2";
  void _parseWifiScanResults(String response) {
    _log('Parsing scan results...');

    final List<WifiNetwork> networks = [];

    // Parse each network entry using SSID pattern to find network indices
    final ssidPattern = RegExp(r'ap_ssid\[(\d+)\]="([^"]*)"');

    // Find all SSIDs first
    final ssidMatches = ssidPattern.allMatches(response);

    for (final match in ssidMatches) {
      final index = match.group(1)!;
      final ssid = match.group(2)!;

      if (ssid.isEmpty) continue; // Skip empty SSIDs

      // Find corresponding signal, security, channel
      int signal = 0;
      String security = '';
      int channel = 0;

      final signalMatch = RegExp('ap_signal\\[$index\\]=(\\d+)').firstMatch(response);
      if (signalMatch != null) {
        signal = int.tryParse(signalMatch.group(1)!) ?? 0;
      }

      final securityMatch = RegExp('ap_security\\[$index\\]="([^"]*)"').firstMatch(response);
      if (securityMatch != null) {
        security = securityMatch.group(1)!;
      }

      final channelMatch = RegExp('ap_channel\\[$index\\]=(\\d+)').firstMatch(response);
      if (channelMatch != null) {
        channel = int.tryParse(channelMatch.group(1)!) ?? 0;
      }

      networks.add(WifiNetwork(
        ssid: ssid,
        signal: signal,
        security: security,
        channel: channel,
      ));

      _log('  Found: $ssid (signal: $signal, security: $security, ch: $channel)');
    }

    // Sort by signal strength (strongest first)
    networks.sort((a, b) => b.signal.compareTo(a.signal));

    setState(() {
      _networks = networks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Setup'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Connection status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isConnected ? Colors.teal.shade50 : Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.warning_amber,
                  color: _isConnected ? Colors.teal : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isConnected
                            ? 'Connected to Camera'
                            : 'Not Connected',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isConnected
                            ? 'Ready to scan WiFi networks'
                            : 'Connect to camera WiFi hotspot first',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isConnected)
                  ElevatedButton(
                    onPressed: _isConnecting ? null : _connectToCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: _isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Connect'),
                  )
                else
                  TextButton(
                    onPressed: _disconnect,
                    child: const Text('Disconnect'),
                  ),
              ],
            ),
          ),

          // Scan button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnected && !_isScanning ? _scanNetworks : null,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.wifi_find),
                label: Text(_isScanning ? 'Scanning...' : 'Scan Networks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // Network list
          if (_networks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Available Networks (${_networks.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _isScanning ? null : _scanNetworks,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _networks.length,
                itemBuilder: (context, index) {
                  final network = _networks[index];
                  return _buildNetworkTile(network);
                },
              ),
            ),
          ] else if (_scanError != null) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _scanError!,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isConnected ? _scanNetworks : null,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Empty state
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_find,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isConnected
                          ? 'Tap "Scan Networks" to find WiFi networks'
                          : 'Connect to camera first',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Log panel (collapsible)
          Container(
            height: 120,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Logs',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _logs.clear()),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color color = Colors.white;
                      if (log.contains('ERROR')) {
                        color = Colors.red.shade300;
                      } else if (log.contains('OK') || log.contains('Found')) {
                        color = Colors.green.shade300;
                      } else if (log.contains('Step')) {
                        color = Colors.cyan.shade300;
                      }
                      return Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: color,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTile(WifiNetwork network) {
    return ListTile(
      leading: _buildSignalIcon(network.signalBars),
      title: Text(network.ssid),
      subtitle: Text(
        '${network.security.isEmpty ? "Open" : network.security} • Ch ${network.channel}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: network.isOpen
          ? null
          : const Icon(Icons.lock, size: 16, color: Colors.grey),
      onTap: () => _onNetworkTap(network),
    );
  }

  Widget _buildSignalIcon(int bars) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Base wifi icon
          Icon(
            bars >= 4
                ? Icons.wifi
                : bars >= 3
                    ? Icons.wifi_2_bar
                    : bars >= 2
                        ? Icons.wifi_1_bar
                        : Icons.wifi,
            color: bars >= 3
                ? Colors.green
                : bars >= 2
                    ? Colors.orange
                    : Colors.red,
            size: 24,
          ),
        ],
      ),
    );
  }

  void _onNetworkTap(WifiNetwork network) {
    _log('Selected network: ${network.ssid}');
    // TODO: Story 2 - Show password dialog and configure WiFi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: ${network.ssid}\n(WiFi configuration coming in Story 2)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
