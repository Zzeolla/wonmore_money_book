import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wonmore_money_book/dialog/custom_delete_dialog.dart';
import 'package:wonmore_money_book/dialog/installment_input_dialog.dart';
import 'package:wonmore_money_book/dialog/repeat_record_input_dialog.dart';
import 'package:wonmore_money_book/model/period_type.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/screen/category_management_screen.dart';
import 'package:wonmore_money_book/util/custom_datetime_picker.dart';
import 'package:wonmore_money_book/util/icon_map.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:flutter/services.dart';
import 'package:wonmore_money_book/widget/custom_circle_button.dart';
import 'package:wonmore_money_book/widget/transaction_type_button.dart';

class RecordInputDialog extends StatefulWidget {
  final DateTime initialDate;
  final String? initialTitle;
  final int? initialAmount;
  final TransactionType? initialType;
  final int? initialCategoryId;
  final int? initialAssetId;
  final String? initialMemo;
  final int? transactionId; // 수정할 거래 내역의 ID

  const RecordInputDialog({
    super.key,
    required this.initialDate,
    this.initialTitle,
    this.initialAmount,
    this.initialType,
    this.initialCategoryId,
    this.initialAssetId,
    this.initialMemo,
    this.transactionId,
  });

  @override
  State<RecordInputDialog> createState() => _RecordInputDialogState();
}

class _RecordInputDialogState extends State<RecordInputDialog> {

  late DateTime selectedDate = widget.initialDate;
  TransactionType _selectedType = TransactionType.expense;

  final amountController = TextEditingController();
  final titleController = TextEditingController();
  final memoController = TextEditingController();

  // 포커스 노드 추가
  final _amountFocus = FocusNode();
  final _titleFocus = FocusNode();

  Category? selectedCategory;
  String? selectedAsset;

  final GlobalKey _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 금액 입력 필드 포맷팅을 위한 리스너 추가
    amountController.addListener(_formatAmount);

    // 초기값 설정
    if (widget.initialTitle != null) {
      titleController.text = widget.initialTitle!;
    }
    if (widget.initialAmount != null) {
      amountController.text = widget.initialAmount!.toString();
    }
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
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
    amountController.removeListener(_formatAmount);
    amountController.dispose();
    titleController.dispose();
    memoController.dispose();
    _amountFocus.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  // 금액 포맷팅 함수
  void _formatAmount() {
    final text = amountController.text;
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
    final cursorPosition = amountController.selection.baseOffset;

    // 포맷팅된 텍스트가 현재 텍스트와 다를 경우에만 업데이트
    if (formattedText != text) {
      // 커서 위치 조정 (콤마 추가로 인한 위치 변화 계산)
      final newCursorPosition = cursorPosition + (formattedText.length - text.length);

      amountController.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }
  }

