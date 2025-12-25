import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

/// Reusable Malaysia phone input widget.
/// Shows a fixed '+60' prefix and a 9-digit Pinput composed of square boxes.
class MalaysiaPhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final FormFieldValidator<String>? validator;
  final void Function(String)? onChanged;
  final double boxSize;
  final double borderRadius;

  const MalaysiaPhoneInput({
    super.key,
    required this.controller,
    this.label = 'Phone',
    this.required = false,
    this.validator,
    this.onChanged,
    this.boxSize = 48,
    this.borderRadius = 10,
  });

  String? _defaultValidator(String? _) {
    final text = controller.text.trim();
    if (required) {
      if (text.isEmpty) return 'Please enter your phone';
      if (text.length != 9) return 'Phone must be 9 digits';
    } else {
      if (text.isNotEmpty && text.length != 9) return 'Phone must be 9 digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pinTheme = PinTheme(
      width: boxSize,
      height: boxSize,
      textStyle: const TextStyle(fontSize: 16, color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade400),
      ),
    );

    return FormField<String>(
      initialValue: controller.text,
      validator: validator ?? _defaultValidator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 18),
                  const SizedBox(width: 8),
                  Text(label, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: const Text('+60', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Pinput(
                    length: 9,
                    controller: controller,
                    defaultPinTheme: pinTheme,
                    focusedPinTheme: pinTheme.copyWith(
                      decoration: pinTheme.decoration!.copyWith(
                        border: Border.all(color: theme.primaryColor),
                      ),
                    ),
                    submittedPinTheme: pinTheme,
                    androidSmsAutofillMethod: AndroidSmsAutofillMethod.none,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      field.didChange(value);
                      if (onChanged != null) onChanged!(value);
                    },
                  ),
                ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(field.errorText ?? '', style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }
}


