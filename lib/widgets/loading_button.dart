import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.child,
    this.height = 48,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loader'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : KeyedSubtree(key: const ValueKey('child'), child: child),
        ),
      ),
    );
  }
}
