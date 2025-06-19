import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/component/pie_chart_widget.dart';
import 'package:wonmore_money_book/model/category_summary.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/util/analysis_category_color.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';
import 'package:wonmore_money_book/widget/common_drawer.dart';
import 'package:wonmore_money_book/widget/transaction_type_button.dart';

enum DatePeriodType { month, week, custom }

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  TransactionType _selectedType = TransactionType.expense;
  DatePeriodType _datePeriodType = DatePeriodType.month;
  WeekDateInfo? _weekDateInfo;
  String _selectedAsset = '전체'; // 자산 이름 또는 ID
  final now = DateTime.now();

  final dummyData = [
    CategorySummary(name: '식비', amount: 45000),
    CategorySummary(name: '교통', amount: 30000),
    CategorySummary(name: '문화', amount: 15000),
    CategorySummary(name: '기타', amount: 10000),
  ];

  @override
  void initState() {
    super.initState();
    resetUsedAutoColors();
    _weekDateInfo = WeekDateInfo(
      weekNumber: null,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoneyProvider>();
    final assetList = provider.assets.map((e) => e.name).toList();

    final start = _weekDateInfo!.startDate;
    final end = _weekDateInfo!.endDate;

    return Scaffold(
      // todo: 분석 기능 만들기 최대한 간단하게
      appBar: CommonAppBar(actions: [
        IconButton(
          icon: Icon(Icons.date_range, color: Color(0xFFF2F4F6), size: 30),
          onPressed: () => _showPeriodSelectionDialog(provider.focusedDay),
        ),
      ]),
      drawer: CommonDrawer(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildYearMonthHeader(provider, _datePeriodType),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                TransactionTypeButton(
                  label: '수입',
                  type: TransactionType.income,
                  selectedType: _selectedType,
                  onSelected: (type) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                ),
                SizedBox(width: 24),
                TransactionTypeButton(
                  label: '지출',
                  type: TransactionType.expense,
                  selectedType: _selectedType,
                  onSelected: (type) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DropdownButtonFormField<String>(
                      value: _selectedAsset,
                      isExpanded: true,
                      alignment: Alignment.center,
                      items: ['전체', ...assetList].map((asset) {
                        return DropdownMenuItem<String>(
                          value: asset,
                          child: Center(
                              child: Text(
                            asset,
                            textAlign: TextAlign.center,
                          )),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedAsset = value;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade300,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1, height: 1, color: Colors.grey),

          /// ✅ DB에서 불러온 카테고리별 합계 PieChart 표시
          Expanded(
            child: FutureBuilder<List<CategorySummary>>(
              future: provider.getCategorySummariesByPeriod(
                start: start,
                end: end,
                type: _selectedType,
                selectedAssetName: _selectedAsset,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('에러 발생: ${snapshot.error}'));
                }

                final data = snapshot.data!;
                if (data.isEmpty) {
                  return const Center(child: Text('해당 기간의 데이터가 없습니다.'));
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: PieChartWidget(
                    data: data,
                    transactionType: _selectedType,
                  ),
                );
              },
            ),
          ),
          BannerAdWidget(),
        ],
      ),
    );
  }

  //
  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(EnumProperty<DatePeriodType>('_datePeriodType', _datePeriodType));
  // }

  void _showPeriodSelectionDialog(DateTime date) async {
    final selected = await showDialog<DatePeriodType>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('기간 선택'),
        children: [
          SimpleDialogOption(
            child: Text('월간'),
            onPressed: () => Navigator.pop(context, DatePeriodType.month),
          ),
          SimpleDialogOption(
            child: Text('주간'),
            onPressed: () => Navigator.pop(context, DatePeriodType.week),
          ),
          SimpleDialogOption(
            child: Text('기간 설정'),
            onPressed: () => Navigator.pop(context, DatePeriodType.custom),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() {
        _datePeriodType = selected;
        if (selected == DatePeriodType.month || selected == DatePeriodType.custom) {
          _weekDateInfo = WeekDateInfo(
            weekNumber: null,
            startDate: DateTime(date.year, date.month, 1),
            endDate: DateTime(date.year, date.month + 1, 1).subtract(const Duration(days: 1)),
          );
        } else {
          _weekDateInfo = getSundayBasedWeekInfo(date);
        }
        // 필요 시 _startDate, _endDate 계산
      });
    }
  }

  DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime lastDayOfMonth(DateTime date) {
    final beginningNextMonth =
        (date.month == 12) ? DateTime(date.year + 1, 1, 1) : DateTime(date.year, date.month + 1, 1);
    return beginningNextMonth.subtract(const Duration(days: 1));
  }

  Widget _buildYearMonthHeader(MoneyProvider provider, DatePeriodType periodType) {
    final focusedDay = provider.focusedDay;
    final String yearMonthText;
    switch (periodType) {
      case DatePeriodType.month:
        yearMonthText =
            '${_weekDateInfo!.startDate.year}.${_weekDateInfo!.startDate.month.toString().padLeft(2, '0')}월';
        break;

      case DatePeriodType.week:
        yearMonthText =
            '${_weekDateInfo!.startDate.year.toString().substring(2)}년 W${_weekDateInfo!.weekNumber} '
            '(${_weekDateInfo!.startDate.month}.${_weekDateInfo!.startDate.day} ~ ${_weekDateInfo!.endDate.month}.${_weekDateInfo!.endDate.day})';
        break;
      case DatePeriodType.custom:
        yearMonthText =
            '${_weekDateInfo!.startDate.year.toString().substring(2)}.${_weekDateInfo!.startDate.month.toString().padLeft(2, '0')}.${_weekDateInfo!.startDate.day.toString().padLeft(2, '0')}'
                ' ~ ${_weekDateInfo!.endDate.year.toString().substring(2)}.${_weekDateInfo!.endDate.month.toString().padLeft(2, '0')}.${_weekDateInfo!.endDate.day.toString().padLeft(2, '0')}';
        break;
    }
    // final yearMonthText = '${focusedDay.year}.${focusedDay.month.toString().padLeft(2, '0')}월';

    void _showMonthPickerDialog() async {
      final picked = await showMonthPicker(
        context: context,
        initialDate: focusedDay,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        provider.changeFocusedDay(DateTime(picked.year, picked.month));
      }
    }

    Widget _buildCircleArrowButton({required IconData icon, required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F1FD),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 30, color: Color(0xFF5A5A89)),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF1F1FD),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (periodType != DatePeriodType.custom)
              _buildCircleArrowButton(
                icon: Icons.chevron_left,
                onTap: () {
                  final prevMonth = DateTime(focusedDay.year, focusedDay.month - 1);
                  provider.changeFocusedDay(prevMonth);
                },
              ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _showMonthPickerDialog,
              child: Text(
                yearMonthText,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 16),
            if (periodType != DatePeriodType.custom)
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
}

class WeekDateInfo {
  int? weekNumber;
  DateTime startDate;
  DateTime endDate;

  WeekDateInfo({
    this.weekNumber,
    required this.startDate,
    required this.endDate,
  });
}

WeekDateInfo getSundayBasedWeekInfo(DateTime date) {
  // 일요일을 시작으로 하는 주의 시작일
  final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  // 기준점: 1월 1일이 속한 주의 일요일
  final firstDayOfYear = DateTime(date.year, 1, 1);
  final firstWeekStart = firstDayOfYear.subtract(Duration(days: firstDayOfYear.weekday % 7));

  final weekNumber = ((startOfWeek.difference(firstWeekStart).inDays) ~/ 7) + 1;

  return WeekDateInfo(
    weekNumber: weekNumber,
    startDate: startOfWeek,
    endDate: endOfWeek,
  );
}
