import 'package:flutter/material.dart';

import '../../audio/audio_service.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';

enum NeonButtonVariant {
  primary,
  secondary,
  danger,
}

/// A neon styled arcade button with pill shape, glow, and press scaling.
class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = NeonButtonVariant.primary,
    this.width,
    this.height = 56.0,
    this.textStyle,
    this.icon,
  });

  const NeonButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 56.0,
    this.textStyle,
    this.icon,
  }) : variant = NeonButtonVariant.primary;

  const NeonButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 48.0,
    this.textStyle,
    this.icon,
  }) : variant = NeonButtonVariant.secondary;

  const NeonButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.width,
    this.height = 48.0,
    this.textStyle,
    this.icon,
  }) : variant = NeonButtonVariant.danger;

  final String text;
  final VoidCallback? onPressed;
  final NeonButtonVariant variant;
  final double? width;
  final double height;
  final TextStyle? textStyle;
  final Widget? icon;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    AudioService.instance.playClick();
    HapticsService.buttonPress();
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    Color fillColor;
    Border? border;
    Color textColor;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case NeonButtonVariant.primary:
        fillColor = Palette.cyan;
        border = null;
        textColor = Palette.bgDeep;
        if (isEnabled) {
          shadows = [
            BoxShadow(
              color: Palette.cyan.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 0,
            ),
          ];
        }
        break;
      case NeonButtonVariant.secondary:
        fillColor = Colors.transparent;
        border = Border.all(color: Palette.cyan, width: 2.0);
        textColor = Palette.cyan;
        shadows = null;
        break;
      case NeonButtonVariant.danger:
        fillColor = Colors.transparent;
        border = Border.all(color: Palette.magenta, width: 2.0);
        textColor = Palette.magenta;
        shadows = null;
        break;
    }

    final effectiveTextStyle = (widget.textStyle ?? AppTheme.button).copyWith(
      color: textColor,
    );

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.40,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(32),
              border: border,
              boxShadow: shadows,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.text,
                      style: effectiveTextStyle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular neon icon button (48x48, bgPurple fill, 1.5dp cyan@40% border).
class NeonIconButton extends StatefulWidget {
  const NeonIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 48.0,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;

  @override
  State<NeonIconButton> createState() => _NeonIconButtonState();
}

class _NeonIconButtonState extends State<NeonIconButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    AudioService.instance.playClick();
    HapticsService.buttonPress();
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    Widget button = Opacity(
      opacity: isEnabled ? 1.0 : 0.40,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Palette.bgPurple,
              border: Border.all(
                color: Palette.cyan.withValues(alpha: 0.40),
                width: 1.5,
              ),
            ),
            child: widget.icon,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
