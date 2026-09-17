import 'dart:async';

import 'package:flutter/material.dart';

class AnimatedSearchPlaceholder extends StatefulWidget {
  const AnimatedSearchPlaceholder({
    required this.phrases,
    this.interval = const Duration(seconds: 4),
    super.key,
  });

  final List<String> phrases;
  final Duration interval;

  @override
  State<AnimatedSearchPlaceholder> createState() =>
      _AnimatedSearchPlaceholderState();
}

class _AnimatedSearchPlaceholderState extends State<AnimatedSearchPlaceholder> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  @override
  void didUpdateWidget(covariant AnimatedSearchPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.phrases != widget.phrases ||
        oldWidget.interval != widget.interval) {
      _timer?.cancel();
      _index = 0;
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    if (widget.phrases.length <= 1) return;

    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;

      setState(() {
        _index = (_index + 1) % widget.phrases.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.phrases.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,

            // Keep the text anchored to the left.
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  ...previousChildren,
                  ?currentChild,
                ],
              );
            },

            transitionBuilder: (child, animation) {
              final slideAnimation =
                  Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );

              return Align(
                alignment: Alignment.centerLeft,
                child: SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
              );
            },

            child: Align(
              key: ValueKey(_index),
              alignment: Alignment.centerLeft,
              child: Text(
                widget.phrases[_index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
