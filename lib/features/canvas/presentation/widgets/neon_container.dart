import 'package:flutter/material.dart';

class NeonContainer extends StatelessWidget {
  final Widget child;
  final Color neonColor;
  final double blurRadius;
  final double spreadRadius;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const NeonContainer({
    super.key,
    required this.child,
    this.neonColor = Colors.cyanAccent,
    this.blurRadius = 15.0,
    this.spreadRadius = 1.0,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(12.0),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: neonColor.withOpacity(0.8),
          width: 2.0,
        ),
        boxShadow: [
          // Outer Glow
          BoxShadow(
            color: neonColor.withOpacity(0.4),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
          // Inner Glow (simulated)
          BoxShadow(
            color: neonColor.withOpacity(0.2),
            blurRadius: blurRadius / 2,
            spreadRadius: -spreadRadius,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
