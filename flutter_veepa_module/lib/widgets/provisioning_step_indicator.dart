import 'package:flutter/material.dart';

/// Steps in the visual provisioning flow
enum ProvisioningStep {
  /// Step 1: Scan camera QR code
  scanCamera,

  /// Step 2: Connect to camera AP
  connectToAP,

  /// Step 3: Enter home WiFi credentials
  enterWifiCreds,

  /// Step 4: Show QR to camera
  showQR,

  /// Step 5: Detecting camera on network
  detecting,

  /// Step 6: Success
  success,

  /// Error state
  failure,
}

extension ProvisioningStepExtension on ProvisioningStep {
  /// Get the display name for this step
  String get displayName {
    switch (this) {
      case ProvisioningStep.scanCamera:
        return 'Scan';
      case ProvisioningStep.connectToAP:
        return 'Connect';
      case ProvisioningStep.enterWifiCreds:
        return 'WiFi';
      case ProvisioningStep.showQR:
        return 'QR Code';
      case ProvisioningStep.detecting:
        return 'Detect';
      case ProvisioningStep.success:
        return 'Done';
      case ProvisioningStep.failure:
        return 'Error';
    }
  }

  /// Get the step number (1-based)
  int get stepNumber {
    switch (this) {
      case ProvisioningStep.scanCamera:
        return 1;
      case ProvisioningStep.connectToAP:
        return 2;
      case ProvisioningStep.enterWifiCreds:
        return 3;
      case ProvisioningStep.showQR:
        return 4;
      case ProvisioningStep.detecting:
        return 5;
      case ProvisioningStep.success:
        return 6;
      case ProvisioningStep.failure:
        return 0;
    }
  }

  /// Whether this is a progress step (not success/failure)
  bool get isProgressStep {
    return this != ProvisioningStep.success && this != ProvisioningStep.failure;
  }
}

/// Widget that displays the current step in the provisioning flow
class ProvisioningStepIndicator extends StatelessWidget {
  /// Current step in the flow
  final ProvisioningStep currentStep;

  /// Total number of steps (excluding success/failure)
  static const int totalSteps = 5;

  const ProvisioningStepIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    if (!currentStep.isProgressStep) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          final stepNumber = index + 1;
          final isCompleted = currentStep.stepNumber > stepNumber;
          final isCurrent = currentStep.stepNumber == stepNumber;

          return Row(
            children: [
              if (index > 0)
                Container(
                  width: 24,
                  height: 2,
                  color: isCompleted
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
              _buildStepDot(context, stepNumber, isCompleted, isCurrent),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepDot(
    BuildContext context,
    int stepNumber,
    bool isCompleted,
    bool isCurrent,
  ) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? Theme.of(context).primaryColor
            : isCurrent
                ? Theme.of(context).primaryColor.withOpacity(0.2)
                : Colors.grey.shade200,
        border: isCurrent
            ? Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              )
            : null,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text(
                '$stepNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCurrent
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                ),
              ),
      ),
    );
  }
}

/// Compact step indicator showing "Step X of Y"
class CompactStepIndicator extends StatelessWidget {
  /// Current step in the flow
  final ProvisioningStep currentStep;

  const CompactStepIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    if (!currentStep.isProgressStep) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Step ${currentStep.stepNumber} of ${ProvisioningStepIndicator.totalSteps}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
