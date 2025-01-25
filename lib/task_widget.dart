import 'package:flutter/material.dart';
import 'task.dart';
import 'dart:math';
import 'pomodoro/pomodoro.dart';
import 'settings.dart';

class TaskWidget extends StatefulWidget {
  final Task task;
  final DateTime startTime;
  final DateTime endTime;
  final VoidCallback onStatusChanged; // callback to notify status change

  TaskWidget({
    required this.task,
    required this.startTime,
    required this.endTime,
    required this.onStatusChanged,
  });

  @override
  _TaskWidgetState createState() => _TaskWidgetState();
}

class _TaskWidgetState extends State<TaskWidget> {
  bool isCompleted = false; // For toggling task completion
  bool isCurrentTask = false; // To track if the task is the current task

  @override
  void initState() {
    super.initState();
    _checkIfCurrentTask();
    isCompleted = widget.task.isCompleted;
  }

  void _toggleCompletion(bool? value) async {
  setState(() {
    isCompleted = value ?? false; // Update local state
    widget.task.isCompleted = isCompleted; // Update task object
  });

  widget.onStatusChanged(); // Notify parent to save the updated list
}


  @override
  Widget build(BuildContext context) {
    double height = (widget.task.duration < 15)
        ? 50
        : min(50 + ((widget.task.duration - 15) * 2.0), 50 + ((180 - 15) * 2.0)); // Scaling factor reduced to 2.0

    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        if (now.isAfter(widget.startTime) && now.isBefore(widget.endTime)) {
          Navigator.push(
            context,
            _createPomodoroRoute(context),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            // Time Display Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formatTime(widget.startTime), // Start time
                  style: TextStyle(fontSize: 14, color: white_lower_writings),
                ),
                Text(
                  formatTime(widget.endTime), // End time
                  style: TextStyle(fontSize: 14, color: white_lower_writings),
                ),
              ],
            ),
            SizedBox(width: 10), // Space between time and task card

            // Task Card
            Expanded(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: isCurrentTask ? green_highlight : (isCompleted ? Colors.grey.shade300 : green_foreground),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isCompleted ? green_logo : Colors.green, width: 1.5),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        widget.task.logo,
                        size: 40,
                        color: isCurrentTask ? green_logo_highlight : (isCompleted ? const Color.fromARGB(255, 156, 156, 156) : green_logo),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.task.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                              color: isCompleted ? Colors.grey : Colors.black,
                            ),
                          ),
                          Text(
                            '${widget.task.duration ~/ 60} hrs ${widget.task.duration % 60} mins',
                            style: TextStyle(
                              fontSize: 14,
                              color: isCompleted ? Colors.grey : Colors.black54,
                              decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Completion Check Box
                    Checkbox(
                      focusColor: dark_appbar,
                      activeColor: green_logo,
                      value: isCompleted,
                      onChanged: (value) {
                        _toggleCompletion(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to format time
  String formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Custom route for Pomodoro screen with grow animation
  Route _createPomodoroRoute(BuildContext context) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => PomodoroScreen(
        task: widget.task,
        taskEndTime: widget.endTime,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        return ScaleTransition(
          scale: curve,
          child: child,
        );
      },
    );
  }

  // Check if the current time is within the task's start and end time
  void _checkIfCurrentTask() {
    final now = DateTime.now();
    if (now.isAfter(widget.startTime) && now.isBefore(widget.endTime)) {
      setState(() {
        isCurrentTask = true;
      });
    } else {
      setState(() {
        isCurrentTask = false;
      });
    }
  }
}
