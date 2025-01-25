import 'dart:async';

class PomodoroTimerManager {
  static final PomodoroTimerManager _instance = PomodoroTimerManager._internal();

  factory PomodoroTimerManager() => _instance;

  late Duration workDuration;
  late Duration breakDuration;

  late Timer timer;
  Duration timeLeft = Duration.zero;
  bool isBreakMode = false;

  Function()? onTimerUpdate;

  PomodoroTimerManager._internal();

  void initialize(int workMinutes, int breakMinutes) {
    workDuration = Duration(minutes: workMinutes);
    breakDuration = Duration(minutes: breakMinutes);

    if (timeLeft == Duration.zero) {
      timeLeft = workDuration; // Start fresh if no prior state
    }

    _startTimer();
  }

  void _startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      timeLeft -= Duration(seconds: 1);

      if (timeLeft.isNegative) {
        if (isBreakMode) {
          // Switch to work mode
          isBreakMode = false;
          timeLeft = workDuration;
        } else {
          // Switch to break mode
          isBreakMode = true;
          timeLeft = breakDuration;
        }
      }

      // Only trigger the update if there's an onTimerUpdate callback and the widget is still mounted
      if (onTimerUpdate != null) {
        onTimerUpdate!();
      }
    });
  }

  void dispose() {
    timer.cancel();
  }
}
