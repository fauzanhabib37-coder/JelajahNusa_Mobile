import 'package:flutter/material.dart';

/// A page route that slides in from the right with a fade.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  FadeSlidePageRoute({required this.page, super.settings})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          );
        },
      );
}

/// Wraps a child with a subtle scale animation on press.
class PressScaleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const PressScaleWrapper({super.key, required this.child, this.onTap});
  @override
  State<PressScaleWrapper> createState() => _PressScaleWrapperState();
}

class _PressScaleWrapperState extends State<PressScaleWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) {
      _ctrl.reverse();
      widget.onTap?.call();
    },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

/// An animated bookmark icon that toggles between filled and unfilled.
class AnimatedBookmarkIcon extends StatefulWidget {
  final bool saved;
  final VoidCallback? onTap;
  final String savedLabel;
  final String unsavedLabel;
  const AnimatedBookmarkIcon({
    super.key,
    required this.saved,
    this.onTap,
    this.savedLabel = 'Hapus dari koleksi',
    this.unsavedLabel = 'Simpan materi',
  });
  @override
  State<AnimatedBookmarkIcon> createState() => _AnimatedBookmarkIconState();
}

class _AnimatedBookmarkIconState extends State<AnimatedBookmarkIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedBookmarkIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.saved != widget.saved) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _bounce,
    child: IconButton.filledTonal(
      tooltip: widget.saved ? widget.savedLabel : widget.unsavedLabel,
      onPressed: widget.onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF426B50),
        minimumSize: const Size(48, 48),
      ),
      icon: Icon(
        widget.saved ? Icons.bookmark : Icons.bookmark_border,
        size: 21,
      ),
    ),
  );
}

/// An animated progress bar that animates from 0 to [value] on first build
/// and when [value] changes.
class AnimatedProgressBar extends StatefulWidget {
  final double value;
  const AnimatedProgressBar(this.value, {super.key});
  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.clamp(0, 1),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value.clamp(0, 1);
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value.clamp(0, 1),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (_, __) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: _animation.value,
        backgroundColor: const Color(0xFFE8EEE5),
        color: const Color(0xFF426B50),
        minHeight: 6,
        semanticsLabel: 'Progres belajar',
      ),
    ),
  );
}

