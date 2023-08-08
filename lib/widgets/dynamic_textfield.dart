import 'package:flutter/material.dart';

class DynamicTextfield extends StatefulWidget {
  final String? initialValue;
  final bool isIngredient;
  final void Function(String) onChanged;

  const DynamicTextfield({
    super.key,
    this.initialValue,
    required this.isIngredient,
    required this.onChanged,
  });

  @override
  State<DynamicTextfield> createState() => _DynamicTextFDState();
}

class _DynamicTextFDState extends State<DynamicTextfield> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.text = widget.initialValue ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // maxLines: null,
      controller: _controller,
      onChanged: widget.onChanged,
      style: const TextStyle(
        color: Colors.white,
        // fontSize: 13.sp,
      ),
      decoration: InputDecoration(
        hintText: widget.isIngredient ? "Enter Ingredient" : "Enter Steps",
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Please enter something';
        return null;
      },
    );
  }
}
