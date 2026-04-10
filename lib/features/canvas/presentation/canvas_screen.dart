import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/text_block_model.dart';
import 'providers/canvas_provider.dart';
import 'providers/ocr_provider.dart';
import 'providers/gemma_provider.dart';
import 'widgets/interactive_canvas.dart';
import 'widgets/speech_bubble_widget.dart';
import '../domain/services/intersection_service.dart';

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

  void _onStrokeEnd() {
    if (!mounted) return;
    final stroke = ref.read(canvasProvider.notifier).endStroke();
    if (stroke == null) return;

    final textBlocks = ref.read(ocrProvider).blocks.valueOrNull ?? [];
    final hits = IntersectionService.findHits(
      stroke: stroke,
      textBlocks: textBlocks,
    );

    if (hits.isNotEmpty) {
      ref.read(gemmaProvider.notifier).ask(
            selectedTexts: hits,
            position: stroke.center,
          );
    }
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
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '드로잉 초기화',
            onPressed: () =>
                ref.read(canvasProvider.notifier).clearStrokes(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
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
                child: Consumer(
                  builder: (context, ref, _) {
                    final canvasState = ref.watch(canvasProvider);
                    return InteractiveCanvas(
                      key: _canvasKey,
                      imageFile: _imageFile,
                      textBlocks: textBlocks,
                      strokes: canvasState.strokes,
                      currentPoints: canvasState.currentPoints,
                      showDebug: _showDebug,
                      onPanStart: (pos) =>
                          ref.read(canvasProvider.notifier).startStroke(pos),
                      onPanUpdate: (pos) =>
                          ref.read(canvasProvider.notifier).addPoint(pos),
                      onPanEnd: _onStrokeEnd,
                    );
                  },
                ),
              ),
            ],
          ),

          // 말풍선 오버레이
          Consumer(
            builder: (context, ref, _) {
              final gemmaState = ref.watch(gemmaProvider);
              return gemmaState.bubble.when(
                loading: () => Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('생각 중...'),
                        ],
                      ),
                    ),
                  ),
                ),
                error: (e, _) => const SizedBox.shrink(),
                data: (bubble) {
                  if (bubble == null) return const SizedBox.shrink();
                  return SpeechBubbleWidget(
                    message: bubble.message,
                    targetPosition: bubble.position,
                    onDismiss: () =>
                        ref.read(gemmaProvider.notifier).dismiss(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
