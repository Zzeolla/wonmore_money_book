import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wonmore_money_book/util/custom_datetime_picker.dart';

Widget buildFieldRow(String label, Widget field) {
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

Widget buildTextBox(
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
    inputFormatters: type == TextInputType.number
        ? [FilteringTextInputFormatter.digitsOnly]
        : null,
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF1F1FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFA79BFF), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFA79BFF), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
      ),
    ),
  );
}

Widget buildDropdown({
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
      fillColor: const Color(0xFFF1F1FD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFA79BFF), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFA79BFF), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
      ),
    ),
  );
}

Widget buildDateField({
  required BuildContext context,
  required DateTime selectedDate,
  required ValueChanged<DateTime> onDateSelected,
  bool isDateSelectable = true,
}) {
  return GestureDetector(
    onTap: isDateSelectable
        ? () async {
      final picked = await showCustomDateTimePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000, 1, 1),
        lastDate: DateTime(2035, 12, 31),
        mode: PickerMode.dateTime,
        primaryColor: const Color(0xFFA79BFF),
      );
      if (picked != null) {
        onDateSelected(picked);
      }
    }
        : null,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA79BFF), width: 1.2),
      ),
      child: Text(
        DateFormat('yyyy.MM.dd (E), HH:mm', 'ko_KR').format(selectedDate),
        style: TextStyle(
          fontSize: 16,
          color: isDateSelectable ? Colors.black : Colors.grey,
        ),
      ),
    ),
  );
}
