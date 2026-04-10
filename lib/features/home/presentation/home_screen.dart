import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/image_source_sheet.dart';
import '../../canvas/presentation/canvas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ImageSourceSheet(
        onImageSelected: (XFile image) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CanvasScreen(imagePath: image.path),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 80, color: Color(0xFF4A90D9)),
            const SizedBox(height: 24),
            const Text(
              'MindMuse',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '교과서를 찍고, 궁금한 곳에 표시해보세요',
              style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _showImageSourceSheet(context),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('시작하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