  String _iconSubtitleText() {
    return switch (_selectedType) {
      // todo: 반복/할부 기능 구현 필요
      TransactionType.income => '반복',
      TransactionType.expense => '반복/할부',
      TransactionType.transfer => '반복',
    };
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = context.watch<MoneyProvider>().categories.where((c) => c.type == _selectedType).toList();
    final assetList = context.watch<MoneyProvider>().assets.map((e) => e.name).toList();
    final String title = switch (_selectedType) {
      TransactionType.income => '수입내역',
      TransactionType.expense => '지출내역',
      TransactionType.transfer => '이체',
    };

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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(title,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: GestureDetector(
                            key: _menuKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.repeat, size: 28, color: Colors.black54),
                                const SizedBox(height: 2),
                                Text(
                                  _iconSubtitleText(),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () async {
                              final RenderBox renderBox = _menuKey.currentContext!.findRenderObject() as RenderBox;
                              final Offset offset = renderBox.localToGlobal(Offset.zero);
                              final Size size = renderBox.size;

                              if (_selectedType == TransactionType.income || _selectedType == TransactionType.transfer) {
                                await showDialog(
                                  context: context,
                                  builder: (_) {
                                    final rawAmount = amountController.text.replaceAll(',', '');
                                    final amount = rawAmount.isEmpty ? null : int.tryParse(rawAmount) ?? 0;
                                    final title = titleController.text.trim();
                                    final memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();
                                    final categoryId = selectedCategory?.id;
                                    final assetName = selectedAsset;
                                    final provider = context.read<MoneyProvider>();
                                    int? assetId;
                                    if (assetName != null) {
                                      Asset? asset;
                                      try {
                                        asset =
                                            provider.assets.firstWhere((a) => a.name == assetName);
                                      } catch (_) {
                                        asset = null;
                                      }
                                      assetId = asset?.id;
                                    }
                                    return RepeatRecordInputDialog(
                                      initialStartDate: selectedDate,
                                      initialType: _selectedType,
                                      initialTitle: title,
                                      initialAmount: amount,
                                      initialMemo: memo,
                                      initialCategoryId: categoryId,
                                      initialAssetId: assetId,
                                    );
                                  }
                                ).then((result) {
                                  if (result == true) {
                                    Navigator.pop(context);
                                  }
                                });
                              } else {
                                final selectedMenu = await showMenu<String>(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                    offset.dx,
                                    offset.dy + size.height,
                                    offset.dx + size.width,
                                    offset.dy,
                                  ),
                                  items: [
                                    const PopupMenuItem(value: 'repeat', child: Text('반복')),
                                    const PopupMenuItem(value: 'installment', child: Text('할부')),
                                  ],
                                );

                                if (selectedMenu == null) {
                                  return;
                                } else if (selectedMenu == 'repeat') {
                                  await showDialog(
                                      context: context,
                                      builder: (_) {
                                        final rawAmount = amountController.text.replaceAll(',', '');
                                        final amount = rawAmount.isEmpty ? null : int.tryParse(rawAmount) ?? 0;
                                        final title = titleController.text.trim();
                                        final memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();
                                        final categoryId = selectedCategory?.id;
                                        final assetName = selectedAsset;
                                        final provider = context.read<MoneyProvider>();
                                        int? assetId;
                                        if (assetName != null) {
                                          Asset? asset;
                                          try {
                                            asset =
                                                provider.assets.firstWhere((a) => a.name == assetName);
                                          } catch (_) {
                                            asset = null;
                                          }
                                          assetId = asset?.id;
                                        }
                                        return RepeatRecordInputDialog(
                                          initialStartDate: selectedDate,
                                          initialType: _selectedType,
                                          initialTitle: title,
                                          initialAmount: amount,
                                          initialMemo: memo,
                                          initialCategoryId: categoryId,
                                          initialAssetId: assetId,
                                        );
                                      }
                                  ).then((result) {
                                    if (result == true) {
                                      Navigator.pop(context);
                                    }
                                  });
                                } else {
                                  await showDialog(
                                      context: context,
                                      builder: (_) {
                                        final rawAmount = amountController.text.replaceAll(',', '');
                                        final totalAmount = rawAmount.isEmpty ? null : int.tryParse(rawAmount) ?? 0;
                                        final title = titleController.text.trim();
                                        final memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();
                                        final categoryId = selectedCategory?.id;
                                        final assetName = selectedAsset;
                                        final provider = context.read<MoneyProvider>();
                                        int? assetId;
                                        if (assetName != null) {
                                          Asset? asset;
                                          try {
                                            asset =
                                                provider.assets.firstWhere((a) => a.name == assetName);
                                          } catch (_) {
                                            asset = null;
                                          }
                                          assetId = asset?.id;
                                        }
                                        return InstallmentInputDialog(
                                          initialDate: selectedDate,
                                          initialTitle: title,
                                          initialTotalAmount: totalAmount,
                                          initialMemo: memo,
                                          initialCategoryId: categoryId,
                                          initialAssetId: assetId,
                                        );
                                      }
                                  ).then((result) {
                                    if (result == true) {
                                      Navigator.pop(context);
                                    }
                                  });
                                }
                              }
                            }
                          ),
                        ),
                      ],
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
                          Row(
                            children: [
                              TransactionTypeButton(
                                label: '수입',
                                type: TransactionType.income,
                                selectedType: _selectedType,
                                onSelected: (type) {
                                  setState(() {
                                    _selectedType = type;
                                    selectedCategory = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              TransactionTypeButton(
                                label: '지출',
                                type: TransactionType.expense,
                                selectedType: _selectedType,
                                onSelected: (type) {
                                  setState(() {
                                    _selectedType = type;
                                    selectedCategory = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              TransactionTypeButton(
                                label: '이체',
                                type: TransactionType.transfer,
                                selectedType: _selectedType,
                                onSelected: (type) {
                                  setState(() {
                                    _selectedType = type;
                                    selectedCategory = null;
                                  });
                                },
                                enabled: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildFieldRow('날짜', _buildDateField()),
                          _buildFieldRow(
                              '금액',
                              _buildTextBox(
                                amountController,
                                TextInputType.number,
                                focusNode: _amountFocus,
                                onSubmitted: (_) => _titleFocus.requestFocus(),
                              )),
                          _buildFieldRow(
                              '내역',
                              _buildTextBox(
                                titleController,
                                TextInputType.text,
                                focusNode: _titleFocus,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                              )),
                          _buildFieldRow(
                            '분류',
                            _buildDropdown(
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
                                        selectedType: _selectedType,
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
                          _buildFieldRow(
                            '자산',
                            _buildDropdown(
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
                          _buildFieldRow(
                              '메모',
                              _buildTextBox(
                                memoController,
                                TextInputType.multiline,
                                maxLines: 3,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                              )),
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
                        CustomCircleButton(
                          icon: Icons.star_border_purple500,
                          color: Colors.white,
                          backgroundColor: const Color(0xFFA79BFF),
                          onTap: () async {
                            final favoriteRecords = context.read<MoneyProvider>().favoriteRecords
                                .where((f) => f.period == PeriodType.none).toList();
                            final selected = await showFavoritePickerDialog(context, favoriteRecords);

                            if (selected != null) {
                              setState(() {
                                amountController.text = selected.amount.toString();
                                titleController.text = selected.title ?? '';
                                memoController.text = selected.memo ?? '';
                                _selectedType = selected.type;

                                selectedCategory = context.read<MoneyProvider>().categories.firstWhere(
                                      (c) => c.id == selected.categoryId,
                                  orElse: () => context.read<MoneyProvider>().categories.first,
                                );

                                selectedAsset = context.read<MoneyProvider>().assets.firstWhere(
                                      (a) => a.id == selected.assetId,
                                  orElse: () => context.read<MoneyProvider>().assets.first,
                                ).name;
                              });
                            }
                          },
                        ),
                        if (widget.transactionId != null)
                          CustomCircleButton(
                            icon: Icons.delete_outline,
                            color: Colors.white,
                            backgroundColor: const Color(0xFFA79BFF),
                            onTap: () async {
                              if (widget.transactionId == null) {
                                Navigator.pop(context);
                              } else {
                                final result = await showCustomDeleteDialog(
                                    context,
                                    message: '이 내역을 정말 삭제할까요?'
                                );
                                if (result!) {
                                  await context.read<MoneyProvider>().deleteTransaction(widget.transactionId!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('삭제되었습니다')),
                                  );
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                        CustomCircleButton(
                          icon: Icons.check,
                          color: Colors.white,
                          backgroundColor: const Color(0xFFA79BFF),
                          onTap: () async {
                            // 입력값 검증 (금액, 내역 필수)
                            if (amountController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('금액과 내역을 입력해 주세요.')),
                              );
                              return;
                            }
                            final amount =
                                int.tryParse(amountController.text.replaceAll(',', '')) ?? 0;
                            final title = titleController.text.trim();
                            final memo = memoController.text.trim().isEmpty
                                ? null
                                : memoController.text.trim();
                            final categoryId = selectedCategory?.id;
                            final assetName = selectedAsset;
                            final provider = context.read<MoneyProvider>();
                            int? assetId;
                            if (assetName != null) {
                              Asset? asset;
                              try {
                                asset = provider.assets.firstWhere((a) => a.name == assetName);
                              } catch (_) {
                                asset = null;
                              }
                              assetId = asset?.id;
                            }
                            try {
                              if (widget.transactionId != null) {
                                // 변경 사항이 있는지 확인
                                final hasChanges = widget.initialDate != selectedDate ||
                                    widget.initialAmount != amount ||
                                    widget.initialType != _selectedType ||
                                    widget.initialCategoryId != categoryId ||
                                    widget.initialAssetId != assetId ||
                                    widget.initialTitle != title ||
                                    widget.initialMemo != memo;

                                if (hasChanges) {
                                  await provider.updateTransaction(
                                    widget.transactionId!,
                                    TransactionsCompanion(
                                      date: drift.Value(selectedDate),
                                      amount: drift.Value(amount),
                                      type: drift.Value(_selectedType),
                                      categoryId: categoryId == null
                                          ? const drift.Value.absent()
                                          : drift.Value(categoryId),
                                      assetId: assetId == null
                                          ? const drift.Value.absent()
                                          : drift.Value(assetId),
                                      title: drift.Value(title),
                                      memo: memo == null
                                          ? const drift.Value.absent()
                                          : drift.Value(memo),
                                      updatedAt: drift.Value(DateTime.now()),
                                    ),
                                  );
                                  Navigator.pop(context, true);
                                } else {
                                  Navigator.pop(context, false);
                                }
                              } else {
                                // 새로운 거래내역 추가
                                await provider.addTransaction(
                                  TransactionsCompanion(
                                    date: drift.Value(selectedDate),
                                    amount: drift.Value(amount),
                                    type: drift.Value(_selectedType),
                                    categoryId: categoryId == null
                                        ? const drift.Value.absent()
                                        : drift.Value(categoryId),
                                    assetId: assetId == null
                                        ? const drift.Value.absent()
                                        : drift.Value(assetId),
                                    title: drift.Value(title),
                                    memo: memo == null
                                        ? const drift.Value.absent()
                                        : drift.Value(memo),
                                    createdAt: drift.Value(DateTime.now()),
                                    updatedAt: drift.Value(DateTime.now()),
                                  ),
                                );
                                Navigator.pop(context, true);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('저장에 실패했습니다. 다시 시도해 주세요.')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height:6)
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldRow(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: label == '메모' ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _buildTextBox(
    TextEditingController controller,
    TextInputType type, {
    int maxLines = 1,
    FocusNode? focusNode,
    void Function(String)? onSubmitted,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: type,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
      textInputAction:
          textInputAction ?? (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
      inputFormatters: type == TextInputType.number
          ? [
              FilteringTextInputFormatter.digitsOnly,
            ]
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFFF1F1FD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFA79BFF), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFA79BFF), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFA79BFF)),
      dropdownColor: Colors.white,
      style: const TextStyle(fontSize: 16, color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFFF1F1FD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFA79BFF), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFA79BFF), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showCustomDateTimePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000, 1, 1),
          lastDate: DateTime(2035, 12, 31),
          mode: PickerMode.dateTime,
          primaryColor: Color(0xFFA79BFF),
        );
        if (picked != null) {
          setState(() {
            selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFFF1F1FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFA79BFF), width: 1.2),
        ),
        child: Text(
          DateFormat('yyyy.MM.dd (E), HH:mm', 'ko_KR').format(selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<FavoriteRecord?> showFavoritePickerDialog(BuildContext context, List<FavoriteRecord> favorites) {
    return showDialog<FavoriteRecord>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF1F1FD),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '자주 사용하는 내역',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 400, // 높이 지정 (스크롤 허용)
                width: double.maxFinite,
                child: Consumer<MoneyProvider>(
                  builder: (context, provider, _) {
                    final categories = provider.categories;
                    final assets = provider.assets;

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: favorites.length,
                      itemBuilder: (_, index) {
                        final favoriteRecord = favorites[index];
                        final category = categories.firstWhere(
                              (c) => c.id == favoriteRecord.categoryId,
                          orElse: () => categories.first,
                        );
                        final asset = assets.firstWhere(
                              (a) => a.id == favoriteRecord.assetId,
                          orElse: () => assets.first,
                        ).name;
                        return Card(
                          key: ValueKey(favoriteRecord.id),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.amberAccent, width: 1),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: SizedBox(
                              width: 50,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(category.colorValue),
                                    child: Icon(
                                      getIconData(category.iconName),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  Text(
                                    category.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        favoriteRecord.title ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        asset,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${favoriteRecord.type == TransactionType.income ? '+' : '-'}${NumberFormat('#,###').format(favoriteRecord.amount)}원',
                                  style: TextStyle(
                                    color: favoriteRecord.type == TransactionType.income
                                        ? Colors.blue
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.pop(context, favoriteRecord),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
