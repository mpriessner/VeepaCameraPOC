import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/services/camera_connection_detector.dart';

/// Widget that displays progress and status of camera detection
class DetectionProgressIndicator extends StatelessWidget {
  /// The camera connection detector service
  final CameraConnectionDetector detector;

  /// Optional message to display
  final String? message;

  /// Callback when cancel is pressed
  final VoidCallback? onCancel;

  /// Callback when retry is pressed (shown on timeout/error)
  final VoidCallback? onRetry;

  const DetectionProgressIndicator({
    super.key,
    required this.detector,
    this.message,
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: detector,
      builder: (context, child) {
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (detector.state) {
      case DetectionState.idle:
        return _buildIdleState(context);
      case DetectionState.detecting:
        return _buildDetectingState(context);
      case DetectionState.found:
        return _buildFoundState(context);
      case DetectionState.timeout:
        return _buildTimeoutState(context);
      case DetectionState.error:
        return _buildErrorState(context);
    }
  }

  Widget _buildIdleState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.wifi_find,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          message ?? 'Ready to detect camera',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDetectingState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: detector.progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            Icon(
              Icons.camera_alt,
              size: 32,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          message ?? 'Waiting for camera to connect...',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Attempt ${detector.attemptCount}/${detector.maxAttempts}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: detector.progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'The camera will reboot and connect to WiFi',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
        if (onCancel != null) ...[
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel'),
          ),
        ],
      ],
    );
  }

  Widget _buildFoundState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Camera Connected!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message ?? 'Your camera is now connected to WiFi',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimeoutState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.timer_off,
            size: 64,
            color: Colors.orange.shade600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Camera Not Found',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message ?? 'Could not connect to the camera.\nMake sure the camera is powered on.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (onRetry != null)
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        if (onCancel != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Detection Failed',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message ?? 'An error occurred during detection',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (onRetry != null)
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        if (onCancel != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ],
      ],
    );
  }
}
