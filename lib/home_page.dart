import 'package:flutter/material.dart';
import 'task_manager.dart';
import 'task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'task_widget.dart';
import 'settings.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Task>> futureScheduledTasks;
  late Future<DateTime?> sessionStartTime;
  late Future<DateTime?> sessionEndTime;

  @override
  void initState() {
    super.initState();
    futureScheduledTasks = loadScheduledSession();
    sessionStartTime = getSessionTime('session_start_time');
    sessionEndTime = getSessionTime('session_end_time');
  }

  Future<List<Task>> loadScheduledSession() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('scheduledTasks') ?? '[]'; // Get stored tasks
    final tasksList = json.decode(tasksString) as List; // Decode JSON list

    // Convert JSON objects to Task objects
    return tasksList.map((taskMap) => Task.fromJson(taskMap)).toList();
  }
  // Load session start and end times from SharedPreferences
  Future<DateTime?> getSessionTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(key);
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark_background,
      appBar: AppBar(
        backgroundColor: dark_appbar,
        title: Text(formatDateWithSuffix(DateTime.now()),style: TextStyle(color: green_foreground),),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings,color: white_lower_writings,),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: futureScheduledTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading scheduled tasks'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final tasks = snapshot.data!;

            return FutureBuilder<Map<String, DateTime?>>(
              future: Future.wait([sessionStartTime, sessionEndTime])
                  .then((times) => {'start': times[0], 'end': times[1]}),
              builder: (context, timeSnapshot) {
                if (timeSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final sessionStart = timeSnapshot.data!['start'];
                final sessionEnd = timeSnapshot.data!['end'];

                // Check if sessionStart or sessionEnd is null, if so, don't display the session info
                if (sessionStart == null || sessionEnd == null) {
                  return Center(child: Text('No session available.'));
                }

                // Session exists, display session info
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Session: ${formatTime(sessionStart)} - ${formatTime(sessionEnd)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: white_lower_writings
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final taskStartTime = sessionStart.add(Duration(
                            minutes: tasks.take(index).fold(0, (a, b) => a + b.duration),
                          ));
                          final taskEndTime = taskStartTime.add(Duration(minutes: tasks[index].duration));

                          return TaskWidget(
                            task: tasks[index],
                            startTime: taskStartTime,
                            endTime: taskEndTime,
                            onStatusChanged: () {
                              saveTasks(tasks); // Save updated task list to SharedPreferences
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          } else {
            return Center(child: Text('No tasks scheduled'));
          }
        }
      ),
    // FAB to open Task Manager
    floatingActionButton: Stack(
      children: [
        Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            foregroundColor: white_writings,
            backgroundColor: green_logo,
            onPressed: () async {
              // Fetch the current tasks
              final prefs = await SharedPreferences.getInstance();
              final currentTasksString = prefs.getString('tasks') ?? '[]';
              final currentTasksList = json.decode(currentTasksString) as List;
              final currentTasks =
                  currentTasksList.map((taskMap) => Task.fromJson(taskMap)).toList();

              // Navigate to TaskManagerPage
              final updatedTasks = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskManagerPage(
                    tasks: currentTasks,
                    onTasksUpdated: (newTasks) async {
                      // Save the new session start and end times
                      final prefs = await SharedPreferences.getInstance();

                      // Use the user-selected start and end times from TaskManagerPage
                      final sessionStart = await prefs.getString('session_start_time');
                      final sessionEnd = await prefs.getString('session_end_time');

                      // Update the scheduled session
                      prefs.setString('scheduledTasks',
                          json.encode(newTasks.map((task) => task.toJson()).toList()));

                      // Update the tasks and session times in HomePage
                      setState(() {
                        futureScheduledTasks = Future.value(newTasks);
                        sessionStartTime = Future.value(
                            sessionStart != null ? DateTime.parse(sessionStart) : null);
                        sessionEndTime = Future.value(
                            sessionEnd != null ? DateTime.parse(sessionEnd) : null);
                      });
                    },
                  ),
                ),
              );

              // Refresh session times when returning to HomePage
              if (updatedTasks != null) {
                setState(() {
                  futureScheduledTasks = Future.value(updatedTasks);
                  sessionStartTime = getSessionTime('session_start_time');
                  sessionEndTime = getSessionTime('session_end_time');
                });
              }
            },
            child: Icon(Icons.add),
            tooltip: 'Manage Tasks',
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 33.0, bottom: 0.0), // Add padding
            child: FloatingActionButton(
              foregroundColor: white_writings,
              backgroundColor: const Color.fromARGB(255, 179, 70, 70),
              onPressed: _clearSession,
              child: Icon(Icons.delete),
              tooltip: 'Clear Session',
            ),
          ),
        ),
      ],
    ),
  );
}

  // Clear the current session
void _clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('scheduledTasks');
  await prefs.remove('session_start_time');
  await prefs.remove('session_end_time');

  setState(() {
    futureScheduledTasks = Future.value([]);
    sessionStartTime = Future.value(null);
    sessionEndTime = Future.value(null);
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Session cleared successfully.'),
      duration: Duration(seconds: 2),
    ),
  );
  }

  // Helper to format time for display
  String formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }


  String formatDateWithSuffix(DateTime date) {
    final day = date.day;
    final suffix = (day % 10 == 1 && day != 11)
        ? 'st'
        : (day % 10 == 2 && day != 12)
            ? 'nd'
            : (day % 10 == 3 && day != 13)
                ? 'rd'
                : 'th';
    final dayOfWeek = DateFormat('EEEE').format(date); // e.g., Monday
    final month = DateFormat('MMMM').format(date); // e.g., December
    return '$dayOfWeek, $day$suffix $month';
  }

  void saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert the tasks list to JSON and store it
    final tasksString = json.encode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString('scheduledTasks', tasksString);
  }

}
