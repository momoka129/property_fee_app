import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height,
    this.blur = 15,
    this.opacity = 0.1, // 降低透明度以增强玻璃感
    this.color, // 默认使用白色或主题色
    this.borderRadius,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 默认使用绿色系 (适配您的主题) 或白色
    final baseColor = color ?? Theme.of(context).primaryColor;
    final radius = borderRadius ?? BorderRadius.circular(20);

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(opacity),
            borderRadius: radius,
            // 玻璃的精髓：微妙的渐变边框和内阴影
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.0,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      );
    }
    return content;
  }
}