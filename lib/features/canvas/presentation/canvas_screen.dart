import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora_background/aurora_background.dart';
import '../domain/services/image_composite_service.dart';
import 'providers/canvas_provider.dart';
import 'providers/alien_provider.dart';
import 'widgets/interactive_canvas.dart';
import 'widgets/conversation_panel.dart';
import 'widgets/neon_container.dart';
import 'widgets/resizable_split_view.dart';
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
  Size? _imageNaturalSize;

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
    _loadImageSize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(canvasProvider.notifier).clearStrokes();
      ref.read(alienProvider.notifier).dismiss();
    });
  }

  Future<void> _loadImageSize() async {
    try {
      final bytes = await _imageFile.readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (mounted) {
        setState(() {
          _imageNaturalSize = Size(
            descriptor.width.toDouble(),
            descriptor.height.toDouble(),
          );
        });
      }
      descriptor.dispose();
      buffer.dispose();
    } catch (_) {}
  }

  Future<Uint8List> _buildCompositeImage() async {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final containerSize = renderBox?.size ?? MediaQuery.of(context).size;
    final strokes = ref.read(canvasProvider).strokes;
    return _compositeService.composite(
      imageFile: _imageFile,
      strokes: strokes,
      containerSize: containerSize,
    );
  }

  Widget _buildInteractiveCanvas() {
    final canvasState = ref.watch(canvasProvider);
    return InteractiveCanvas(
      key: _canvasKey,
      imageFile: _imageFile,
      imageNaturalSize: _imageNaturalSize,
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

    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !mounted) return;

    try {
      final imageBytes = await _buildCompositeImage();
      if (!mounted) return;
      final alienState = ref.read(alienProvider);
      if (alienState.isActive) {
        ref.read(alienProvider.notifier).updateCompositeImage(imageBytes);
      }
    } catch (_) {}
  }

  Future<void> _onAskAI() async {
    if (!mounted) return;

    try {
      final imageBytes = await _buildCompositeImage();
      if (mounted) {
        await ref.read(alienProvider.notifier).startConversation(imageBytes);
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
                  IconButton(
                    icon: const Icon(Icons.undo, color: AppTheme.neonGreen),
                    tooltip: '되돌리기',
                    onPressed: hasStrokes
                        ? () =>
                            ref.read(canvasProvider.notifier).undoLastStroke()
                        : null,
                  ),
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
      floatingActionButton: alienState.isActive
          ? null
          : FloatingActionButton.extended(
              onPressed: _onAskAI,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('탐사 질문하기'),
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: AppTheme.spaceBlack,
            ),
      body: AuroraBackground(
        child: alienState.isActive
            ? ResizableSplitView(
                direction: Axis.vertical,
                initialLeftRatio: 0.38,
                leftChild: _buildInteractiveCanvas(),
                rightChild: const ConversationPanel(),
              )
            : _buildInteractiveCanvas(),
      ),
    );
  }
}
