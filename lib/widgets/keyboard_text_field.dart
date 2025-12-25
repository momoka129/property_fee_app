import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A TextField wrapper that ensures physical Delete/Backspace keys work on some emulators/devices
/// by intercepting raw key events and applying edits to the controller when necessary.
class KeyboardTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;

  const KeyboardTextField({
    super.key,
    required this.controller,
    this.validator,
    this.decoration,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  State<KeyboardTextField> createState() => _KeyboardTextFieldState();
}

class _KeyboardTextFieldState extends State<KeyboardTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isHandlingDelete = false;

  @override
  void initState() {
    super.initState();
    _focusNode.onKey = _onKey;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleDelete() {
    if (_isHandlingDelete) return; // 防止重复处理

    final c = widget.controller;
    final sel = c.selection;
    final text = c.text;

    if (sel.isValid) {
      if (sel.start != sel.end) {
        // 有选中文本，删除选中的部分
        final newText = text.replaceRange(sel.start, sel.end, '');
        c.text = newText;
        c.selection = TextSelection.collapsed(offset: sel.start);
      } else {
        // 没有选中文本，删除光标前的一个字符
        if (sel.start > 0) {
          final start = sel.start - 1;
          final newText = text.replaceRange(start, sel.start, '');
          c.text = newText;
          c.selection = TextSelection.collapsed(offset: start);
        }
      }
    } else {
      // 选择无效，删除最后一个字符
      if (text.isNotEmpty) {
        final newText = text.substring(0, text.length - 1);
        c.text = newText;
        c.selection = TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace) {
        _isHandlingDelete = true;
        _handleDelete();
        _isHandlingDelete = false;
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      validator: widget.validator,
      decoration: widget.decoration,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
    );
  }
}






