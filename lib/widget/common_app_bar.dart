import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool isMainScreen;
  final String label;

  const CommonAppBar({
    super.key,
    this.isMainScreen = true,
    this.actions,
    this.label = '원모아 가계부',
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFA79BFF),
      scrolledUnderElevation: 3,
      elevation: 1,
      leading: isMainScreen ? Builder(
        builder: (context) {
          return IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu, color: Color(0xFFF2F4F6), size: 30),
          );
        },
      ) : IconButton(
        icon: Icon(Icons.arrow_back, size: 36),
        onPressed: () => Navigator.of(context).maybePop(),
        color: Colors.white,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Color(0xFFF2F4F6),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);
}
