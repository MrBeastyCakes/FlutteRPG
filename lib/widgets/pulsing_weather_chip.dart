import 'package:flutter/material.dart';
import '../models/weather.dart';

class PulsingWeatherChip extends StatefulWidget {
  final CoastWeather weather;
  const PulsingWeatherChip({super.key, required this.weather});

  @override
  State<PulsingWeatherChip> createState() => _PulsingWeatherChipState();
}

class _PulsingWeatherChipState extends State<PulsingWeatherChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.weather == CoastWeather.stormSwell) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PulsingWeatherChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weather == CoastWeather.stormSwell) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    switch (widget.weather) {
      case CoastWeather.calm:
        label = '🌤️ Calm';
        color = Colors.green;
        break;
      case CoastWeather.seaFog:
        label = '🌫️ Sea Fog';
        color = Colors.grey;
        break;
      case CoastWeather.stormSwell:
        label = '⛈️ Storm Swell';
        color = Colors.redAccent;
        break;
    }

    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
