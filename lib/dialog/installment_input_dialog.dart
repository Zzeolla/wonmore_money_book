import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/dialog/custom_delete_dialog.dart';
import 'package:wonmore_money_book/model/asset_model.dart';
import 'package:wonmore_money_book/model/category_model.dart';
import 'package:wonmore_money_book/model/installment_model.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/screen/category_management_screen.dart';
import 'package:wonmore_money_book/util/icon_map.dart';
import 'package:wonmore_money_book/widget/common_input_field.dart';
import 'package:wonmore_money_book/widget/custom_circle_button.dart';

class InstallmentInputDialog extends StatefulWidget {
  final DateTime initialDate;
  final String? initialTitle;
  final int? initialTotalAmount;
  final int? initialMonths;
  final String? initialCategoryId;
  final String? initialAssetId;
  final String? initialMemo;
  final String? installmentId; // 수정할 거래 내역의 ID

  const InstallmentInputDialog({
    super.key,
    required this.initialDate,
    this.initialTitle,
    this.initialTotalAmount,
    this.initialMonths,
    this.initialCategoryId,
    this.initialAssetId,
    this.initialMemo,
    this.installmentId,
  });

  @override
  State<InstallmentInputDialog> createState() => _InstallmentInputDialogState();
}

class _InstallmentInputDialogState extends State<InstallmentInputDialog> {
  late DateTime selectedDate = widget.initialDate;

  final monthsController = TextEditingController();
  final totalAmountController = TextEditingController();
  final titleController = TextEditingController();
  final memoController = TextEditingController();

  // 포커스 노드 추가
  final _monthsFocus = FocusNode();
  final _totalAmountFocus = FocusNode();
  final _titleFocus = FocusNode();

  CategoryModel? selectedCategory;
  String? selectedAsset;

  @override
  void initState() {
    super.initState();
    // 금액 입력 필드 포맷팅을 위한 리스너 추가
    totalAmountController.addListener(_formatAmount);

    // 초기값 설정
    if (widget.initialTitle != null) {
      titleController.text = widget.initialTitle!;
    }
    if (widget.initialTotalAmount != null) {
      totalAmountController.text = widget.initialTotalAmount!.toString();
    }
    if (widget.initialMonths != null) {
      monthsController.text = widget.initialMonths!.toString();
    }
    if (widget.initialMemo != null) {
      memoController.text = widget.initialMemo!;
    }
    if (widget.initialCategoryId != null) {
      selectedCategory = context.read<MoneyProvider>().categories.firstWhere(
            (c) => c.id == widget.initialCategoryId,
            orElse: () => context.read<MoneyProvider>().categories.first,
          );
    }
    if (widget.initialAssetId != null) {
      final asset = context.read<MoneyProvider>().assets.firstWhere(
            (a) => a.id == widget.initialAssetId,
            orElse: () => context.read<MoneyProvider>().assets.first,
          );
      selectedAsset = asset.name;
    }
  }

