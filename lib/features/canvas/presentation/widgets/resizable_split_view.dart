import 'package:flutter/material.dart';
import 'package:mind_muse/core/theme/app_theme.dart';

/// 두 영역을 드래그로 크기 조절할 수 있는 분할 뷰.
/// [direction]이 Axis.horizontal이면 좌우, Axis.vertical이면 상하 분할.
class ResizableSplitView extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;
  final double initialLeftRatio;
  final Axis direction;

  const ResizableSplitView({
    super.key,
    required this.leftChild,
    required this.rightChild,
    this.initialLeftRatio = 0.7,
    this.direction = Axis.horizontal,
  });

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  late double _primaryRatio;
  bool _isDragging = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _primaryRatio = widget.initialLeftRatio;
  }

  Widget _buildDivider({required bool isVertical, required VoidCallback onEnter, required VoidCallback onExit, required GestureDragUpdateCallback onDragUpdate, required GestureDragStartCallback onDragStart, required GestureDragEndCallback onDragEnd, required GestureDragCancelCallback onDragCancel}) {
    final isActive = _isDragging || _isHovering;
    final lineColor = isActive
        ? AppTheme.neonGreen
        : AppTheme.neonGreen.withValues(alpha: 0.3);

    final indicator = Stack(
      alignment: Alignment.center,
      children: [
        // 얇은 구분선
        AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: isVertical ? double.infinity : 2,
          height: isVertical ? 2 : double.infinity,
          decoration: BoxDecoration(
            color: lineColor,
            boxShadow: isActive ? AppTheme.neonGlow : [],
          ),
        ),
        // 가운데 드래그 핸들 (타원형 필)
        AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: isVertical ? 40 : 8,
          height: isVertical ? 8 : 40,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.neonGreen
                : AppTheme.neonGreen.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive ? AppTheme.neonGlow : [],
          ),
        ),
      ],
    );

    return MouseRegion(
      cursor: isVertical ? SystemMouseCursors.resizeUpDown : SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: isVertical ? onDragStart : null,
        onVerticalDragEnd: isVertical ? onDragEnd : null,
        onVerticalDragCancel: isVertical ? onDragCancel : null,
        onVerticalDragUpdate: isVertical ? onDragUpdate : null,
        onHorizontalDragStart: isVertical ? null : onDragStart,
        onHorizontalDragEnd: isVertical ? null : onDragEnd,
        onHorizontalDragCancel: isVertical ? null : onDragCancel,
        onHorizontalDragUpdate: isVertical ? null : onDragUpdate,
        child: Container(
          width: isVertical ? double.infinity : 24.0,
          height: isVertical ? 24.0 : double.infinity,
          color: AppTheme.spaceBlack,
          child: Center(child: indicator),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = widget.direction == Axis.vertical;
    const double dividerSize = 24.0;
    const double minSecondarySize = 200.0;
    const double minPrimaryPercent = 0.25;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = isVertical ? constraints.maxHeight : constraints.maxWidth;
        final availableSize = totalSize - dividerSize;

        double primarySize = availableSize * _primaryRatio;
        double secondarySize = availableSize - primarySize;

        if (secondarySize < minSecondarySize) {
          secondarySize = minSecondarySize;
          primarySize = availableSize - secondarySize;
        }

        final minPrimarySize = availableSize * minPrimaryPercent;
        if (primarySize < minPrimarySize) {
          primarySize = minPrimarySize;
          secondarySize = availableSize - primarySize;
        }

        _primaryRatio = primarySize / availableSize;

        final divider = _buildDivider(
          isVertical: isVertical,
          onEnter: () => setState(() => _isHovering = true),
          onExit: () => setState(() => _isHovering = false),
          onDragStart: (_) => setState(() => _isDragging = true),
          onDragEnd: (_) => setState(() => _isDragging = false),
          onDragCancel: () => setState(() => _isDragging = false),
          onDragUpdate: (details) {
            setState(() {
              final delta = isVertical ? details.delta.dy : details.delta.dx;
              final newPrimary = primarySize + delta;
              _primaryRatio = (newPrimary / availableSize).clamp(
                minPrimaryPercent,
                1.0 - (minSecondarySize / availableSize),
              );
            });
          },
        );

        if (isVertical) {
          return Column(
            children: [
              SizedBox(height: primarySize, child: widget.leftChild),
              divider,
              Expanded(
                child: Container(
                  color: AppTheme.panelBlack,
                  child: widget.rightChild,
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              SizedBox(width: primarySize, child: widget.leftChild),
              divider,
              Expanded(
                child: Container(
                  color: AppTheme.panelBlack,
                  child: widget.rightChild,
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
