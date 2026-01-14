/// PTZ (Pan-Tilt-Zoom) movement directions
enum PTZDirection {
  /// No movement (stop)
  stop,

  /// Pan camera left
  panLeft,

  /// Pan camera right
  panRight,

  /// Tilt camera up
  tiltUp,

  /// Tilt camera down
  tiltDown,

  /// Pan left and tilt up
  panLeftTiltUp,

  /// Pan left and tilt down
  panLeftTiltDown,

  /// Pan right and tilt up
  panRightTiltUp,

  /// Pan right and tilt down
  panRightTiltDown,
}

/// Zoom direction
enum ZoomDirection {
  /// No zoom (stop)
  stop,

  /// Zoom in
  zoomIn,

  /// Zoom out
  zoomOut,
}

/// Extension methods for PTZDirection
extension PTZDirectionExtension on PTZDirection {
  /// Get SDK command code for this direction
  /// Based on Veepa SDK motor_command.dart structure
  int get commandCode {
    switch (this) {
      case PTZDirection.stop:
        return 0;
      case PTZDirection.panLeft:
        return 4;
      case PTZDirection.panRight:
        return 6;
      case PTZDirection.tiltUp:
        return 2;
      case PTZDirection.tiltDown:
        return 8;
      case PTZDirection.panLeftTiltUp:
        return 1;
      case PTZDirection.panLeftTiltDown:
        return 7;
      case PTZDirection.panRightTiltUp:
        return 3;
      case PTZDirection.panRightTiltDown:
        return 9;
    }
  }

  /// User-friendly display name
  String get displayName {
    switch (this) {
      case PTZDirection.stop:
        return 'Stop';
      case PTZDirection.panLeft:
        return 'Pan Left';
      case PTZDirection.panRight:
        return 'Pan Right';
      case PTZDirection.tiltUp:
        return 'Tilt Up';
      case PTZDirection.tiltDown:
        return 'Tilt Down';
      case PTZDirection.panLeftTiltUp:
        return 'Pan Left + Tilt Up';
      case PTZDirection.panLeftTiltDown:
        return 'Pan Left + Tilt Down';
      case PTZDirection.panRightTiltUp:
        return 'Pan Right + Tilt Up';
      case PTZDirection.panRightTiltDown:
        return 'Pan Right + Tilt Down';
    }
  }

  /// Whether this is a pan movement
  bool get isPan {
    return this == PTZDirection.panLeft ||
        this == PTZDirection.panRight ||
        this == PTZDirection.panLeftTiltUp ||
        this == PTZDirection.panLeftTiltDown ||
        this == PTZDirection.panRightTiltUp ||
        this == PTZDirection.panRightTiltDown;
  }

  /// Whether this is a tilt movement
  bool get isTilt {
    return this == PTZDirection.tiltUp ||
        this == PTZDirection.tiltDown ||
        this == PTZDirection.panLeftTiltUp ||
        this == PTZDirection.panLeftTiltDown ||
        this == PTZDirection.panRightTiltUp ||
        this == PTZDirection.panRightTiltDown;
  }
}

/// Extension methods for ZoomDirection
extension ZoomDirectionExtension on ZoomDirection {
  /// Get SDK command code for zoom
  int get commandCode {
    switch (this) {
      case ZoomDirection.stop:
        return 0;
      case ZoomDirection.zoomIn:
        return 16;
      case ZoomDirection.zoomOut:
        return 32;
    }
  }

  /// User-friendly display name
  String get displayName {
    switch (this) {
      case ZoomDirection.stop:
        return 'Stop';
      case ZoomDirection.zoomIn:
        return 'Zoom In';
      case ZoomDirection.zoomOut:
        return 'Zoom Out';
    }
  }
}
