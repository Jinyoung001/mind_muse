import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aurora_background/aurora_background.dart';
import 'widgets/image_source_sheet.dart';
import '../../canvas/presentation/canvas_screen.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
      body: AuroraBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.neonGlow,
                ),
                child: const Icon(
                  Icons.explore,
                  size: 100,
                  color: AppTheme.neonGreen,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'MIND MUSE',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.neonGreen,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                '우주 너머의 지식을 탐험하세요',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 80),
              ElevatedButton.icon(
                onPressed: () => _showImageSourceSheet(context),
                icon: const Icon(Icons.rocket_launch),
                label: const Text('탐사 시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: AppTheme.spaceBlack,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ).copyWith(
                  elevation: MaterialStateProperty.all(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
