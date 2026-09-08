import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class EditableBudgetCell extends StatefulWidget {
  final double budgetPercent;
  final ValueChanged<double> onPercentChanged;

  const EditableBudgetCell({
    super.key,
    required this.budgetPercent,
    required this.onPercentChanged,
  });

  @override
  State<EditableBudgetCell> createState() => _EditableBudgetCellState();
}

class _EditableBudgetCellState extends State<EditableBudgetCell> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.budgetPercent * 100).toStringAsFixed(1),
    );
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant EditableBudgetCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.budgetPercent != widget.budgetPercent) {
      _controller.text = (widget.budgetPercent * 100).toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.').trim());
    if (parsed != null && parsed >= 0) {
      widget.onPercentChanged(parsed / 100.0);
    }
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return SizedBox(
        width: 70,
        height: 32,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            suffixText: '%',
            suffixStyle: const TextStyle(fontSize: 11),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          onSubmitted: (_) => _commit(),
        ),
      );
    }

    final displayVal = (widget.budgetPercent * 100).toStringAsFixed(1);
    return InkWell(
      onTap: () {
        setState(() {
          _isEditing = true;
          _controller.text = (widget.budgetPercent * 100).toStringAsFixed(1);
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.budgetPercent > 0
              ? AppColors.primaryLight.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: widget.budgetPercent > 0
                ? AppColors.primaryLight.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$displayVal%',
              style: TextStyle(
                fontWeight: widget.budgetPercent > 0 ? FontWeight.w700 : FontWeight.w500,
                color: widget.budgetPercent > 0 ? AppColors.primary : Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
