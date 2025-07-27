import 'package:flutter/material.dart';

class RoundedLoginButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final double textOpacity;
  final double iconSize;
  final double borderRadius;

  const RoundedLoginButton({
    required this.label,
    required this.iconAsset,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.textOpacity = 1.0,
    this.iconSize = 20,
    this.borderRadius = 6,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              height: iconSize,
              width: iconSize,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(textOpacity),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
