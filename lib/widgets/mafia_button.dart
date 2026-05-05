// المسار: lib/widgets/mafia_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class MafiaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final double width;
  final double height;
  final double fontSize;
  final Widget? icon;

  const MafiaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.width = double.infinity,
    this.height = 45,
    this.fontSize = 13,
    this.icon,
  });

  @override
  State<MafiaButton> createState() => _MafiaButtonState();
}

class _MafiaButtonState extends State<MafiaButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    final String bgImage = widget.isPrimary ? 'assets/images/ui/btn_primary.png' : 'assets/images/ui/btn_secondary.png';
    final Color textColor = isDisabled ? Colors.white38 : (widget.isPrimary ? Colors.amber : Colors.white);

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _controller.forward(),
      onTapUp: isDisabled ? null : (_) {
        _controller.reverse();
        if (widget.onPressed != null) {
          Provider.of<AudioProvider>(context, listen: false).playEffect('click.mp3');
          widget.onPressed!();
        }
      },
      onTapCancel: isDisabled ? null : () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgImage),
                // 🟢 الحسبة النهائية لزر مقاس 300x100 🟢
                centerSlice: const Rect.fromLTRB(30, 30, 270, 70),
                fit: BoxFit.fill,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Changa',
                      shadows: const [Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}