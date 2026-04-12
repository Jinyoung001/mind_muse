import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/services/image_composite_service.dart';
import 'providers/canvas_provider.dart';
import 'providers/gemma_provider.dart';
import 'widgets/interactive_canvas.dart';
import 'widgets/conversation_panel.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const CanvasScreen({super.key, required this.imagePath});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  late final File _imageFile;
  final GlobalKey _canvasKey = GlobalKey();
  final _compositeService = ImageCompositeService();

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
    // 새 이미지로 진입할 때 이전 드로잉/대화 상태 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(canvasProvider.notifier).clearStrokes();
      ref.read(gemmaProvider.notifier).dismiss();
    });
  }

  Future<void> _onStrokeEnd() async {
    if (!mounted) return;

    // 획 완료 처리
    final stroke = ref.read(canvasProvider.notifier).endStroke();
    if (stroke == null) return;

    // 컨테이너 크기 측정
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final containerSize = renderBox.size;

    // 이미지 + 드로잉 합성
    final strokes = ref.read(canvasProvider).strokes;
    final imageBytes = await _compositeService.composite(
      imageFile: _imageFile,
      strokes: strokes,
      containerSize: containerSize,
    );

    // Gemma에 전달 (드로잉 있음)
    if (mounted) {
      await ref.read(gemmaProvider.notifier).startConversation(imageBytes);
    }
  }

  /// 드로잉 없이 전체 이미지를 AI에게 질문
  Future<void> _onAskAI() async {
    if (!mounted) return;

    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final containerSize = renderBox.size;

    final strokes = ref.read(canvasProvider).strokes;
    final imageBytes = await _compositeService.composite(
      imageFile: _imageFile,
      strokes: strokes,
      containerSize: containerSize,
    );

    if (mounted) {
      await ref.read(gemmaProvider.notifier).startConversation(
            imageBytes,
            hasDrawing: strokes.isNotEmpty,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gemmaState = ref.watch(gemmaProvider);
    final canvasState = ref.watch(canvasProvider);
    final hasStrokes = canvasState.strokes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MindMuse'),
        actions: [
          // 되돌리기
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '되돌리기',
            onPressed: hasStrokes
                ? () => ref.read(canvasProvider.notifier).undoLastStroke()
                : null,
          ),
          // 전체 초기화
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '드로잉 초기화',
            onPressed: () {
              ref.read(canvasProvider.notifier).clearStrokes();
              ref.read(gemmaProvider.notifier).dismiss();
            },
          ),
          // AI 질문 (드로잉 없이도 가능)
          if (!gemmaState.isLoading)
            IconButton(
              icon: const Icon(Icons.psychology_outlined),
              tooltip: 'AI에게 질문',
              onPressed: _onAskAI,
            ),
        ],
      ),
      body: Column(
        children: [
          // 메인 캔버스
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final canvasState = ref.watch(canvasProvider);
                return InteractiveCanvas(
                  key: _canvasKey,
                  imageFile: _imageFile,
                  strokes: canvasState.strokes,
                  currentPoints: canvasState.currentPoints,
                  onPanStart: (pos) =>
                      ref.read(canvasProvider.notifier).startStroke(pos),
                  onPanUpdate: (pos) =>
                      ref.read(canvasProvider.notifier).addPoint(pos),
                  onPanEnd: _onStrokeEnd,
                );
              },
            ),
          ),

          // 대화 패널 (활성 상태일 때만 표시)
          if (gemmaState.isActive) const ConversationPanel(),
        ],
      ),
    );
  }
}
