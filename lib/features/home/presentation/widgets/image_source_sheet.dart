import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';

class ImageSourceSheet extends StatelessWidget {
  final void Function(XFile image) onImageSelected;

  const ImageSourceSheet({super.key, required this.onImageSelected});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (image != null && context.mounted) {
      Navigator.pop(context);
      onImageSelected(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.spaceBlack.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonGreen.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                '교과서 데이터 스캔',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonGreen,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Divider(color: AppTheme.neonGreen.withOpacity(0.2)),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.neonGreen),
              title: const Text('광학 카메라 스캔', style: TextStyle(color: Colors.white)),
              onTap: () => _pickImage(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.neonGreen),
              title: const Text('데이터베이스에서 선택', style: TextStyle(color: Colors.white)),
              onTap: () => _pickImage(context, ImageSource.gallery),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
