import 'package:flutter/material.dart';

class ControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const ControlButton({
    super.key,
    required this.icon,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onTapDown();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTapUp();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        widget.onTapUp();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: _isPressed ? const Color(0xFF333333) : const Color(0xFF222222),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isPressed 
                  ? Colors.cyanAccent.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.5),
                offset: _isPressed ? const Offset(0, 0) : const Offset(4, 4),
                blurRadius: _isPressed ? 15 : 10,
                spreadRadius: _isPressed ? 2 : 0,
              ),
              if (!_isPressed)
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
                  offset: const Offset(-4, -4),
                  blurRadius: 10,
                ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isPressed 
                ? [const Color(0xFF3A3A3A), const Color(0xFF2A2A2A)]
                : [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)],
            ),
            border: Border.all(
              color: _isPressed ? Colors.cyanAccent : Colors.cyanAccent.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 50,
              color: _isPressed ? Colors.cyanAccent : Colors.cyanAccent.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }
}
