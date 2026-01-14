import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/models/extracted_frame.dart';
import 'package:veepa_camera_poc/services/frame_extraction_service.dart';

/// Test widget for validating frame extraction capabilities
class FrameExtractionTest extends StatefulWidget {
  /// Texture ID from the video player
  final int textureId;

  /// Optional RepaintBoundary key for screenshot fallback
  final GlobalKey? repaintBoundaryKey;

  const FrameExtractionTest({
    super.key,
    required this.textureId,
    this.repaintBoundaryKey,
  });

  @override
  State<FrameExtractionTest> createState() => _FrameExtractionTestState();
}

class _FrameExtractionTestState extends State<FrameExtractionTest> {
  final FrameExtractionService _service = FrameExtractionService();

  ExtractedFrame? _lastFrame;
  Uint8List? _lastFramePng;
  String _status = 'Not started';
  final List<String> _logs = [];
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _service.stopExtraction();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {
        _lastFrame = _service.lastFrame;
      });
    }
  }

  void _log(String message) {
    setState(() {
      final timestamp = DateTime.now().toIso8601String().substring(11, 23);
      _logs.add('[$timestamp] $message');
      if (_logs.length > 50) _logs.removeAt(0);
    });
  }

  Future<void> _startExtraction() async {
    _log('Starting frame extraction...');
    setState(() => _status = 'Starting...');

    try {
      await _service.startExtraction(
        textureId: widget.textureId,
        repaintBoundaryKey: widget.repaintBoundaryKey,
        onFrame: _onFrameReceived,
      );
      setState(() => _status = 'Extracting');
      _log('Frame extraction started');
    } catch (e) {
      _log('Error: $e');
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _stopExtraction() async {
    _log('Stopping frame extraction...');
    await _service.stopExtraction();
    setState(() => _status = 'Stopped');
    _log('Frame extraction stopped. Total frames: ${_service.frameCount}');
  }

  void _onFrameReceived(ExtractedFrame frame) {
    // Log every 30th frame to avoid spam
    if (frame.frameNumber % 30 == 1) {
      _log('Frame #${frame.frameNumber}: ${frame.width}x${frame.height}, '
          '${frame.sizeKB.toStringAsFixed(1)}KB, '
          'FPS: ${_service.extractionFPS.toStringAsFixed(1)}');
    }
  }

  Future<void> _convertToPng() async {
    if (_lastFrame == null) {
      _log('No frame to convert');
      return;
    }

    setState(() => _isConverting = true);
    _log('Converting frame #${_lastFrame!.frameNumber} to PNG...');

    try {
      final png = await _service.frameToPng(_lastFrame!);

      if (png != null) {
        setState(() => _lastFramePng = png);
        _log('PNG conversion successful: ${(png.length / 1024).toStringAsFixed(1)}KB');

        // Verify PNG header
        if (png.length >= 4 &&
            png[0] == 0x89 &&
            png[1] == 0x50 &&
            png[2] == 0x4E &&
            png[3] == 0x47) {
          _log('PNG header verified (valid PNG format)');
        } else {
          _log('WARNING: Invalid PNG header');
        }
      } else {
        _log('PNG conversion failed');
      }
    } catch (e) {
      _log('PNG conversion error: $e');
    } finally {
      setState(() => _isConverting = false);
    }
  }

  void _clearPng() {
    setState(() {
      _lastFramePng = null;
    });
    _log('PNG preview cleared');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.camera, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Frame Extraction Test',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _service.isExtracting ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _service.isExtracting ? 'ACTIVE' : 'IDLE',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statistics
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                _buildStatRow('Status', _status),
                _buildStatRow('Texture ID', '${widget.textureId}'),
                _buildStatRow('Frames', '${_service.frameCount}'),
                _buildStatRow('FPS', '${_service.extractionFPS.toStringAsFixed(1)}'),
                if (_lastFrame != null) ...[
                  const Divider(color: Colors.white24),
                  _buildStatRow('Dimensions', '${_lastFrame!.width}x${_lastFrame!.height}'),
                  _buildStatRow('Data Size', '${_lastFrame!.sizeKB.toStringAsFixed(1)} KB'),
                  _buildStatRow('Format', _lastFrame!.format.toUpperCase()),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Controls
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _service.isExtracting ? null : _startExtraction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Start'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _service.isExtracting ? _stopExtraction : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.stop, size: 18),
                  label: const Text('Stop'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_lastFrame != null && !_isConverting) ? _convertToPng : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isConverting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.image, size: 18),
                  label: const Text('PNG'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // PNG Preview
          if (_lastFramePng != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'PNG Preview',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      '${(_lastFramePng!.length / 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _clearPng,
                      child: const Icon(Icons.close, color: Colors.grey, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _lastFramePng!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Text(
                          'Invalid image data',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Logs
          const Text(
            'Logs',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  final logIndex = _logs.length - 1 - index;
                  return Text(
                    _logs[logIndex],
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
