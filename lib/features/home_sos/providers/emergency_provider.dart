import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class EmergencyProvider extends ChangeNotifier {
  bool _isSosActive = false;
  bool _isCountingDown = false;
  int _countdownRemaining = AppConstants.sosCountdownSeconds;
  Timer? _countdownTimer;
  String? _activeEmergencyId;
  DateTime? _emergencyTriggeredTime;

  bool get isSosActive => _isSosActive;
  bool get isCountingDown => _isCountingDown;
  int get countdownRemaining => _countdownRemaining;
  String? get activeEmergencyId => _activeEmergencyId;
  DateTime? get emergencyTriggeredTime => _emergencyTriggeredTime;

  void startSosCountdown({required VoidCallback onSosTriggered}) {
    if (_isSosActive || _isCountingDown) return;

    _isCountingDown = true;
    _countdownRemaining = AppConstants.sosCountdownSeconds;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownRemaining > 1) {
        _countdownRemaining--;
        notifyListeners();
      } else {
        timer.cancel();
        _isCountingDown = false;
        _isSosActive = true;
        _emergencyTriggeredTime = DateTime.now();
        _activeEmergencyId = 'SOS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
        notifyListeners();
        onSosTriggered();
      }
    });
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    _isCountingDown = false;
    _countdownRemaining = AppConstants.sosCountdownSeconds;
    notifyListeners();
  }

  void cancelActiveEmergency() {
    _isSosActive = false;
    _activeEmergencyId = null;
    _emergencyTriggeredTime = null;
    notifyListeners();
  }
}
