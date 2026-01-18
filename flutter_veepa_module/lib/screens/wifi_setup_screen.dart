import 'dart:async';
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
  bool _isLoginVerified = false;  // Login confirmed via cmd 24577 result=0
  int? _clientPtr;
  P2PCredentials? _credentials;

  // Extracted device info
  String? _realDeviceId;
  String? _serviceParam;

  // WiFi scan state
  bool _isScanning = false;
  List<WifiNetwork> _networks = [];
  String? _scanError;

  // Completer for waiting on login/status responses
  Completer<Map<String, dynamic>?>? _commandCompleter;
  int? _waitingForCmd;

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
  /// Implements the login verification gate per epic requirements
  Future<void> _connectToCamera() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
      _isLoginVerified = false;
      _realDeviceId = null;
      _logs.clear();
    });

    _log('=== CONNECTING TO CAMERA ===');
    _log('');

    try {
      // Check for cached credentials (required for reliable connection)
      if (_credentials == null) {
        _credentials = await _cache.loadCredentials(_cameraUID);
      }

      if (_credentials == null) {
        _log('ERROR: No cached credentials found');
        _log('Go to P2P Test Screen and press "Fetch & Cache" first');
        _log('(Requires internet connection)');
        setState(() => _isConnecting = false);
        return;
      }

      _log('Using cached credentials...');
      _log('  clientId: ${_credentials!.clientId.substring(0, 8)}...');

      // Step 1: Create P2P client with cached clientId (like _connectForVideo)
      _log('');
      _log('Step 1: Creating P2P client...');

      final api = AppP2PApi();
      _clientPtr = await api.clientCreate(_credentials!.clientId);

      if (_clientPtr == null || _clientPtr == 0) {
        _log('ERROR: Failed to create client');
        setState(() => _isConnecting = false);
        return;
      }
      _log('  OK - clientPtr: $_clientPtr');

      // Step 2: Connect with cached serviceParam (like _connectForVideo)
      _log('');
      _log('Step 2: Connecting...');
      _log('  lanScan: true');
      _log('  serviceParam: ${_credentials!.serviceParam.substring(0, 20)}...');
      _log('  connectType: 63 (LAN mode)');
      _log('');
      _log('  Connecting... (this may take up to 20 seconds)');

      final connectState = await api
          .clientConnect(
            _clientPtr!,
            true,
            _credentials!.serviceParam,
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

      _log('  Result: ${connectState.name}');

      if (connectState != ClientConnectState.CONNECT_STATUS_ONLINE) {
        _log('');
        _log('ERROR: Connection failed');
        _log('Make sure phone is connected to camera WiFi');
        await _cleanup();
        setState(() => _isConnecting = false);
        return;
      }

      // Step 3: Send login (matching P2P test screen pattern)
      _log('');
      _log('Step 3: Logging in...');

      final loginResult = await AppP2PApi().clientLogin(
        _clientPtr!,
        'admin',
        _defaultPassword,
      );
      _log('  Login request sent: $loginResult');

      if (!loginResult) {
        _log('ERROR: Failed to send login request');
        await _cleanup();
        setState(() => _isConnecting = false);
        return;
      }

      _log('  OK - Login sent successfully');

      // Step 4: Set up command listener (after login, like P2P test screen)
      _log('');
      _log('Step 4: Setting up command listener...');
      AppP2PApi().setCommandListener(_clientPtr!, _onCommand);
      _log('  OK - Listener attached');
      _isLoginVerified = true;

      // Step 5: Extract realdeviceid via get_status.cgi
      _log('');
      _log('Step 5: Extracting real device ID...');
      await _extractDeviceInfo();

      _log('');
      _log('=== CONNECTED & VERIFIED ===');
      _log('Ready to scan WiFi networks');
      if (_realDeviceId != null) {
        _log('Real Device ID: $_realDeviceId');
      }

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

  /// Wait for a specific command response with timeout
  Future<Map<String, dynamic>?> _waitForCommand(int cmd, {int timeout = 5}) async {
    _commandCompleter = Completer<Map<String, dynamic>?>();
    _waitingForCmd = cmd;

    try {
      final result = await _commandCompleter!.future.timeout(
        Duration(seconds: timeout),
        onTimeout: () => null,
      );
      return result;
    } finally {
      _commandCompleter = null;
      _waitingForCmd = null;
    }
  }

  /// Extract device info (realdeviceid) via get_status.cgi
  Future<void> _extractDeviceInfo() async {
    if (_clientPtr == null) return;

    _log('  Sending get_status.cgi...');
    _responseBuffer.clear();

    final sent = await AppP2PApi().clientWriteCgi(_clientPtr!, 'get_status.cgi?');
    if (!sent) {
      _log('  WARNING: Failed to send get_status.cgi');
      return;
    }

    // Wait for cmd 24577 response with status data
    final statusResponse = await _waitForCommand(24577, timeout: 5);

    if (statusResponse != null) {
      // Extract realdeviceid
      if (statusResponse.containsKey('realdeviceid')) {
        _realDeviceId = statusResponse['realdeviceid']?.toString();
        _log('  Found realdeviceid: $_realDeviceId');
      }

      // Cache credentials for future use
      if (_realDeviceId != null) {
        await _cacheCredentials();
      }
    } else {
      _log('  WARNING: No status response received');
    }
  }

  /// Cache extracted credentials for future router connections
  Future<void> _cacheCredentials() async {
    if (_realDeviceId == null) return;

    _log('  Caching credentials...');

    // Get serviceParam from existing credentials or leave empty
    // VSTH is in the SDK built-in table, so it will be looked up automatically
    _serviceParam = _credentials?.serviceParam ?? '';

    final newCredentials = P2PCredentials(
      cameraUid: _cameraUID,
      clientId: _realDeviceId!,
      serviceParam: _serviceParam ?? '',
      password: _defaultPassword,
      cachedAt: DateTime.now(),
    );

    await _cache.saveCredentials(newCredentials);
    _credentials = newCredentials;
    _log('  OK - Credentials cached');
  }

  /// Disconnect from camera
  Future<void> _disconnect() async {
    await _cleanup();
    setState(() {
      _isConnected = false;
      _isLoginVerified = false;
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

      // Parse response into key-value map
      final parsed = _parseResponse(response);

      // If we're waiting for this command, complete the future
      if (_waitingForCmd == cmd && _commandCompleter != null && !_commandCompleter!.isCompleted) {
        _commandCompleter!.complete(parsed);
      }

      // Accumulate response data for WiFi scan
      _responseBuffer.write(response);

      // Check if we have WiFi scan results
      if (_responseBuffer.toString().contains('ap_ssid[')) {
        _parseWifiScanResults(_responseBuffer.toString());
        _responseBuffer.clear();
      }
    } catch (e) {
      _log('CMD $cmd: ${data.length} bytes (binary)');

      // Complete with null if we're waiting for this command
      if (_waitingForCmd == cmd && _commandCompleter != null && !_commandCompleter!.isCompleted) {
        _commandCompleter!.complete(null);
      }
    }
  }

  /// Parse a CGI response string into a key-value map
  /// Handles format like: var key1="value1"; var key2=value2;
  Map<String, dynamic> _parseResponse(String response) {
    final Map<String, dynamic> result = {};

    // Remove newlines and split by semicolon
    final cleaned = response.replaceAll('\r', '').replaceAll('\n', '');
    final parts = cleaned.split(';');

    for (final part in parts) {
      if (part.contains('=')) {
        final eqIndex = part.indexOf('=');
        var key = part.substring(0, eqIndex).trim();
        var value = part.substring(eqIndex + 1).trim();

        // Remove "var " prefix if present
        if (key.startsWith('var ')) {
          key = key.substring(4);
        }

        // Remove quotes from value if present
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }

        result[key] = value;
      }
    }

    return result;
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
    _log('clientPtr: $_clientPtr');

    try {
      // Step 1: Send scan command
      _log('');
      _log('Step 1: Sending wifi_scan.cgi...');
      _responseBuffer.clear();

      final scanSent = await AppP2PApi().clientWriteCgi(
        _clientPtr!,
        'wifi_scan.cgi?',
        timeout: 10,
      );
      _log('  Sent: $scanSent');

      if (!scanSent) {
        _log('  ERROR: clientWriteCgi returned false');
        _log('  Connection may have been lost. Try reconnecting.');
        setState(() {
          _isScanning = false;
          _scanError = 'Failed to send scan command - connection lost?';
        });
        return;
      }

      // Step 2: Wait for camera to scan (cmd 24618)
      _log('');
      _log('Step 2: Waiting for scan response (cmd 24618)...');
      await Future.delayed(const Duration(seconds: 5));

      // Step 3: Get results
      _log('');
      _log('Step 3: Sending get_wifi_scan_result.cgi...');
      _responseBuffer.clear();

      final resultSent = await AppP2PApi().clientWriteCgi(
        _clientPtr!,
        'get_wifi_scan_result.cgi?',
        timeout: 10,
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
  /// Supports multiple formats:
  /// - Format 1: ap_ssid[0]="NetworkName"; ap_signal[0]=80;
  /// - Format 2: var ap_ssid=["Net1","Net2"]; var ap_signal=[80,60];
  void _parseWifiScanResults(String response) {
    _log('Parsing scan results...');
    _log('Raw response (first 500 chars):');
    _log(response.length > 500 ? response.substring(0, 500) : response);

    final List<WifiNetwork> networks = [];

    // First, parse into a map (like SDK does)
    final data = _parseResponse(response);
    _log('Parsed ${data.length} fields');

    // Check for ap_number (SDK format)
    final apNumberStr = data['ap_number']?.toString() ?? '0';
    final apNumber = int.tryParse(apNumberStr) ?? 0;
    _log('ap_number: $apNumber');

    if (apNumber > 0) {
      // SDK format: ap_ssid[0], ap_ssid[1], etc.
      for (int i = 0; i < apNumber; i++) {
        final ssid = data['ap_ssid[$i]']?.toString() ?? '';
        if (ssid.isEmpty) continue;

        final signal = int.tryParse(data['ap_dbm0[$i]']?.toString() ?? '0') ?? 0;
        final security = data['ap_security[$i]']?.toString() ?? '';
        final channel = int.tryParse(data['ap_channel[$i]']?.toString() ?? '0') ?? 0;

        networks.add(WifiNetwork(
          ssid: ssid,
          signal: signal.abs(),  // dbm is negative, we want positive
          security: security,
          channel: channel,
        ));
        _log('  Found: $ssid (signal: $signal, security: $security, ch: $channel)');
      }
    } else {
      // Try alternative format: ap_ssid[0]="value" pattern in raw text
      final ssidPattern = RegExp(r'ap_ssid\[(\d+)\][=:]"?([^";]+)"?');
      final ssidMatches = ssidPattern.allMatches(response);

      for (final match in ssidMatches) {
        final index = match.group(1)!;
        final ssid = match.group(2)!.trim();

        if (ssid.isEmpty) continue;

        int signal = 0;
        String security = '';
        int channel = 0;

        // Try to find corresponding values
        final signalMatch = RegExp('ap_(?:signal|dbm0)\\[$index\\][=:](\\d+)').firstMatch(response);
        if (signalMatch != null) {
          signal = int.tryParse(signalMatch.group(1)!) ?? 0;
        }

        final securityMatch = RegExp('ap_security\\[$index\\][=:]"?([^";]+)"?').firstMatch(response);
        if (securityMatch != null) {
          security = securityMatch.group(1)!;
        }

        final channelMatch = RegExp('ap_channel\\[$index\\][=:](\\d+)').firstMatch(response);
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
    }

    // Sort by signal strength (strongest first)
    networks.sort((a, b) => b.signal.compareTo(a.signal));

    _log('Total networks found: ${networks.length}');

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
