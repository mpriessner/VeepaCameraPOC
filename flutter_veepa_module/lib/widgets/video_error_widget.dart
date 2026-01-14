import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/models/video_error_type.dart';

/// Widget displayed when video error occurs
class VideoErrorWidget extends StatelessWidget {
  final VideoErrorType errorType;
  final String? technicalError;
  final VoidCallback onRetry;
  final VoidCallback onGoBack;
  final bool showTechnicalDetails;

  const VideoErrorWidget({
    super.key,
    required this.errorType,
    this.technicalError,
    required this.onRetry,
    required this.onGoBack,
    this.showTechnicalDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Icon(
                _getErrorIcon(),
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),

              // Error title
              Text(
                errorType.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // User-friendly message
              Text(
                errorType.userMessage,
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),

              // Technical details (debug mode)
              if (showTechnicalDetails && technicalError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    technicalError!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onGoBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),

              // Recovery hint
              if (errorType.isRecoverable) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'This error may resolve automatically',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (errorType) {
      case VideoErrorType.bufferingTimeout:
        return Icons.hourglass_empty;
      case VideoErrorType.networkError:
        return Icons.wifi_off;
      case VideoErrorType.streamEnded:
        return Icons.videocam_off;
      case VideoErrorType.decodeError:
        return Icons.broken_image;
      default:
        return Icons.error_outline;
    }
  }
}
