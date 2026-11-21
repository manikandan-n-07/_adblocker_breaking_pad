import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double progress;
  final bool isLoading;

  const LoadingIndicator({
    super.key,
    required this.progress,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && progress >= 1.0) {
      return const SizedBox(height: 2);
    }

    return SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        value: progress > 0 ? progress : null,
        backgroundColor: Colors.transparent,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}
