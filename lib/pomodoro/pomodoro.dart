import 'package:flutter/material.dart';
import 'dart:async';
import '../task.dart';
import '../settings.dart';
import 'pomodoro_timer.dart';

class PomodoroScreen extends StatefulWidget {
  final Task task;
  final DateTime taskEndTime;

  PomodoroScreen({required this.task, required this.taskEndTime});

  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  late Duration taskTimeLeft;
  final PomodoroTimerManager timerManager = PomodoroTimerManager();

  @override
  void initState() {
    super.initState();

    // Initialize the task timer
    taskTimeLeft = widget.taskEndTime.difference(DateTime.now());
    
    // Initialize the Pomodoro timer if it hasn't been initialized yet
    if (timerManager.timeLeft == Duration.zero) {
      timerManager.initialize(pomodoroWorkDuration, pomodoroBreakDuration);
    }

    // Update the task time left periodically
    Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          taskTimeLeft = widget.taskEndTime.difference(DateTime.now());

          // Automatically close the Pomodoro page when task time is finished
          if (taskTimeLeft.isNegative || taskTimeLeft.inSeconds == 0) {
            Navigator.pop(context);
          }
        });
      }
    });

    // Listen for timer updates from the PomodoroTimerManager
    timerManager.onTimerUpdate = () {
      if (mounted) {
        setState(() {});
      }
    };
  }

  @override
  void dispose() {
    super.dispose();
    // No need to cancel timerManager because it should persist globally
  }

  @override
  Widget build(BuildContext context) {
    final isBreakMode = timerManager.isBreakMode;

    final Duration pomodoroTimeLeft = timerManager.timeLeft;
    final Duration effectiveTimeLeft = isBreakMode
        ? (pomodoroTimeLeft < Duration(minutes: pomodoroBreakDuration)
            ? pomodoroTimeLeft
            : Duration(minutes: pomodoroBreakDuration))
        : (pomodoroTimeLeft < Duration(minutes: pomodoroWorkDuration)
            ? pomodoroTimeLeft
            : Duration(minutes: pomodoroWorkDuration));

    return Scaffold(
      appBar: AppBar(
        title: Text(isBreakMode ? "Break Time" : "Pomodoro"),
        backgroundColor: isBreakMode ? Colors.red : Colors.green,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: isBreakMode ? Colors.red.shade100 : Colors.green.shade100,
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.task.logo,
                  size: 100,
                  color: isBreakMode ? Colors.red : Colors.green,
                ),
                SizedBox(height: 20),
                Text(
                  widget.task.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isBreakMode ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Task Time Left: ${_formatDuration(taskTimeLeft)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                Text( timerManager.isBreakMode ?
                  'Break Mode: ${effectiveTimeLeft.compareTo(taskTimeLeft) < 0 ?_formatDuration(effectiveTimeLeft):_formatDuration(taskTimeLeft)}':
                  'Pomodoro Timer: ${effectiveTimeLeft.compareTo(taskTimeLeft) < 0 ?_formatDuration(effectiveTimeLeft):_formatDuration(taskTimeLeft)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: isBreakMode ? Colors.red.shade900 : Colors.green.shade900,
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBreakMode ? Colors.red : Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () {
                    if (isBreakMode) {
                      // Start work mode immediately
                      timerManager.isBreakMode = false;
                      timerManager.timeLeft = Duration(minutes: pomodoroWorkDuration);
                    } else {
                      // Start break mode immediately
                      timerManager.isBreakMode = true;
                      timerManager.timeLeft = Duration(minutes: pomodoroBreakDuration);
                    }
                    setState(() {});
                  },
                  child: Text(
                    isBreakMode ? 'Start Work' : 'Take a Break',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Back',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}


