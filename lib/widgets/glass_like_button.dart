import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassLikeButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final Color color;

  const GlassLikeButton({
    super.key,
    required this.count,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: double.infinity,
      height: 52,
      opacity: 0.8,
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}