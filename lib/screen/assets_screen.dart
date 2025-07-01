import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/component/banner_ad_widget.dart';
import 'package:wonmore_money_book/dialog/asset_input_dialog.dart';
import 'package:wonmore_money_book/dialog/custom_delete_dialog.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/widget/common_app_bar.dart';
import 'package:wonmore_money_book/widget/common_drawer.dart';
import 'package:wonmore_money_book/widget/year_month_header.dart';

class AssetsScreen extends StatelessWidget {
  AssetsScreen({super.key});

  final currencyFormat = NumberFormat('#,###원', 'ko_KR');

  @override
  Widget build(BuildContext context) {
    final assets = context.watch<MoneyProvider>().assets;
    return Scaffold(
      appBar: CommonAppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Color(0xFFF2F4F6), size: 30),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AssetInputDialog(),
            ),
          ),
        ]
      ),
      drawer: CommonDrawer(),
      backgroundColor: const Color(0xFFFDF7FF),
      body: Column(
        children: [
          /// 연도.월 + 화살표 구현
          YearMonthHeader(),
          assets.isEmpty
              ? Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 64, color: Color(0xFFB0AFFF)),
                          SizedBox(height: 16),
                          Text(
                            '등록된 자산이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A5A89),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '목표 금액을 정하여 매 달 실적 관리가 가능합니다',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Expanded(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(context, '💰 내 자산', [
                          for (final asset in assets)
                            _buildCard(
                              context,
                              asset.id!,
                              asset.name,
                              asset.targetAmount,
                            ),
                        ]),
                      ],
                    ),
                  ),
              ),
          BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Divider(thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(child: Divider(thickness: 1)),
          ],
        ),
        const SizedBox(height: 12),
        ...cards,
      ],
    );
  }

  Widget _buildCard(BuildContext context, String id, String name, targetAmount) {
    final income = context.read<MoneyProvider>().getIncomeByAsset(id);
    final expense = context.read<MoneyProvider>().getExpenseByAsset(id);
    final progress = (targetAmount > 0) ? (expense / targetAmount).clamp(0.0, 1.0) : 0.0;
    final percentText = '${(progress * 100).toStringAsFixed(0)}%';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: () async {
            final result = await showCustomDeleteDialog(
              context,
              message: '이 자산을 정말 삭제할까요?',
            );
            if (result!) {
              await context.read<MoneyProvider>().deleteAsset(id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('삭제되었습니다.')),
              );
            }
          },
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AssetInputDialog(
                assetId: id,
                initialName: name,
                initialTargetAmount: targetAmount,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amberAccent, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 이름 + 오른쪽 금액 레이블
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          income > 0 ? '+${currencyFormat.format(income)}' : '',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        Text(
                          expense > 0 ? '-${currencyFormat.format(expense)}' : '',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ],
                ),
                targetAmount > 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '목표 금액 : ${currencyFormat.format(targetAmount)}',
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                percentText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          )
                        ],
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
