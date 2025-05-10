import 'package:flutter/material.dart';

final Map<String, IconData> iconMap = {
  // 식비/음식
  'restaurant': Icons.restaurant,
  'fastfood': Icons.fastfood,
  'local_cafe': Icons.local_cafe,
  'cake': Icons.cake,
  'local_bar': Icons.local_bar,
  'free_breakfast': Icons.free_breakfast,
  'emoji_food_beverage': Icons.emoji_food_beverage,

  // 쇼핑/패션
  'shopping_bag': Icons.shopping_bag,
  'shopping_cart': Icons.shopping_cart,
  'store': Icons.store,
  'loyalty': Icons.loyalty,
  'local_mall': Icons.local_mall,
  'redeem': Icons.redeem,

  // 교통/이동
  'commute': Icons.commute,
  'two_wheeler': Icons.two_wheeler,
  'airport_shuttle': Icons.airport_shuttle,
  'directions_car': Icons.directions_car,
  'train': Icons.train,
  'subway': Icons.subway,
  'local_taxi': Icons.local_taxi,

  // 금융/저축/지출
  'attach_money': Icons.attach_money,
  'account_balance': Icons.account_balance,
  'credit_card': Icons.credit_card,
  'savings': Icons.savings,
  'monetization_on': Icons.monetization_on,
  'euro_symbol': Icons.euro_symbol,

  // 주거/생활
  'home': Icons.home,
  'weekend': Icons.weekend,
  'local_laundry_service': Icons.local_laundry_service,
  'local_hospital': Icons.local_hospital,
  'local_florist': Icons.local_florist,
  'local_grocery_store': Icons.local_grocery_store,
  'local_pharmacy': Icons.local_pharmacy,
  'local_library': Icons.local_library,

  // 건강/운동
  'fitness_center': Icons.fitness_center,
  'spa': Icons.spa,
  'sports_tennis': Icons.sports_tennis,
  'directions_run': Icons.directions_run,
  'self_improvement': Icons.self_improvement,

  // 가족/교육/반려동물
  'school': Icons.school,
  'child_friendly': Icons.child_friendly,
  'pets': Icons.pets,
  'favorite': Icons.favorite,

  // 취미/여가/문화
  'movie': Icons.movie,
  'music_note': Icons.music_note,
  'palette': Icons.palette,
  'camera_alt': Icons.camera_alt,
  'book': Icons.book,
  'videogame_asset': Icons.videogame_asset,
  'event': Icons.event,

  // IT/전자기기/기타
  'computer': Icons.computer,
  'phone_iphone': Icons.phone_iphone,
  'watch': Icons.watch,
  'build': Icons.build,
  'work': Icons.work,
  'flight': Icons.flight,
  'emoji_objects': Icons.emoji_objects,
};

IconData getIconData(String iconName) {
  return iconMap[iconName] ?? Icons.category;
} 