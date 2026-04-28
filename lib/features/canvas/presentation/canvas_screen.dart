import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora_background/aurora_background.dart';
import '../domain/services/image_composite_service.dart';
import 'providers/canvas_provider.dart';
import 'providers/alien_provider.dart';
import 'widgets/interactive_canvas.dart';
import 'widgets/conversation_panel.dart';
import 'widgets/neon_container.dart';
import '../../../core/theme/app_theme.dart';

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
      if (!mounted) return;
      ref.read(canvasProvider.notifier).clearStrokes();
      ref.read(alienProvider.notifier).dismiss();

      // 선제적 대화 시작: 이미지 분석 및 첫 질문 유도
      _onAskAI();
    });
  }

  Widget _buildInteractiveCanvas() {
    final canvasState = ref.watch(canvasProvider);
    return InteractiveCanvas(
      key: _canvasKey,
      imageFile: _imageFile,
      strokes: canvasState.strokes,
      currentPoints: canvasState.currentPoints,
      onPanStart: (pos) => ref.read(canvasProvider.notifier).startStroke(pos),
      onPanUpdate: (pos) => ref.read(canvasProvider.notifier).addPoint(pos),
      onPanEnd: _onStrokeEnd,
    );
  }

  Future<void> _onStrokeEnd() async {
    if (!mounted) return;
    final stroke = ref.read(canvasProvider.notifier).endStroke();
    if (stroke == null) return;

    // 획이 완성될 때마다 합성 이미지 갱신
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null && !mounted) return;
    final containerSize = renderBox?.size ?? MediaQuery.of(context).size;

    try {
      final strokes = ref.read(canvasProvider).strokes;
      final imageBytes = await _compositeService.composite(
        imageFile: _imageFile,
        strokes: strokes,
        containerSize: containerSize,
      );
      if (!mounted) return;
      // 대화가 이미 시작된 경우 → 합성 이미지만 업데이트 (대화 흐름 유지)
      final alienState = ref.read(alienProvider);
      if (alienState.isActive) {
        ref.read(alienProvider.notifier).updateCompositeImage(imageBytes);
      }
      // 비활성 상태면 FAB이 보이므로 사용자가 직접 시작 — 아무것도 안 함
    } catch (e) {
      // 합성 실패 시 무시 (드로잉 계속 가능)
    }
  }

  /// 드로잉 없이 전체 이미지를 AI에게 질문
  Future<void> _onAskAI() async {
    if (!mounted) return;

    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final containerSize = renderBox?.size ?? MediaQuery.of(context).size;

    try {
      final strokes = ref.read(canvasProvider).strokes;
      final imageBytes = await _compositeService.composite(
        imageFile: _imageFile,
        strokes: strokes,
        containerSize: containerSize,
      );

      if (mounted) {
        await ref.read(alienProvider.notifier).startConversation(
              imageBytes,
              hasDrawing: strokes.isNotEmpty,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // API 에러 발생 시 SnackBar로 표시
    ref.listen(alienProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    final alienState = ref.watch(alienProvider);
    final canvasState = ref.watch(canvasProvider);
    final hasStrokes = canvasState.strokes.isNotEmpty;
    final shouldShowSplitView = alienState.isActive || alienState.isLoading;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('MIND MUSE'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: NeonContainer(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              neonColor: AppTheme.neonGreen,
              borderRadius: 8,
              blurRadius: 10,
              backgroundColor: AppTheme.spaceBlack.withOpacity(0.5),
              child: Row(
                children: [
                  // 되돌리기
                  IconButton(
                    icon: const Icon(Icons.undo, color: AppTheme.neonGreen),
                    tooltip: '되돌리기',
                    onPressed: hasStrokes
                        ? () =>
                            ref.read(canvasProvider.notifier).undoLastStroke()
                        : null,
                  ),
                  // 전체 초기화
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.neonGreen),
                    tooltip: '드로잉 초기화',
                    onPressed: () {
                      ref.read(canvasProvider.notifier).clearStrokes();
                      ref.read(alienProvider.notifier).dismiss();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !shouldShowSplitView
          ? FloatingActionButton.extended(
              onPressed: _onAskAI,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('탐사 질문하기'),
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: AppTheme.spaceBlack,
            )
          : null,
      body: AuroraBackground(
        child: shouldShowSplitView
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      SizedBox(
                        height: constraints.maxHeight * 0.38,
                        child: _buildInteractiveCanvas(),
                      ),
                      const Expanded(child: ConversationPanel()),
                    ],
                  );
                },
              )
            : _buildInteractiveCanvas(),
      ),
    );
  }
}

