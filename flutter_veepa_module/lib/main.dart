import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/screens/discovery_screen.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';

void main() {
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
  final VeepaSDKManager _sdkManager = VeepaSDKManager();

  @override
  void initState() {
    super.initState();
    _sdkManager.addListener(_onSDKStateChanged);
    _initializeSDK();
  }

  @override
  void dispose() {
    _sdkManager.removeListener(_onSDKStateChanged);
    super.dispose();
  }

  void _onSDKStateChanged() {
    setState(() {});
  }

  Future<void> _initializeSDK() async {
    await _sdkManager.initialize();
  }

  void _retryInitialization() {
    _sdkManager.reset();
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
    switch (_sdkManager.initState) {
      case SDKInitState.uninitialized:
        return Colors.grey;
      case SDKInitState.initializing:
        return Colors.orange;
      case SDKInitState.initialized:
        return Colors.green;
      case SDKInitState.failed:
        return Colors.red;
    }
  }

  Widget _buildStatusIndicator() {
    final state = _sdkManager.initState;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (state.isLoading) const SizedBox(width: 8),
            Text(
              'SDK Status: ${state.displayName}',
              style: TextStyle(
                fontSize: 16,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (state.isFailed && _sdkManager.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _sdkManager.errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    final state = _sdkManager.initState;

    if (state.isLoading) {
      return const SizedBox.shrink();
    }

    if (state.isFailed) {
      return ElevatedButton.icon(
        onPressed: _retryInitialization,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      );
    }

    if (state.isReady) {
      return ElevatedButton.icon(
        onPressed: _proceedToDiscovery,
        icon: const Icon(Icons.search),
        label: const Text('Find Cameras'),
      );
    }

    return const SizedBox.shrink();
  }
}
