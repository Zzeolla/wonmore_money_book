import 'package:flutter/material.dart';

class RecordInputDialog extends StatefulWidget {
  final DateTime initialDate;

  const RecordInputDialog({
    super.key,
    required this.initialDate,
  });

  @override
  State<RecordInputDialog> createState() => _RecordInputDialogState();
}

class _RecordInputDialogState extends State<RecordInputDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog();
  }
}
