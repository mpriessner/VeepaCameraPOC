import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/services/veepa_ptz_service.dart';

/// Speed control slider for PTZ movements
class PTZSpeedSlider extends StatefulWidget {
  const PTZSpeedSlider({super.key});

  @override
  State<PTZSpeedSlider> createState() => _PTZSpeedSliderState();
}

class _PTZSpeedSliderState extends State<PTZSpeedSlider> {
  final VeepaPTZService _ptzService = VeepaPTZService();

  @override
  void initState() {
    super.initState();
    _ptzService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _ptzService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: _ptzService.speed.toDouble(),
                min: 0,
                max: 100,
                divisions: 10,
                activeColor: Colors.blue,
                inactiveColor: Colors.white30,
                onChanged: (value) {
                  _ptzService.speed = value.toInt();
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 36,
            child: Text(
              '${_ptzService.speed}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
