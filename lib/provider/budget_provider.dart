import 'package:flutter/material.dart';

class BudgetGroup {
  final String id;
  final String name;
  final bool isOwner;

  BudgetGroup({required this.id, required this.name, required this.isOwner});
}

class BudgetProvider extends ChangeNotifier {
  List<BudgetGroup> _myBudgetGroups = [];
  BudgetGroup? _selectedBudget;

  List<BudgetGroup> get myBudgetGroups => _myBudgetGroups;
  BudgetGroup? get selectedBudget => _selectedBudget;

  void setBudgetGroups(List<BudgetGroup> groups) {
    _myBudgetGroups = groups;
    if (_selectedBudget == null && groups.isNotEmpty) {
      _selectedBudget = groups.first;
    }
    notifyListeners();
  }

  void selectBudget(BudgetGroup group) {
    _selectedBudget = group;
    notifyListeners();
  }
}
