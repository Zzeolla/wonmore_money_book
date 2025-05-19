import 'package:flutter/material.dart';

class FavoriteScreen extends StatelessWidget {
  final VoidCallback onClose;

  const FavoriteScreen({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        onClose();
        return Future.value(false);
      },
      child: Column(
        children: [
          Text("즐겨찾기"),
          ElevatedButton(onPressed: onClose, child: Text("닫기")),
        ],
      ),
    );
  }
}