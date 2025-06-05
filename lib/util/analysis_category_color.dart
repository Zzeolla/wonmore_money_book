import 'package:flutter/material.dart';

/// 기본 카테고리 → 고정 색상 매핑
const Map<String, Color> defaultCategoryColors = {
  // 수입
  '급여': Colors.teal,
  '용돈': Colors.lightBlue,
  '부수입': Colors.indigo,

  // 지출
  '식비': Colors.green,
  '교통비': Colors.blue,
  '쇼핑': Colors.pink,
  '문화생활': Colors.deepPurple,
  '주거비': Colors.brown,
  '통신비': Colors.orange,
  '보험료': Colors.redAccent,
  '교육비': Colors.cyan,
};

/// 자동 색상 후보 리스트
final List<Color> autoCategoryColors = [
  Colors.amber,
  Colors.deepOrange,
  Colors.blueGrey,
  Colors.lime,
  Colors.purpleAccent,
  Colors.greenAccent,
  Colors.lightGreen,
  Colors.yellow,
  Colors.deepPurpleAccent,
  Colors.cyanAccent,
];

/// 사용된 자동 색상 추적
final Set<Color> _usedAutoColors = {};

/// 카테고리 이름 기반으로 색상 반환
Color getColorForCategory(String name) {
  // 기본 카테고리면 고정 색상 반환
  if (defaultCategoryColors.containsKey(name)) {
    return defaultCategoryColors[name]!;
  }

  // 이미 할당된 색상 피해서 자동 색상 부여
  for (final color in autoCategoryColors) {
    if (!_usedAutoColors.contains(color)) {
      _usedAutoColors.add(color);
      return color;
    }
  }

  // 예비: 다 써버리면 해시 기반으로 선택
  final fallback = autoCategoryColors[name.hashCode % autoCategoryColors.length];
  return fallback;
}

/// 색상 초기화 (예: 앱 시작 시 리셋)
void resetUsedAutoColors() {
  _usedAutoColors.clear();
}