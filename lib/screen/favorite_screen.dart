import 'package:flutter/material.dart';

class FavoriteScreen extends StatefulWidget {
  final VoidCallback onClose;

  const FavoriteScreen({
    super.key,
    required this.onClose,
  });

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("즐겨찾기"),
        ElevatedButton(onPressed: widget.onClose, child: Text("닫기")),
      ],
    );
  }
}
