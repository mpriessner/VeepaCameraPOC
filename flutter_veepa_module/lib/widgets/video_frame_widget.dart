import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Video frame data
class VideoFrame {
  final Uint8List data;
  final int width;
  final int height;
  final DateTime timestamp;

  VideoFrame({
    required this.data,
    required this.width,
    required this.height,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Widget to display video frames
class VideoFrameWidget extends StatefulWidget {
  final Stream<VideoFrame>? frameStream;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const VideoFrameWidget({
    super.key,
    this.frameStream,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<VideoFrameWidget> createState() => _VideoFrameWidgetState();
}

class _VideoFrameWidgetState extends State<VideoFrameWidget> {
  Uint8List? _currentFrame;
  StreamSubscription<VideoFrame>? _subscription;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _subscribeToStream();
  }

  @override
  void didUpdateWidget(VideoFrameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frameStream != oldWidget.frameStream) {
      _subscribeToStream();
    }
  }

  void _subscribeToStream() {
    _subscription?.cancel();
    _currentFrame = null;
    _hasError = false;

    if (widget.frameStream != null) {
      _subscription = widget.frameStream!.listen(
        _onFrameReceived,
        onError: _onError,
      );
    }
  }

  void _onFrameReceived(VideoFrame frame) {
    if (mounted) {
      setState(() {
        _currentFrame = frame.data;
        _hasError = false;
      });
    }
  }

  void _onError(dynamic error) {
    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ??
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 8),
                Text('Video error', style: TextStyle(color: Colors.red)),
              ],
            ),
          );
    }

    if (_currentFrame == null) {
      return widget.placeholder ??
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading video...'),
              ],
            ),
          );
    }

    return Image.memory(
      _currentFrame!,
      fit: widget.fit,
      gaplessPlayback: true, // Prevents flickering between frames
    );
  }
}

/// Simple widget for displaying static frame data
class StaticFrameWidget extends StatelessWidget {
  final Uint8List? frameData;
  final BoxFit fit;
  final Widget? placeholder;

  const StaticFrameWidget({
    super.key,
    this.frameData,
    this.fit = BoxFit.contain,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (frameData == null) {
      return placeholder ??
          Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            ),
          );
    }

    return Image.memory(
      frameData!,
      fit: fit,
      gaplessPlayback: true,
    );
  }
}
