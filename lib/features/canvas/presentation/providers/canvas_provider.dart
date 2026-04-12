import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/drawn_stroke_model.dart';

class CanvasState {
  /// 완성된 획 목록
  final List<DrawnStrokeModel> strokes;

  /// 현재 그리고 있는 획의 좌표 목록 (onPanEnd 전까지 임시 저장)
  final List<Offset> currentPoints;

  const CanvasState({
    this.strokes = const [],
    this.currentPoints = const [],
  });

  CanvasState copyWith({
    List<DrawnStrokeModel>? strokes,
    List<Offset>? currentPoints,
  }) =>
      CanvasState(
        strokes: strokes ?? this.strokes,
        currentPoints: currentPoints ?? this.currentPoints,
      );
}

class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(const CanvasState());

  /// 새 획 시작 (onPanStart)
  void startStroke(Offset point) {
    state = state.copyWith(currentPoints: [point]);
  }

  /// 획에 좌표 추가 (onPanUpdate)
  void addPoint(Offset point) {
    state = state.copyWith(
      currentPoints: [...state.currentPoints, point],
    );
  }

  /// 획 완료 — currentPoints를 strokes에 저장 (onPanEnd)
  /// 반환값: 완성된 DrawnStrokeModel (IntersectionService에 전달할 용도)
  DrawnStrokeModel? endStroke() {
    if (state.currentPoints.length < 2) {
      state = state.copyWith(currentPoints: []);
      return null;
    }

    final stroke = DrawnStrokeModel(points: List.from(state.currentPoints));
    state = state.copyWith(
      strokes: [...state.strokes, stroke],
      currentPoints: [],
    );
    return stroke;
  }

  /// 마지막 획 되돌리기
  void undoLastStroke() {
    if (state.strokes.isEmpty) return;
    final newStrokes = List<DrawnStrokeModel>.from(state.strokes);
    newStrokes.removeLast();
    state = state.copyWith(strokes: newStrokes, currentPoints: []);
  }

  /// 모든 획 초기화
  void clearStrokes() {
    state = const CanvasState();
  }
}

final canvasProvider =
    StateNotifierProvider<CanvasNotifier, CanvasState>(
  (ref) => CanvasNotifier(),
);
