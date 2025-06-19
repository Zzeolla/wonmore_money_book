import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:wonmore_money_book/model/category_summary.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';

class PieChartWidget extends StatefulWidget {
  final List<CategorySummary> data;
  final TransactionType transactionType;

  const PieChartWidget({super.key, required this.data, required this.transactionType,});

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.fold<double>(0, (sum, d) => sum + d.amount);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      // 탭 업일 때만 처리
                      if (event is FlTapUpEvent) {
                        setState(() {
                          final index = response?.touchedSection?.touchedSectionIndex;
                          if (_touchedIndex == index || index == null) {
                            _touchedIndex = null; // 해제
                          } else {
                            _touchedIndex = index;
                          }
                        });
                      }
                    },
                  ),
                  sections: List.generate(widget.data.length, (i) {
                    final entry = widget.data[i];
                    final isTouched = i == _touchedIndex;
                    final percent = (entry.amount / total * 100).toStringAsFixed(1);

                    return PieChartSectionData(
                      value: entry.amount,
                      title: '',
                      color: entry.color,
                      radius: 70,
                      badgeWidget: (_touchedIndex == null || _touchedIndex == i)
                        ? _buildBadge(entry.name, percent)
                        : null,
                      badgePositionPercentageOffset: 1.2,
                    );
                  }),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                ),
              ),
            ),
            Column(
              children: [
                Text(widget.transactionType == TransactionType.expense ? '총 지출' : '총 수입', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(_formatCurrency(total),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 50),
        // ✅ 여기가 핵심: 리스트 복사 후 sort
        ...(() {
          final sortedData = widget.data.toList()
            ..sort((a, b) => b.amount.compareTo(a.amount));
          return sortedData.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: e.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${e.name} (${(e.amount / total * 100).toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  _formatCurrency(e.amount),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )).toList();
        })(),
      ],
    );
  }

  Widget _buildBadge(String name, String percent) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(name, style: const TextStyle(fontSize: 10)),
            Text('$percent%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '₩${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }
}