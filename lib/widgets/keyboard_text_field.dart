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

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleDelete() {
    final c = widget.controller;
    final sel = c.selection;
    final text = c.text;
    if (sel.isValid) {
      if (sel.start != sel.end) {
        final newText = text.replaceRange(sel.start, sel.end, '');
        c.text = newText;
        c.selection = TextSelection.collapsed(offset: sel.start);
        return;
      } else {
        if (sel.start > 0) {
          final start = sel.start - 1;
          final newText = text.replaceRange(start, sel.start, '');
          c.text = newText;
          c.selection = TextSelection.collapsed(offset: start);
          return;
        }
      }
    } else {
      if (text.isNotEmpty) {
        final newText = text.substring(0, text.length - 1);
        c.text = newText;
        c.selection = TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  bool _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace) {
        _handleDelete();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _onKey,
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        decoration: widget.decoration,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
      ),
    );
  }
}






