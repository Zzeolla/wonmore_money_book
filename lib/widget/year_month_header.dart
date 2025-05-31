import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';

class YearMonthHeader extends StatelessWidget {
  final Color backgroundColor;

  const YearMonthHeader({
    super.key,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoneyProvider>();
    final focusedDay = provider.focusedDay;
    final yearMonthText = '${focusedDay.year}.${focusedDay.month.toString().padLeft(2, '0')}월';

    return Container(
      color: backgroundColor,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircleArrowButton(
              icon: Icons.chevron_left,
              onTap: () {
                final prevMonth = DateTime(focusedDay.year, focusedDay.month - 1);
                provider.changeFocusedDay(prevMonth);
              },
            ),
            SizedBox(width: 16),
            GestureDetector(
              onTap: () => _showMonthPickerDialog(context, focusedDay),
              child: Text(
                yearMonthText,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            SizedBox(width: 16),
            _buildCircleArrowButton(
              icon: Icons.chevron_right,
              onTap: () {
                final nextMonth = DateTime(focusedDay.year, focusedDay.month + 1);
                provider.changeFocusedDay(nextMonth);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 30,
          color: const Color(0xFF5A5A89),
        ),
      ),
    );
  }

  void _showMonthPickerDialog(BuildContext context, DateTime current) async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      context.read<MoneyProvider>().changeFocusedDay(DateTime(picked.year, picked.month));
    }
  }
}
