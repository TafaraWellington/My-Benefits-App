import 'package:flutter/material.dart';

class WatermarkWrapper extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double size;

  const WatermarkWrapper({
    super.key,
    required this.child,
    this.opacity = 0.05,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Watermark in the background
        Positioned(
          bottom: -50,
          right: -50,
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              'assets/images/gold_protea_watermark.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        ),
        // The actual content
        child,
      ],
    );
  }
}
