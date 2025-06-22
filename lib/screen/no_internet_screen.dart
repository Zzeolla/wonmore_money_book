import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("인터넷 연결이 필요합니다."),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final result = await Connectivity().checkConnectivity();
                if (result != ConnectivityResult.none && context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              child: const Text("다시 시도"),
            )
          ],
        ),
      ),
    );
  }
}
