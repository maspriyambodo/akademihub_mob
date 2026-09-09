import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final bool autofocus;
  final FocusNode? focusNode;
  final BorderRadius? borderRadius;

  const TvFocusable({
    super.key,
    required this.child,
    this.onSelect,
    this.autofocus = false,
    this.focusNode,
    this.borderRadius,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return Focus(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onFocusChange: (has) => setState(() => _hasFocus = has),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onSelect?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedScale(
        scale: _hasFocus ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: _hasFocus ? const Color(0xFFE9A23B) : Colors.transparent,
              width: 3,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onSelect,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
