import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/models/ptz_direction.dart';
import 'package:veepa_camera_poc/services/veepa_ptz_service.dart';

/// Semi-transparent PTZ controls overlay for camera pan/tilt/zoom control
class PTZControlsOverlay extends StatelessWidget {
  /// Whether controls are visible
  final bool visible;

  /// Callback when visibility toggle is requested
  final VoidCallback? onToggleVisibility;

  const PTZControlsOverlay({
    super.key,
    this.visible = true,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // D-Pad (left side)
              _DirectionalPad(),

              // Zoom controls (right side)
              _ZoomControls(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Directional pad for pan/tilt control
class _DirectionalPad extends StatelessWidget {
  final VeepaPTZService _ptzService = VeepaPTZService();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(80),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Up
          Positioned(
            top: 8,
            child: PTZButton(
              icon: Icons.keyboard_arrow_up,
              direction: PTZDirection.tiltUp,
              ptzService: _ptzService,
            ),
          ),

          // Down
          Positioned(
            bottom: 8,
            child: PTZButton(
              icon: Icons.keyboard_arrow_down,
              direction: PTZDirection.tiltDown,
              ptzService: _ptzService,
            ),
          ),

          // Left
          Positioned(
            left: 8,
            child: PTZButton(
              icon: Icons.keyboard_arrow_left,
              direction: PTZDirection.panLeft,
              ptzService: _ptzService,
            ),
          ),

          // Right
          Positioned(
            right: 8,
            child: PTZButton(
              icon: Icons.keyboard_arrow_right,
              direction: PTZDirection.panRight,
              ptzService: _ptzService,
            ),
          ),

          // Diagonal: Up-Left
          Positioned(
            top: 24,
            left: 24,
            child: PTZButton(
              icon: Icons.north_west,
              direction: PTZDirection.panLeftTiltUp,
              size: 32,
              ptzService: _ptzService,
            ),
          ),

          // Diagonal: Up-Right
          Positioned(
            top: 24,
            right: 24,
            child: PTZButton(
              icon: Icons.north_east,
              direction: PTZDirection.panRightTiltUp,
              size: 32,
              ptzService: _ptzService,
            ),
          ),

          // Diagonal: Down-Left
          Positioned(
            bottom: 24,
            left: 24,
            child: PTZButton(
              icon: Icons.south_west,
              direction: PTZDirection.panLeftTiltDown,
              size: 32,
              ptzService: _ptzService,
            ),
          ),

          // Diagonal: Down-Right
          Positioned(
            bottom: 24,
            right: 24,
            child: PTZButton(
              icon: Icons.south_east,
              direction: PTZDirection.panRightTiltDown,
              size: 32,
              ptzService: _ptzService,
            ),
          ),

          // Center dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Zoom controls column
class _ZoomControls extends StatelessWidget {
  final VeepaPTZService _ptzService = VeepaPTZService();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Zoom label
        Text(
          'ZOOM',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Zoom In
        ZoomButton(
          icon: Icons.add,
          zoomDirection: ZoomDirection.zoomIn,
          ptzService: _ptzService,
        ),
        const SizedBox(height: 16),

        // Zoom Out
        ZoomButton(
          icon: Icons.remove,
          zoomDirection: ZoomDirection.zoomOut,
          ptzService: _ptzService,
        ),
      ],
    );
  }
}

/// Individual PTZ button with press-and-hold support for pan/tilt
class PTZButton extends StatefulWidget {
  final IconData icon;
  final PTZDirection direction;
  final double size;
  final VeepaPTZService ptzService;

  const PTZButton({
    super.key,
    required this.icon,
    required this.direction,
    this.size = 40,
    required this.ptzService,
  });

  @override
  State<PTZButton> createState() => _PTZButtonState();
}

class _PTZButtonState extends State<PTZButton> {
  bool _isPressed = false;

  void _handlePressStart() {
    setState(() => _isPressed = true);
    widget.ptzService.startMovement(widget.direction);
  }

  void _handlePressEnd() {
    setState(() => _isPressed = false);
    widget.ptzService.stopMovement();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handlePressStart(),
      onTapUp: (_) => _handlePressEnd(),
      onTapCancel: _handlePressEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.white.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isPressed ? Colors.white : Colors.white.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}

/// Zoom button with press-and-hold support
class ZoomButton extends StatefulWidget {
  final IconData icon;
  final ZoomDirection zoomDirection;
  final double size;
  final VeepaPTZService ptzService;

  const ZoomButton({
    super.key,
    required this.icon,
    required this.zoomDirection,
    this.size = 48,
    required this.ptzService,
  });

  @override
  State<ZoomButton> createState() => _ZoomButtonState();
}

class _ZoomButtonState extends State<ZoomButton> {
  bool _isPressed = false;

  void _handlePressStart() {
    setState(() => _isPressed = true);
    widget.ptzService.startZoom(widget.zoomDirection);
  }

  void _handlePressEnd() {
    setState(() => _isPressed = false);
    widget.ptzService.stopZoom();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handlePressStart(),
      onTapUp: (_) => _handlePressEnd(),
      onTapCancel: _handlePressEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.blue.withOpacity(0.7)
              : Colors.blue.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isPressed ? Colors.white : Colors.white.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}
