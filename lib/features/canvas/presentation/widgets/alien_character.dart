import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import '../providers/alien_provider.dart';

/// Rive 애니메이션을 사용하는 외계인 캐릭터 위젯.
/// [alienProvider]의 isLoading 상태에 따라 'isThinking' 상태를 전환합니다.
class AlienCharacter extends ConsumerStatefulWidget {
  final double size;
  
  const AlienCharacter({
    super.key,
    this.size = 100,
  });

  @override
  ConsumerState<AlienCharacter> createState() => _AlienCharacterState();
}

class _AlienCharacterState extends ConsumerState<AlienCharacter> {
  /// Rive 상태 머신 컨트롤러
  StateMachineController? _controller;
  
  /// 'isThinking' 입력값 (부울)
  SMIBool? _isThinking;

  @override
  void initState() {
    super.initState();
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'MainStateMachine', // Rive 파일에 정의된 상태 머신 이름
    );

    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
      _isThinking = controller.findInput<bool>('isThinking') as SMIBool?;
      
      // 초기 상태 설정
      if (_isThinking != null) {
        _isThinking!.value = ref.read(alienProvider).isLoading;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // isLoading 상태를 감시하여 애니메이션 입력값 업데이트
    final isLoading = ref.watch(alienProvider.select((s) => s.isLoading));
    
    if (_isThinking != null) {
      _isThinking!.value = isLoading;
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: RiveAnimation.asset(
          'assets/animations/alien_inspector.riv',
          fit: BoxFit.contain,
          onInit: _onRiveInit,
          // 에셋 로드 실패 시 플레이스홀더 표시 (충돌 방지)
          placeHolder: _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.withOpacity(0.2),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: const Text(
          '👽',
          style: TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}
