import 'package:flutter/material.dart';

class CanvasScreen extends StatelessWidget {
  final String imagePath;
  const CanvasScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캔버스')),
      body: Center(child: Text('이미지 경로: $imagePath')),
    );
  }
}
