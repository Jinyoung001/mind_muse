import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/text_block_model.dart';
import 'providers/ocr_provider.dart';
import 'widgets/interactive_canvas.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const CanvasScreen({super.key, required this.imagePath});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  late final File _imageFile;
  Size? _imageSize;
  bool _showDebug = true;

  // 이미지가 화면에 실제로 표시되는 크기를 측정하기 위한 GlobalKey
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
    _loadImageAndRunOcr();
  }

  Future<void> _loadImageAndRunOcr() async {
    // 원본 이미지 크기 로드
    final decodedImage = await decodeImageFromList(
      await _imageFile.readAsBytes(),
    );
    final imgSize = Size(
      decodedImage.width.toDouble(),
      decodedImage.height.toDouble(),
    );
    setState(() => _imageSize = imgSize);

    // 화면 렌더링 후 컨테이너 크기 측정 및 OCR 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox =
          _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        // 컨테이너 크기를 측정할 수 없는 경우 에러 상태로 전환
        ref.read(ocrProvider.notifier).setError('캔버스 크기를 측정할 수 없습니다. 다시 시도해주세요.');
        return;
      }
      final containerSize = renderBox.size;
      ref.read(ocrProvider.notifier).runOcr(
            imageFile: _imageFile,
            imageSize: _imageSize!,
            containerSize: containerSize,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrProvider);
    final textBlocks = ocrState.blocks.valueOrNull ?? <TextBlockModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindMuse'),
        actions: [
          // 디버그 BBox 토글 버튼
          IconButton(
            icon: Icon(_showDebug ? Icons.visibility : Icons.visibility_off),
            tooltip: 'OCR 디버그 표시',
            onPressed: () => setState(() => _showDebug = !_showDebug),
          ),
        ],
      ),
      body: Column(
        children: [
          // OCR 상태 표시 배너
          ocrState.blocks.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: Text('OCR 오류: $e'),
            ),
            data: (blocks) => Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.all(8),
              child: Text('텍스트 블록 ${blocks.length}개 인식됨'),
            ),
          ),

          // 메인 캔버스
          Expanded(
            child: InteractiveCanvas(
              key: _canvasKey,
              imageFile: _imageFile,
              textBlocks: textBlocks,
              showDebug: _showDebug,
            ),
          ),
        ],
      ),
    );
  }
}