  @override
  void dispose() {
    totalAmountController.removeListener(_formatAmount);
    monthsController.dispose();
    totalAmountController.dispose();
    titleController.dispose();
    memoController.dispose();
    _monthsFocus.dispose();
    _totalAmountFocus.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  // 금액 포맷팅 함수
  void _formatAmount() {
    final text = totalAmountController.text;
    if (text.isEmpty) return;

    // 콤마 제거
    final cleanText = text.replaceAll(',', '');

    // 숫자가 아닌 문자 제거
    final numericText = cleanText.replaceAll(RegExp(r'[^\d]'), '');

    // 포맷팅된 텍스트 생성
    final formattedText = numericText.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    // 현재 커서 위치 저장
    final cursorPosition = totalAmountController.selection.baseOffset;

    // 포맷팅된 텍스트가 현재 텍스트와 다를 경우에만 업데이트
    if (formattedText != text) {
      // 커서 위치 조정 (콤마 추가로 인한 위치 변화 계산)
      final newCursorPosition = cursorPosition + (formattedText.length - text.length);

      totalAmountController.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }
  }

  @override
  Widget build(BuildContext context) {;
    final filteredCategories = context.watch<MoneyProvider>().categories.where((c) => c.type == TransactionType.expense).toList();
    final assetList = context.watch<MoneyProvider>().assets.map((e) => e.name).toList();

    // 키보드 높이 확인
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.9; // 화면 높이의 90%

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: dialogHeight,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 제목 + 아이콘 영역
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F1FD),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('할부내역',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const Divider(height: 1, thickness: 1, color: Color(0xFFDADCE0)),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: 20 + keyboardHeight, // 키보드 높이만큼 하단 패딩 추가
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          buildFieldRow(
                            '날짜',
                            buildDateField(
                              context: context,
                              selectedDate: selectedDate,
                              onDateSelected: (value) {
                                setState(() {
                                  selectedDate = value;
                                });
                              },
                            ),
                          ),
                          buildFieldRow(
                            '기간',
                            Row(
                              children: [
                                Expanded(
                                  child: buildTextBox(
                                    monthsController,
                                    TextInputType.number,
                                    focusNode: _monthsFocus,
                                    onSubmitted: (_) => _totalAmountFocus.requestFocus(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '개월',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          buildFieldRow(
                            '금액',
                            buildTextBox(
                              totalAmountController,
                              TextInputType.number,
                              focusNode: _totalAmountFocus,
                              onSubmitted: (_) => _titleFocus.requestFocus(),
                            ),
                          ),
                          buildFieldRow(
                            '내역',
                            buildTextBox(
                              titleController,
                              TextInputType.text,
                              focusNode: _titleFocus,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => FocusScope.of(context).unfocus(),
                            ),
                          ),
                          buildFieldRow(
                            '분류',
                            buildDropdown(
                              value: selectedCategory?.name ?? '__none__',
                              items: [
                                DropdownMenuItem<String>(
                                  value: '__none__',
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.grey.shade300,
                                        child:
                                            Icon(Icons.help_outline, color: Colors.white, size: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('선택하세요', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                ...filteredCategories.map(
                                  (c) => DropdownMenuItem(
                                    value: c.name,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Color(c.colorValue),
                                          child: Icon(getIconData(c.iconName),
                                              color: Colors.white, size: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(c.name, style: TextStyle(fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
                                DropdownMenuItem<String>(
                                  value: '---divider---', // 이건 구분용으로 사용
                                  enabled: false,
                                  child: Column(
                                    children: [
                                      const Divider(height: 1, thickness: 1),
                                    ],
                                  ),
                                ),
                                const DropdownMenuItem<String>(
                                  value: '__edit__',
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.black,
                                        child: Icon(Icons.edit, color: Colors.white, size: 16),
                                      ),
                                      SizedBox(width: 8),
                                      Text('분류 수정', style: TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == '__edit__') {
                                  // 분류 수정 화면으로 이동
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryManagementScreen(
                                        selectedType: TransactionType.expense,
                                      ),
                                    ),
                                  ).then((_) {
                                    if (mounted) setState(() => selectedCategory = null);
                                  });
                                } else {
                                  setState(
                                    () {
                                      selectedCategory = value == '__none__'
                                          ? null
                                          : filteredCategories.firstWhere((c) => c.name == value);
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                          buildFieldRow(
                            '자산',
                            buildDropdown(
                              value: selectedAsset,
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('선택하세요', style: TextStyle(color: Colors.grey)),
                                ),
                                ...assetList.map(
                                  (a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(a),
                                  ),
                                ),
                              ],
                              onChanged: (value) => setState(() => selectedAsset = value),
                            ),
                          ),
                          buildFieldRow(
                            '메모',
                            buildTextBox(
                              memoController,
                              TextInputType.multiline,
                              maxLines: 3,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => FocusScope.of(context).unfocus(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomCircleButton(
                            icon: Icons.close,
                            color: Colors.black54,
                            backgroundColor: const Color(0xFFE5E6EB),
                            onTap: () => Navigator.pop(context)),
                        if (widget.installmentId != null)
                          CustomCircleButton(
                            icon: Icons.delete_outline,
                            color: Colors.white,
                            backgroundColor: const Color(0xFFA79BFF),
                            onTap: () async {
                              final result =
                                  await showCustomDeleteDialog(context, message: '이 내역을 정말 삭제할까요?');
                              if (result!) {
                                await context
                                    .read<MoneyProvider>()
                                    .deleteInstallment(widget.installmentId!); /// TODO: 삭제 provider 생성 및 적용 필요
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('삭제되었습니다')),
                                );
                                Navigator.pop(context);
                              }
                            },
                          ),
                        CustomCircleButton(
                          icon: Icons.check,
                          color: Colors.white,
                          backgroundColor: const Color(0xFFA79BFF),
                          onTap: () async {
                            // 입력값 검증 (금액, 내역 필수)
                            if (totalAmountController.text.trim().isEmpty || monthsController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('금액과 기간을 입력해 주세요.')),
                              );
                              return;
                            }
                            final totalAmount =
                                int.tryParse(totalAmountController.text.replaceAll(',', '')) ?? 0;
                            final months = int.tryParse(monthsController.text.trim()) ?? 0;
                            final title = titleController.text.trim();
                            final memo = memoController.text.trim().isEmpty
                                ? null
                                : memoController.text.trim();
                            final categoryId = selectedCategory?.id;
                            final assetName = selectedAsset;
                            final provider = context.read<MoneyProvider>();
                            String? assetId;
                            if (assetName != null) {
                              AssetModel? asset;
                              try {
                                asset = provider.assets.firstWhere((a) => a.name == assetName);
                              } catch (_) {
                                asset = null;
                              }
                              assetId = asset?.id;
                            }
                            try {
                              if (widget.installmentId != null) {
                                // 변경 사항이 있는지 확인
                                final hasChanges = widget.initialDate != selectedDate ||
                                    widget.initialTotalAmount != totalAmount ||
                                    widget.initialMonths != months ||
                                    widget.initialCategoryId != categoryId ||
                                    widget.initialAssetId != assetId ||
                                    widget.initialTitle != title ||
                                    widget.initialMemo != memo;

                                if (hasChanges) {
                                  await provider.updateInstallment(
                                    widget.installmentId!,
                                    InstallmentModel(
                                      date: selectedDate,
                                      totalAmount: totalAmount,
                                      months: months,
                                      categoryId: categoryId,
                                      assetId: assetId,
                                      title: title,
                                      memo: memo,
                                    ),
                                  );
                                  Navigator.pop(context, true);
                                } else {
                                  Navigator.pop(context, false);
                                }
                              } else {
                                // 새로운 거래내역 추가
                                await provider.addInstallment(
                                  InstallmentModel(
                                    date: selectedDate,
                                    totalAmount: totalAmount,
                                    months: months,
                                    categoryId: categoryId,
                                    assetId: assetId,
                                    title: title,
                                    memo: memo,
                                  ),
                                );
                                Navigator.pop(context, true);
                              }
                            } catch (e) {
                              debugPrint('💥 Installment 저장 실패: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('저장에 실패했습니다. 다시 시도해 주세요.')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6)
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
