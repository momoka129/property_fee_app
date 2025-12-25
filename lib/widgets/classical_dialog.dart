import 'package:flutter/material.dart';

/// 一个通用的古典雅致风格弹窗
class ClassicalDialog extends StatefulWidget {
  final String title;
  final String content;
  final String? cancelText; // 改为可空 (String?)
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;

  const ClassicalDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText, // 默认为 null，表示不显示取消按钮
    this.confirmText = 'CONFIRM',
    this.onCancel,
    required this.onConfirm,
  });

  @override
  State<ClassicalDialog> createState() => _ClassicalDialogState();
}

class _ClassicalDialogState extends State<ClassicalDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 调色板
    const Color paperColor = Color(0xFFF9F7F2); // 宣纸白
    const Color inkColor = Color(0xFF2C2C2C); // 墨色
    // 使用当前主题的主色调
    final Color accentColor = Theme.of(context).colorScheme.primary;
    const Color borderColor = Color(0xFFD4C5A8); // 淡金边框

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 主体容器
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: paperColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: inkColor.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 顶部装饰
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 40, height: 1, color: borderColor),
                        const SizedBox(width: 10),
                        const Icon(Icons.spa_outlined,
                            size: 16, color: borderColor),
                        const SizedBox(width: 10),
                        Container(width: 40, height: 1, color: borderColor),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 标题
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: inkColor,
                        letterSpacing: 2.0,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 内容文本
                    Text(
                      widget.content,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: inkColor.withOpacity(0.7),
                        height: 1.8,
                        fontStyle: FontStyle.normal,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 按钮区域 (逻辑修改：根据是否有 cancelText 决定布局)
                    _buildButtonRow(inkColor, accentColor),
                  ],
                ),
              ),

              // 印章装饰
              Positioned(
                bottom: -10,
                right: -10,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(
                    Icons.fingerprint,
                    size: 120,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 抽离按钮构建逻辑，支持单按钮模式
  Widget _buildButtonRow(Color inkColor, Color accentColor) {
    // 确认按钮样式（复用）
    Widget confirmBtn = InkWell(
      onTap: widget.onConfirm,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.confirmText,
          style: const TextStyle(
            color: Color(0xFFF9F7F2),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
    );

    // 如果没有取消文本，则显示单按钮（铺满宽度，视觉上即居中）
    if (widget.cancelText == null || widget.cancelText!.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: confirmBtn,
      );
    }

    // 否则显示双按钮
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 左侧取消按钮
        Expanded(
          child: InkWell(
            onTap: widget.onCancel ?? () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: inkColor.withOpacity(0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.cancelText!,
                style: TextStyle(
                  color: inkColor.withOpacity(0.8),
                  fontSize: 15,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 右侧确认按钮
        Expanded(
          child: confirmBtn,
        ),
      ],
    );
  }
}