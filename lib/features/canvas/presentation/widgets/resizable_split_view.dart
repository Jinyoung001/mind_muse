import 'package:flutter/material.dart';
import 'package:mind_muse/core/theme/app_theme.dart';

/// A view that splits the screen into two parts (left and right) 
/// with a draggable divider in between.
class ResizableSplitView extends StatefulWidget {
  final Widget leftChild;
  final Widget rightChild;
  final double initialLeftRatio;

  const ResizableSplitView({
    super.key,
    required this.leftChild,
    required this.rightChild,
    this.initialLeftRatio = 0.7,
  });

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  late double _leftRatio;
  bool _isDragging = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _leftRatio = widget.initialLeftRatio;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double dividerWidth = 4.0;
        const double minRightWidth = 300.0;
        const double minLeftPercent = 0.4;
        
        final totalWidth = constraints.maxWidth;
        final availableWidth = totalWidth - dividerWidth;
        
        // Calculate initial widths based on ratio
        double leftWidth = availableWidth * _leftRatio;
        double rightWidth = availableWidth - leftWidth;

        // Constraint Enforcement: Right panel min 300px
        if (rightWidth < minRightWidth) {
          rightWidth = minRightWidth;
          leftWidth = availableWidth - rightWidth;
        }

        // Constraint Enforcement: Left panel min 40%
        final minLeftWidth = availableWidth * minLeftPercent;
        if (leftWidth < minLeftWidth) {
          leftWidth = minLeftWidth;
          rightWidth = availableWidth - leftWidth;
        }

        // Re-calculate ratio after constraints for consistency
        _leftRatio = leftWidth / availableWidth;

        return Row(
          children: [
            // Left Panel (Canvas Zone)
            SizedBox(
              width: leftWidth,
              child: widget.leftChild,
            ),
            
            // Draggable Divider
            MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (_) => setState(() => _isDragging = true),
                onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
                onHorizontalDragCancel: () => setState(() => _isDragging = false),
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    double newLeftWidth = leftWidth + details.delta.dx;
                    _leftRatio = (newLeftWidth / availableWidth).clamp(
                      minLeftPercent, 
                      1.0 - (minRightWidth / availableWidth),
                    );
                  });
                },
                child: Container(
                  width: dividerWidth,
                  color: AppTheme.spaceBlack,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 2,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: (_isDragging || _isHovering)
                            ? AppTheme.neonGreen
                            : AppTheme.neonGreen.withOpacity(0.3),
                        boxShadow: (_isDragging || _isHovering) 
                            ? AppTheme.neonGlow 
                            : [],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Right Panel (Conversation Zone)
            Expanded(
              child: Container(
                color: AppTheme.panelBlack,
                child: widget.rightChild,
              ),
            ),
          ],
        );
      },
    );
  }
}
