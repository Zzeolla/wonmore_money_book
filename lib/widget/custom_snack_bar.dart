import 'package:flutter/material.dart';

class CustomSnackBar extends SnackBar {
  CustomSnackBar({
    super.key,
    required String content,
    required VoidCallback onAddRecord,
    required VoidCallback onUndo,
    super.duration = const Duration(seconds: 3),
  }) : super(
          content: Text(content),
          action: SnackBarAction(
            label: '내역 추가',
            textColor: Colors.white,
            onPressed: onAddRecord,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: Colors.black87,
          actionOverflowThreshold: 0.5,
          onVisible: () {
            // 스낵바가 표시된 후 되돌리기 버튼을 위한 새로운 스낵바를 표시
            Future.delayed(const Duration(milliseconds: 500), () {
              ScaffoldMessenger.of(GlobalKey<ScaffoldMessengerState>().currentContext!)
                  .showSnackBar(
                SnackBar(
                  content: const Text('되돌리기'),
                  action: SnackBarAction(
                    label: '되돌리기',
                    textColor: Colors.white,
                    onPressed: onUndo,
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.black87,
                  duration: const Duration(seconds: 2),
                ),
              );
            });
          },
        );
} 