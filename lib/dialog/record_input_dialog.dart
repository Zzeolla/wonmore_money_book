import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/database/database.dart';
import 'package:wonmore_money_book/util/custom_datetime_picker.dart';
import 'package:wonmore_money_book/util/icon_map.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';
import 'package:flutter/services.dart';

class RecordInputDialog extends StatefulWidget {
  final DateTime initialDate;
  final List<Category> categories;
  final List<String> assetList;

  const RecordInputDialog({
    super.key,
    required this.initialDate,
    required this.categories,
    required this.assetList,
  });

  @override
  State<RecordInputDialog> createState() => _RecordInputDialogState();
}

class _RecordInputDialogState extends State<RecordInputDialog> {
  late DateTime selectedDate = widget.initialDate;
  late TransactionType _selectedType = TransactionType.expense;

  final amountController = TextEditingController();
  final contentController = TextEditingController();
  final memoController = TextEditingController();

  // 포커스 노드 추가
  final _amountFocus = FocusNode();
  final _contentFocus = FocusNode();

  Category? selectedCategory;
  String? selectedAsset;

  @override
  void initState() {
    super.initState();
    // 금액 입력 필드 포맷팅을 위한 리스너 추가
    amountController.addListener(_formatAmount);
  }

  @override
  void dispose() {
    amountController.removeListener(_formatAmount);
    amountController.dispose();
    contentController.dispose();
    memoController.dispose();
    _amountFocus.dispose();
    _contentFocus.dispose();
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

  List<Category> get _filteredCategories {
    return widget.categories.where((c) => c.type == _selectedType).toList();
  }

  String _iconSubtitleText() {
    return switch (_selectedType) {
      TransactionType.income => '반복',
      TransactionType.expense => '반복/할부',
      TransactionType.transfer => '반복',
    };
  }

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
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
                            child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 4.0),
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
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, thickness: 1, color: Color(0xFFDADCE0)),

                    Padding(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: 20 + keyboardHeight, // 키보드 높이만큼 하단 패딩 추가
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildTypeButton('수입', TransactionType.income),
                              const SizedBox(width: 8),
                              _buildTypeButton('지출', TransactionType.expense),
                              const SizedBox(width: 8),
                              _buildTypeButton('이체', TransactionType.transfer, enabled: false),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildFieldRow('날짜', _buildDateField()),
                          _buildFieldRow('금액', _buildTextBox(
                            amountController,
                            TextInputType.number,
                            focusNode: _amountFocus,
                            onSubmitted: (_) => _contentFocus.requestFocus(),
                          )),
                          _buildFieldRow('내역', _buildTextBox(
                            contentController,
                            TextInputType.text,
                            focusNode: _contentFocus,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          )),
                          _buildFieldRow('분류', _buildDropdown(
                            value: selectedCategory?.name,
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.grey.shade300,
                                      child: Icon(Icons.help_outline, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('선택하세요', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              ..._filteredCategories.map((c) => DropdownMenuItem(
                                value: c.name,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Color(c.colorValue),
                                      child: Icon(getIconData(c.iconName), color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(c.name, style: TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedCategory = value == null ? null : 
                                  _filteredCategories.firstWhere((c) => c.name == value);
                              });
                            },
                          )),
                          _buildFieldRow('자산', _buildDropdown(
                            value: selectedAsset,
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text('선택하세요', style: TextStyle(color: Colors.grey)),
                              ),
                              ...widget.assetList.map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(a),
                              )),
                            ],
                            onChanged: (value) => setState(() => selectedAsset = value),
                          )),
                          _buildFieldRow('메모', _buildTextBox(
                            memoController,
                            TextInputType.multiline,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          )),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.star_border, size: 32),
                                tooltip: '즐겨찾기',
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.delete_outline, size: 32),
                                tooltip: '취소',
                              ),
                              IconButton(
                                onPressed: () async {
                                  // 입력값 검증 (금액, 내역 필수)
                                  if (amountController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('금액과 내역을 입력해 주세요.')),
                                    );
                                    return;
                                  }
                                  final amount = int.tryParse(amountController.text.trim()) ?? 0;
                                  final title = contentController.text.trim();
                                  final memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();
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
                                    // 새로운 거래내역 추가
                                    await provider.addTransaction(
                                      TransactionsCompanion(
                                        date: drift.Value(selectedDate),
                                        amount: drift.Value(amount),
                                        type: drift.Value(_selectedType),
                                        categoryId: categoryId == null ? const drift.Value.absent() : drift.Value(categoryId),
                                        assetId: assetId == null ? const drift.Value.absent() : drift.Value(assetId),
                                        title: drift.Value(title),
                                        memo: memo == null ? const drift.Value.absent() : drift.Value(memo),
                                      ),
                                    );
                                    Navigator.pop(context, true);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('저장에 실패했습니다. 다시 시도해 주세요.')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check, size: 32),
                                tooltip: '확인',
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeButton(String label, TransactionType type, {bool enabled = true}) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: enabled ? () {
            setState(() {
              selectedCategory = null; // 거래 유형 변경 시 카테고리 초기화
              _selectedType = type;
            });
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.amber : Colors.grey.shade300,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label),
        ),
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
            child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
      textInputAction: textInputAction ?? (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
      inputFormatters: type == TextInputType.number ? [
        FilteringTextInputFormatter.digitsOnly,
      ] : null,
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
}
