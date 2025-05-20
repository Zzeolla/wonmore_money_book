import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/money_provider.dart';
import 'package:wonmore_money_book/util/icon_map.dart';
import 'package:wonmore_money_book/util/color_palette.dart';
import 'package:wonmore_money_book/widget/custom_circle_button.dart';
import 'package:drift/drift.dart' as drift;
import 'package:wonmore_money_book/model/transaction_type.dart';
import 'package:wonmore_money_book/database/database.dart';

class CategoryInputDialog extends StatefulWidget {
  final Category? category;
  final TransactionType type;

  const CategoryInputDialog({
    super.key,
    this.category,
    required this.type,
  });

  @override
  State<CategoryInputDialog> createState() => _CategoryInputDialogState();
}

class _CategoryInputDialogState extends State<CategoryInputDialog> {
  final _nameController = TextEditingController();
  String? _selectedIconName;
  Color? _selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedIconName = widget.category!.iconName;
      _selectedColor = Color(widget.category!.colorValue);
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
            const Text(
              '카테고리 입력',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 32),

            _buildTextBox(
              controller: _nameController,
              label: '이름',
              icon: Icons.edit,
              hintText: '예: 식비, 교통비',
              isRequired: true,
            ),
            const SizedBox(height: 32),

            _buildIconPicker(),
            const SizedBox(height: 32),

            _buildColorPicker(),

            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomCircleButton(
                  icon: Icons.close,
                  color: Colors.black54,
                  backgroundColor: const Color(0xFFE5E6EB),
                  onTap: () => Navigator.pop(context),
                ),
                CustomCircleButton(
                  icon: Icons.check,
                  color: Colors.white,
                  backgroundColor: const Color(0xFFA79BFF),
                  onTap: _handleSave,
                ),
              ],
            ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 28, color: const Color(0xFFA79BFF)),
            const SizedBox(width: 12),
            Text(
              isRequired ? '$label *' : label,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
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

  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.category, size: 28, color: Color(0xFFA79BFF)),
            SizedBox(width: 12),
            Text('아이콘 선택 *', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: GridView.count(
            crossAxisCount: 5,
            padding: const EdgeInsets.all(4),
            children: iconMap.entries.map((entry) {
              final isSelected = _selectedIconName == entry.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedIconName = entry.key),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber.shade100 : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.amber : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(entry.value, size: 30, color: Colors.black87),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.palette, size: 28, color: Color(0xFFA79BFF)),
            SizedBox(width: 12),
            Text('색상 선택 *', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableColors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedIconName == null || _selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 값을 입력해주세요.')),
      );
      return;
    }

    final provider = context.read<MoneyProvider>();

    if (widget.category == null) {
      await provider.addCategory(
        CategoriesCompanion.insert(
          name: name,
          iconName: drift.Value(_selectedIconName!),
          colorValue: drift.Value(_selectedColor!.value),
          type: widget.type,
        ),
      );
    } else {
      final hasChanged = name != widget.category!.name ||
          _selectedIconName != widget.category!.iconName ||
          _selectedColor!.value != widget.category!.colorValue;

      if (hasChanged) {
        await provider.updateCategory(
          widget.category!.copyWith(
            name: name,
            iconName: _selectedIconName!,
            colorValue: _selectedColor!.value,
          ),
        );
      }
    }

    if (context.mounted) Navigator.pop(context, true);
  }
}
