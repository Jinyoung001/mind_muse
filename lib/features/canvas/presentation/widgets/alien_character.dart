import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/alien_provider.dart';

class AlienCharacter extends ConsumerWidget {
  final double size;

  const AlienCharacter({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(alienProvider.select((s) => s.isLoading));

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            isLoading ? '🛸' : '👽',
            key: ValueKey(isLoading),
            style: TextStyle(fontSize: size * 0.75),
          ),
        ),
      ),
    );
  }
}
