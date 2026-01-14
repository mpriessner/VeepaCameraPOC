import 'package:flutter/material.dart';

/// Overlay shown when connection is lost
class DisconnectionOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onGoBack;
  final String? errorMessage;
  final int reconnectAttempt;
  final int maxAttempts;
  final bool isReconnecting;

  const DisconnectionOverlay({
    super.key,
    required this.onRetry,
    required this.onGoBack,
    this.errorMessage,
    this.reconnectAttempt = 0,
    this.maxAttempts = 3,
    this.isReconnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                isReconnecting ? Icons.sync : Icons.signal_wifi_off,
                size: 64,
                color: isReconnecting ? Colors.orange : Colors.red,
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isReconnecting ? 'Reconnecting...' : 'Connection Lost',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                isReconnecting
                    ? 'Attempt $reconnectAttempt of $maxAttempts'
                    : errorMessage ?? 'The connection to the camera was lost.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Progress indicator (if reconnecting)
              if (isReconnecting) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 24),
              ],

              // Buttons
              if (!isReconnecting)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onGoBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Camera List'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
