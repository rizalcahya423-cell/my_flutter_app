import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ControlProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  ControlProvider() {
    // Keep this node synced to maintain an active connection (reduce delay)
    _dbRef.child("rc_control").keepSynced(true);
  }

  int _f = 0;
  int _b = 0;
  int _l = 0;
  int _r = 0;

  int get f => _f;
  int get b => _b;
  int get l => _l;
  int get r => _r;

  void updateDirection(String direction, bool isPressed) {
    int value = isPressed ? 1 : 0;
    switch (direction) {
      case "F":
        _f = value;
        break;
      case "B":
        _b = value;
        break;
      case "L":
        _l = value;
        break;
      case "R":
        _r = value;
        break;
    }
    notifyListeners();
    _syncWithFirebase();
  }

  void _syncWithFirebase() {
    _dbRef.child("rc_control").update({"F": _f, "B": _b, "L": _l, "R": _r});
  }
}
