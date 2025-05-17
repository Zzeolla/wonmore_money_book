import 'package:flutter/material.dart';

Future<bool?> showCustomDeleteDialog(
    BuildContext context, {
      String title = '삭제하시겠습니까?',
      String message = '이 내역을 삭제할까요?',
      String cancelText = '취소',
      String confirmText = '삭제하기',
      Color confirmColor = Colors.redAccent,
    }) {
  return showDialog<bool>(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFF1F1FD),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_forever, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _dialogButton(
                  text: cancelText,
                  onTap: () => Navigator.of(context).pop(false),
                  color: const Color(0xFFA79BFF),
                ),
                _dialogButton(
                  text: confirmText,
                  onTap: () => Navigator.of(context).pop(true),
                  color: confirmColor,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _dialogButton({
  required String text,
  required VoidCallback onTap,
  required Color color,
}) {
  return ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
    child: Text(text),
  );
}
