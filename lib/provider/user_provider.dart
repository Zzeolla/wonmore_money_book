import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _justSignedIn = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get justSignedIn => _justSignedIn;

  set justSignedIn(bool value) {
    _justSignedIn = value;
    notifyListeners();
  }

  UserProvider() {
    _currentUser = Supabase.instance.client.auth.currentUser;
    //
    // Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    //   final session = data.session;
    //   final event = data.event;
    //
    //   _currentUser = session?.user;
    //
    //   if (event == AuthChangeEvent.signedIn && _currentUser != null) {
    //     _justSignedIn = true;
    //
    //     final userId = _currentUser!.id;
    //     final exists = await _checkUserExists(userId);
    //
    //     if (!exists) {
    //       await _createUser(_currentUser!);
    //     }
    //   }
    notifyListeners();
    // });
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
}