import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height,
    this.blur = 30, // 极致模糊
    this.opacity = 0.7, // 基础透明度
    this.borderRadius,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);

    Widget content = Stack(
      children: [
        // 1. 背景模糊层 + 填充层
        ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                // 液态光感填充：左上角亮白 -> 右下角透明
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity((opacity + 0.1).clamp(0.0, 0.9)), // 高光区
                    Colors.white.withOpacity((opacity - 0.1).clamp(0.0, 0.9)), // 过度区
                    Colors.white.withOpacity(0.05), // 暗部区
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
                borderRadius: radius,
              ),
              padding: padding ?? const EdgeInsets.all(24),
              child: Theme(
                // 强制内容为深色，保证对比度
                data: Theme.of(context).copyWith(
                  iconTheme: const IconThemeData(color: Colors.black87),
                  textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.black87, displayColor: Colors.black87),
                ),
                child: child,
              ),
            ),
          ),
        ),

        // 2. 渐变边框层 (使用 CustomPainter 实现)
        // 这是实现 "iOS 26" 钻石切割感的关键
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GradientBorderPainter(
                radius: radius,
                strokeWidth: 1.5,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.9), // 边框左上角：极亮，像发光
                    Colors.white.withOpacity(0.1), // 边框中间：渐隐
                    Colors.white.withOpacity(0.3), // 边框右下角：微亮反光
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    // 增加一个外阴影，让它浮起来
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 20),
            spreadRadius: -5,
          ),
        ],
      ),
      child: content,
    );
  }
}

// 辅助绘制器：绘制渐变边框
class _GradientBorderPainter extends CustomPainter {
  final BorderRadius radius;
  final double strokeWidth;
  final Gradient gradient;

  _GradientBorderPainter({
    required this.radius,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // 将 BorderRadius 转换为 RRect
    final rrect = radius.toRRect(rect);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect.deflate(strokeWidth / 2), paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gradient != gradient;
  }
}