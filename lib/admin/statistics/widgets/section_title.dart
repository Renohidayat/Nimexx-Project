import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final TextStyle? textStyle;

  const SectionTitle({
    super.key,
    required this.title,
    this.icon,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        textStyle ??
        const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );

    return Row(
      children: [
        if (icon != null) Icon(icon, color: Colors.orangeAccent),
        if (icon != null) const SizedBox(width: 8),
        Text(title, style: style),
      ],
    );
  }
}
