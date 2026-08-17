import 'package:flutter/material.dart';

class PillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPrimary;
  final double height;

  const PillButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isPrimary = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          splashColor: isPrimary
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.deepOrange.withValues(alpha: 0.15),
          highlightColor: isPrimary
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.deepOrange.withValues(alpha: 0.08),
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              color: isPrimary ? Colors.deepOrange : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isPrimary ? Colors.deepOrange : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: Colors.deepOrange.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isPrimary ? Colors.white : Colors.black87,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}