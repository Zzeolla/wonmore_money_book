import 'package:flutter/cupertino.dart';
import 'package:wonmore_money_book/model/home_screen_tab.dart';

class HomeScreenTabProvider extends ChangeNotifier {
  HomeTab _currentTab = HomeTab.home;
  HomeTab get currentTab => _currentTab;
  bool _isMainScreen = true;
  bool get isMainScreen => _isMainScreen;

  void setTab(HomeTab tab) {
    _currentTab = tab;
    _isMainScreen = false;
    notifyListeners();
  }

  void resetToHome() {
    _currentTab = HomeTab.home;
    _isMainScreen = true;
    notifyListeners();
  }
}