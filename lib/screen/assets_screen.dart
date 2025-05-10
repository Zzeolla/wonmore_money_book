import 'package:flutter/material.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자산 관리'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAssetCard(
            context,
            '현금',
            '1,000,000원',
            '목표: 2,000,000원',
            0.5,
          ),
          const SizedBox(height: 16),
          _buildAssetCard(
            context,
            '신한은행',
            '5,000,000원',
            '목표: 10,000,000원',
            0.5,
          ),
          const SizedBox(height: 16),
          _buildAssetCard(
            context,
            '국민은행',
            '3,000,000원',
            '목표: 5,000,000원',
            0.6,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 자산 추가 다이얼로그 구현
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAssetCard(
    BuildContext context,
    String title,
    String amount,
    String goal,
    double progress,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              goal,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 