import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/dialog/custom_delete_dialog.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';
import 'package:wonmore_money_book/widget/custom_circle_button.dart';

class AssetInputDialog extends StatefulWidget {
  final int? assetId;
  final String? initialName;
  final int? initialTargetAmount;

  const AssetInputDialog({
    super.key,
    this.assetId,
    this.initialName,
    this.initialTargetAmount,
  });

  @override
  State<AssetInputDialog> createState() => _AssetInputDialogState();
}

class _AssetInputDialogState extends State<AssetInputDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _targetAmountController.addListener(_formatAmount);

    _nameController.text = widget.initialName ?? '';
    _targetAmountController.text = widget.initialTargetAmount?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  void _formatAmount() {
    final text = _targetAmountController.text;
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
    final cursorPosition = _targetAmountController.selection.baseOffset;

    // 포맷팅된 텍스트가 현재 텍스트와 다를 경우에만 업데이트
    if (formattedText != text) {
      // 커서 위치 조정 (콤마 추가로 인한 위치 변화 계산)
      final newCursorPosition = cursorPosition + (formattedText.length - text.length);

      _targetAmountController.value = TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF1F1FD),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MediaQuery.of(context).viewInsets.bottom > 0
                ? const SizedBox(height: 12)
                : const SizedBox(height: 0),
            const Text(
              '할 일 입력',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            // 제목 필드
            _buildTextBox(
              controller: _nameController,
              label: '자산 이름',
              icon: Icons.edit,
              hintText: '(예: 삼성카드, 신한은행 등)',
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildTextBox(
              controller: _targetAmountController,
              label: '실적 목표',
              icon: Icons.track_changes,
              hintText: '실적 관리를 위해 목표 금액을 설정하세요',
              type: TextInputType.number,
            ),
            const SizedBox(height: 32),

            // 하단 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomCircleButton(
                    icon: Icons.close,
                    color: Colors.black54,
                    backgroundColor: const Color(0xFFE5E6EB),
                    onTap: () => Navigator.pop(context)),
                CustomCircleButton(
                  icon: Icons.delete_outline,
                  color: Colors.white,
                  backgroundColor: const Color(0xFFA79BFF),
                  onTap: () async {
                    if (widget.assetId == null) {
                      Navigator.pop(context);
                    } else {
                      final result = await showCustomDeleteDialog(
                        context,
                        message: '이 자산을 정말 삭제할까요?'
                      );
                      if (result!) {
                        await context.read<MoneyProvider>().deleteAsset(widget.assetId!);
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
                    final docDir = await getApplicationDocumentsDirectory();
                    print('Doc dir: ${docDir.path}');
                    final dbFile = File('${docDir.path}/db.sqlite');
                    print('DB exists: ${await dbFile.exists()}');
                    final name = _nameController.text.trim();
                    final targetAmount =
                        int.tryParse(_targetAmountController.text.replaceAll(',', '')) ?? 0;
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('자산 이름을 입력해 주세요.')),
                      );
                      return;
                    }

                    if (widget.assetId != null) {
                      final hasChanges =
                          widget.initialName != name || widget.initialTargetAmount != targetAmount;

                      if (hasChanges) {
                        await context.read<MoneyProvider>().updateAsset(
                              widget.assetId!,
                              name,
                              targetAmount,
                            );
                      } else {
                        Navigator.pop(context);
                        return;
                      }
                    } else {
                      await context.read<MoneyProvider>().addAsset(
                            name,
                            targetAmount,
                          );
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextBox({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 28, color: const Color(0xFFA79BFF)),
            const SizedBox(width: 12),
            Text(isRequired ? '$label *' : label,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: type,
          inputFormatters:
              type == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
