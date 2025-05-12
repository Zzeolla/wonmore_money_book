import 'package:flutter/cupertino.dart';
import 'package:wonmore_money_book/model/home_screen_tab.dart';

class HomeScreenTabProvider extends ChangeNotifier {
  HomeTab _currentTab = HomeTab.home;
  HomeTab get currentTab => _currentTab;

  void setTab(HomeTab tab) {
    _currentTab = tab;
    notifyListeners();
  }

  void resetToHome() {
    _currentTab = HomeTab.home;
    notifyListeners();
  }
}