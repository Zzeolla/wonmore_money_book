import 'package:flutter/material.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class TransactionTypeButton extends StatelessWidget {
  final String label;
  final TransactionType type;
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onSelected;
  final bool enabled;

  const TransactionTypeButton({
    super.key,
    required this.label,
    required this.type,
    required this.selectedType,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedType == type;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: enabled ? () => onSelected(type) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.amber : Colors.grey.shade300,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}