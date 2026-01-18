import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/screens/discovery_screen.dart';
import 'package:veepa_camera_poc/screens/p2p_test_screen.dart';
import 'package:veepa_camera_poc/screens/wifi_setup_screen.dart';
import 'package:veepa_camera_poc/services/sdk_integration_service.dart';
import 'package:veepa_camera_poc/services/camera_method_channel.dart';
import 'package:veepa_camera_poc/services/camera_event_channel.dart';
import 'package:veepa_camera_poc/sdk/app_p2p_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Reset SDK singletons on app start to handle restart scenarios
  AppP2PApi.resetInstance();

  CameraMethodChannel.setup();
  CameraEventChannel.setup();
  runApp(const VeepaCameraPOCApp());
}

class VeepaCameraPOCApp extends StatelessWidget {
  const VeepaCameraPOCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeepaCameraPOC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SDKIntegrationService _sdkService = SDKIntegrationService();

  @override
  void initState() {
    super.initState();
    _sdkService.addListener(_onSDKStateChanged);
    _initializeSDK();
  }

  @override
  void dispose() {
    _sdkService.removeListener(_onSDKStateChanged);
    super.dispose();
  }

  void _onSDKStateChanged() {
    setState(() {});
  }

  Future<void> _initializeSDK() async {
    // Use mock mode for simulator/testing
    _sdkService.setMode(SDKMode.mock);
    await _sdkService.initialize();
  }

  void _retryInitialization() {
    _sdkService.reset();
    _initializeSDK();
  }

  void _proceedToDiscovery() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiscoveryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VeepaCameraPOC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 64,
                color: _getStatusColor(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Veepa Camera POC',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatusIndicator(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    return _sdkService.isReady ? Colors.green : Colors.orange;
  }

  Widget _buildStatusIndicator() {
    final isReady = _sdkService.isReady;
    final mode = _sdkService.mode;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isReady)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (!isReady) const SizedBox(width: 8),
            Text(
              'SDK Status: ${isReady ? "Ready" : "Initializing..."}',
              style: TextStyle(
                fontSize: 16,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Mode: ${mode.name.toUpperCase()}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // WiFi Setup button - NEW for router connection setup
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WifiSetupScreen()),
            );
          },
          icon: const Icon(Icons.settings),
          label: const Text('WiFi Setup'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(250, 52),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure camera for router WiFi',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        // Connect via Router button - for cameras already on router
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Story 4 - Connect via router (LAN scan mode)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connect via Router - Coming in Story 4'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.home),
          label: const Text('Connect via Router'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(250, 52),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'For cameras already on your WiFi',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        // Direct Connection (AP) button - existing P2P test
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const P2PTestScreen()),
            );
          },
          icon: const Icon(Icons.wifi_tethering),
          label: const Text('Direct Connection (AP)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size(250, 52),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect to camera hotspot',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        // Find Cameras button (discovery)
        if (_sdkService.isReady)
          ElevatedButton.icon(
            onPressed: _proceedToDiscovery,
            icon: const Icon(Icons.search),
            label: const Text('Find Cameras'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
          ),
      ],
    );
  }
}
