import 'package:flutter/material.dart';
import 'task.dart'; // Import the updated Task class
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'settings.dart';

Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('tasks') ?? '[]';
    final tasksList = json.decode(tasksString) as List;

    return tasksList.map((taskMap) => Task.fromJson(taskMap)).toList();
}

class TaskManagerPage extends StatefulWidget {
  final List<Task> tasks; // Shared tasks list passed from SchedulerHomePage
  final ValueChanged<List<Task>> onTasksUpdated; // Callback to update shared list

  TaskManagerPage({required this.tasks, required this.onTasksUpdated});

  @override
  _TaskManagerPageState createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends State<TaskManagerPage> {
  late List<Task> tasks;

  @override
  void initState() {
    super.initState();
    tasks = widget.tasks; // Use the shared tasks list
  }

    // Function to schedule tasks based on the priority algorithm
 List<Task> scheduleTasksInTimeRange(int startMinutes, int endMinutes) {
  // Separate tasks by priority
  List<Task> mandatoryTasks = tasks.where((task) => task.priority == 1).toList();
  List<Task> highPriorityTasks = tasks.where((task) => task.priority == 2).toList();
  List<Task> mediumPriorityTasks = tasks.where((task) => task.priority == 3).toList();
  List<Task> lowPriorityTasks= tasks.where((task) => task.priority == 4).toList();

  // Shuffle each list randomly
  mandatoryTasks.shuffle();
  lowPriorityTasks.shuffle();
  mediumPriorityTasks.shuffle();
  highPriorityTasks.shuffle();

  // Start building the schedule
  List<Task> scheduledTasks = [];
  int currentTime = startMinutes;

  // Schedule mandatory tasks first
  for (Task task in mandatoryTasks) {
    int taskDuration = task.duration;

    // Adjust task duration if it exceeds remaining time in the range
    if (currentTime + taskDuration > endMinutes) {
      taskDuration = endMinutes - currentTime;
    }

    // Clone the task with adjusted duration for this session
    Task scheduledTask = Task(
      name: task.name,
      duration: taskDuration,
      logo: task.logo,
      priority: task.priority,
    );

    scheduledTasks.add(scheduledTask);

    // Update the current session time
    currentTime += taskDuration;

    // Break out if the time range is fully occupied
    if (currentTime >= endMinutes) break;
  }

  // If the time range is already filled, return the mandatory tasks
  if (currentTime >= endMinutes) {
    scheduledTasks.shuffle(); // Shuffle to randomize order
    return scheduledTasks;
  }

  // Create a combined pool for low, medium, and high priorities
  Random random = Random();

  while (currentTime < endMinutes) {
    int randomNumber = random.nextInt(6) + 1; // Random number between 1 and 6
    Task? selectedTask;

    if (randomNumber == 1 && lowPriorityTasks.isNotEmpty) {
      // Select from low priority
      selectedTask = lowPriorityTasks[random.nextInt(lowPriorityTasks.length)];
    } else if ((randomNumber == 2 || randomNumber == 3) && mediumPriorityTasks.isNotEmpty) {
      // Select from medium priority
      selectedTask = mediumPriorityTasks[random.nextInt(mediumPriorityTasks.length)];
    } else if ((randomNumber == 4 || randomNumber == 5 || randomNumber == 6) && highPriorityTasks.isNotEmpty) {
      // Select from high priority
      selectedTask = highPriorityTasks[random.nextInt(highPriorityTasks.length)];
    }

    // Add the selected task to the schedule if one was picked
    if (selectedTask != null) {
      int taskDuration = selectedTask.duration;

      // Adjust task duration if it exceeds remaining time in the range
      if (currentTime + taskDuration > endMinutes) {
        taskDuration = endMinutes - currentTime;
      }

      // Clone the task with adjusted duration for this session
      Task scheduledTask = Task(
        name: selectedTask.name,
        duration: taskDuration,
        logo: selectedTask.logo,
        priority: selectedTask.priority,
      );

      scheduledTasks.add(scheduledTask);

      // Update the current session time
      currentTime += taskDuration;
    }
  }

  // Shuffle the final list of scheduled tasks
  scheduledTasks.shuffle();

  return scheduledTasks;
}


  // Helper function to add tasks based on weighted probability
  List<Task> getPriorityTasks(List<Task> tasks, int chanceMultiplier) {
    List<Task> selectedTasks = [];
    for (var task in tasks) {
      // The weight of a task is defined by its chanceMultiplier
      int weight = chanceMultiplier;
      for (int i = 0; i < weight; i++) {
        selectedTasks.add(task);  // Add task multiple times based on its priority multiplier
      }
    }
    return selectedTasks;
  }

  // Load tasks from shared_preferences
  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString('tasks') ?? '[]';
    final tasksList = json.decode(tasksString) as List;
    setState(() {
      tasks = tasksList.map((taskMap) => Task.fromJson(taskMap)).toList();
    });
  }

  // Save tasks to shared_preferences
  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = json.encode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', tasksString);
  }

void showAddTaskDialog() {
  String name = '';
  int duration = 0; // Total duration in minutes
  IconData? logo = Icons.star; // Default logo
  int priority = 2;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: dark_appbar,
            title: Text('Add Task',style: TextStyle(color: white_writings),),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    cursorColor: white_lower_writings,
                    style: TextStyle(color: white_lower_writings),
                    decoration: InputDecoration(labelText: 'Task Name',labelStyle: TextStyle(color: white_lower_writings)),
                    onChanged: (value) => name = value,
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final time = await showCustomTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: 0, minute: 0),
                      );
                      if (time != null) {
                        setDialogState(() {
                          duration = (time.hour * 60) + time.minute;
                        });
                      }
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        duration == 0
                            ? 'Select Duration'
                            : '${duration ~/ 60} hrs ${duration % 60} mins',
                        style: TextStyle(color:white_lower_writings),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<IconData>(
                    dropdownColor: dark_appbar,
                    decoration: InputDecoration(labelText: 'Select Logo',labelStyle: TextStyle(color: white_lower_writings)),
                    value: logo,
                    items: [
                      DropdownMenuItem(value: Icons.book, child: Row(children: [Icon(Icons.book,color: green_foreground), SizedBox(width: 10), Text('Books',style: TextStyle(color: white_lower_writings),)])),
                      DropdownMenuItem(value: Icons.sports, child: Row(children: [Icon(Icons.sports,color: green_foreground), SizedBox(width: 10), Text('Sports',style: TextStyle(color: white_lower_writings))])),
                      DropdownMenuItem(value: Icons.shopping_cart, child: Row(children: [Icon(Icons.shopping_cart,color: green_foreground), SizedBox(width: 10), Text('Shopping Cart',style: TextStyle(color: white_lower_writings))])),
                      DropdownMenuItem(value: Icons.nature, child: Row(children: [Icon(Icons.nature,color: green_foreground), SizedBox(width: 10), Text('Plant',style: TextStyle(color: white_lower_writings))])),
                      DropdownMenuItem(value: Icons.bedtime, child: Row(children: [Icon(Icons.bedtime,color: green_foreground), SizedBox(width: 10), Text('Sleep',style: TextStyle(color: white_lower_writings))])),
                      DropdownMenuItem(value: Icons.star, child: Row(children: [Icon(Icons.star,color: green_foreground), SizedBox(width: 10), Text('Star',style: TextStyle(color: white_lower_writings))])),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        logo = value;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    dropdownColor: dark_appbar,
                    decoration: InputDecoration(labelText: 'Priority',labelStyle: TextStyle(color: white_lower_writings)),
                    value: priority,
                    items: [
                      DropdownMenuItem(value: 1, child: Text('Mandatory',style: TextStyle(color: green_foreground),)),
                      DropdownMenuItem(value: 2, child: Text('High',style: TextStyle(color: green_foreground),)),
                      DropdownMenuItem(value: 3, child: Text('Medium',style: TextStyle(color: green_foreground),)),
                      DropdownMenuItem(value: 4, child: Text('Low',style: TextStyle(color: green_foreground),)),
                    ],
                    onChanged: (value) => priority = value ?? 1,
                  ),
                  
                ],
              ),
            ),
            actions: [
              TextButton(
                style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(green_logo), // Green background
                foregroundColor: WidgetStateProperty.all(white_writings), // White text
                overlayColor: WidgetStateProperty.all(Colors.red),
              ),
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(green_logo), // Green background
                foregroundColor: WidgetStateProperty.all(white_writings), // White text
                overlayColor: WidgetStateProperty.all(green_foreground),
              ),
                onPressed: () {
                  if (name.isNotEmpty && duration > 0) {
                    setState(() {
                      tasks.add(Task(
                        name: name,
                        duration: duration,
                        logo: logo ?? Icons.star,
                        priority: priority,
                      ));
                    });
                    saveTasks();
                    Navigator.pop(context);
                  }
                },
                child: Text('Add'),
              ),
            ],
          );
        },
      );
    },
  );
}

  /**
   * 
   *  Delete by swiping to right
   * 
   */

  Future<bool?> showDeleteConfirmationDialog(int index) async {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                tasks.removeAt(index);
              });
              saveTasks();
              Navigator.pop(context, true);
            },
            child: Text('Delete'),
          ),
        ],
      );
    },
  );
}


  /**
   * 
   *  Modify by swiping to left
   * 
   */
void showModifyTaskDialog(int index) {
  Task existingTask = tasks[index];
  String name = existingTask.name;
  int duration = existingTask.duration;
  IconData logo = existingTask.logo;
  int priority = existingTask.priority;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Modify Task'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Task Name'),
                    controller: TextEditingController(text: name),
                    onChanged: (value) => name = value,
                  ),
                  GestureDetector(
                    onTap: () async {
                      final time = await showCustomTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: duration ~/ 60,
                          minute: duration % 60,
                        ),
                      );
                      if (time != null) {
                        setDialogState(() {
                          duration = (time.hour * 60) + time.minute;
                        });
                      }
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        duration == 0
                            ? 'Select Duration'
                            : '${duration ~/ 60} hrs ${duration % 60} mins',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<IconData>(
                    decoration: InputDecoration(labelText: 'Select Logo'),
                    value: logo, // Set the initial value to the current logo
                    items: [
                      DropdownMenuItem(
                        value: Icons.book,
                        child: Row(
                          children: [Icon(Icons.book), SizedBox(width: 10), Text('Books')],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Icons.sports,
                        child: Row(
                          children: [Icon(Icons.sports), SizedBox(width: 10), Text('Sports')],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Icons.shopping_cart,
                        child: Row(
                          children: [Icon(Icons.shopping_cart), SizedBox(width: 10), Text('Shopping Cart')],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Icons.nature,
                        child: Row(
                          children: [Icon(Icons.nature), SizedBox(width: 10), Text('Plant')],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Icons.bedtime,
                        child: Row(
                          children: [Icon(Icons.bedtime), SizedBox(width: 10), Text('Sleep')],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Icons.star,
                        child: Row(
                          children: [Icon(Icons.star), SizedBox(width: 10), Text('Star')],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        logo = value ?? Icons.star;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(labelText: 'Priority'),
                    value: priority,
                    items: [
                      DropdownMenuItem(value: 1, child: Text('Mandatory')),
                      DropdownMenuItem(value: 2, child: Text('High')),
                      DropdownMenuItem(value: 3, child: Text('Medium')),
                      DropdownMenuItem(value: 4, child: Text('Low')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        priority = value ?? 1;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (name.isNotEmpty && duration > 0) {
                    setState(() {
                      tasks[index] = Task(
                        name: name,
                        duration: duration,
                        logo: logo,
                        priority: priority,
                      );
                    });
                    saveTasks();
                    Navigator.pop(context);
                  }
                },
                child: Text('Save Changes'),
              ),
            ],
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark_background,
      appBar: AppBar(
        backgroundColor: dark_appbar,
        foregroundColor: white_lower_writings,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Task Manager',
          style: TextStyle(fontSize: 20,color: green_foreground),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(green_logo), // Green background
                foregroundColor: WidgetStateProperty.all(white_writings), // White text
              ),
              onPressed: showAddTaskDialog,
              child: Text('Add Task'),
            ),

          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), // Small padding between tiles
                  child: Dismissible(
                    key: Key(task.name + index.toString()), // Unique key for each item
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Modify', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        // Modify Task
                        showModifyTaskDialog(index);
                        return false; // Prevent Dismissal
                      } else if (direction == DismissDirection.endToStart) {
                        // Delete Task
                        return await showDeleteConfirmationDialog(index);
                      }
                      return false;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: dark_appbar, // Tile background color
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                      child: ListTile(
                        title: Text(
                          task.name,
                          style: TextStyle(color: white_writings),
                        ),
                        subtitle: Text(
                          'Duration: ${(task.duration / 60).toInt()}h${task.duration % 60}min '
                          'Priority: ${['Mandatory', 'High', 'Medium', 'Low'][task.priority - 1]}, ',
                          style: TextStyle(color: white_lower_writings),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: green_foreground,
                          child: Icon(task.logo, color: green_logo),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: green_logo,
        foregroundColor: white_writings,
        onPressed: () async {
          // Fetch the last session duration (in minutes) from SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final lastDuration = prefs.getInt('lastSessionDuration') ?? 120; // Default to 2 hours if not found

          showDialog(
            context: context,
            builder: (context) {
              TimeOfDay? startTime;
              TimeOfDay? endTime;

              // Round the current time to the nearest 5 minutes
              DateTime now = DateTime.now();
              int minutes = now.minute;
              int remainder = minutes % 5;
              int roundedMinutes = minutes + (remainder == 0 ? 0 : 5 - remainder);
              startTime = TimeOfDay(hour: now.hour, minute: roundedMinutes);

              // Calculate end time based on the last session duration
              DateTime endDateTime = now.add(Duration(minutes: lastDuration));
              endTime = TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);

              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    backgroundColor: dark_appbar,
                    title: Text('Set Session Time',style: TextStyle(color: green_foreground),),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text('Start Time: ${startTime != null ? startTime?.format(context) : 'Not set'}',style: TextStyle(color: white_lower_writings)),
                          trailing: IconButton(
                            icon: Icon(Icons.access_time,color: green_foreground),
                            onPressed: () async {
                              TimeOfDay? picked = await showCustomTimePicker(context: context, initialTime: startTime!);
                              if (picked != null) {
                                setState(() {
                                  startTime = picked;
                                });
                              }
                            },
                          ),
                        ),
                        ListTile(
                          title: Text('End Time: ${endTime != null ? endTime?.format(context) : 'Not set'}',style: TextStyle(color: white_lower_writings)),
                          trailing: IconButton(
                            icon: Icon(Icons.access_time,color: green_foreground,),
                            onPressed: () async {
                              TimeOfDay? picked = await showCustomTimePicker(context: context, initialTime: startTime!);
                              if (picked != null) {
                                setState(() {
                                  endTime = picked;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(green_logo), // Green background
                          foregroundColor: WidgetStateProperty.all(white_writings), // White text
                          overlayColor: WidgetStateProperty.all(Colors.red)
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(green_logo), // Green background
                          foregroundColor: WidgetStateProperty.all(white_writings),
                          overlayColor: WidgetStateProperty.all(const Color.fromARGB(255, 75, 209, 80)) // White text
                        ),
                        onPressed: () async {
                          if (startTime != null && endTime != null) {
                            // Convert TimeOfDay to minutes since midnight
                            int startMinutes = startTime!.hour * 60 + startTime!.minute;
                            int endMinutes = endTime!.hour * 60 + endTime!.minute;

                            // Handle case where endTime is smaller than startTime (crosses midnight)
                            if (endMinutes <= startMinutes) {
                              endMinutes += 24 * 60; // Add 24 hours to the end timeR
                            }

                            // Schedule tasks within the given time range
                            List<Task> scheduledTasks = scheduleTasksInTimeRange(startMinutes, endMinutes);

                            // Save session start and end times
                            final prefs = await SharedPreferences.getInstance();
                            final now = DateTime.now();
                            final sessionStart = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              startTime!.hour,
                              startTime!.minute,
                            );
                            final sessionEnd = sessionStart.add(Duration(minutes: endMinutes - startMinutes));

                            await prefs.setString('session_start_time', sessionStart.toIso8601String());
                            await prefs.setString('session_end_time', sessionEnd.toIso8601String());

                            // Pass the scheduled tasks back to the home page
                            widget.onTasksUpdated(scheduledTasks);

                            // Close the dialog and notify HomePage
                            Navigator.pop(context, true); // Close dialog and return a signal
                            Navigator.pop(context);
                          }
                        },
                        child: Text('Schedule It'),
                      ),

                    ],
                  );
                },
              );
            },
          );
        },
        child: Icon(Icons.schedule),
        tooltip: 'Schedule Tasks',
      ),

    );
  }
    // Save the scheduled tasks to SharedPreferences
  Future<void> saveScheduledTasks(List<Task> scheduledTasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = json.encode(scheduledTasks.map((task) => task.toJson()).toList());
    await prefs.setString('scheduled_tasks', tasksString);
  }


  Future<TimeOfDay?> showCustomTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    }) {
    return showTimePicker(
      barrierColor: dark_appbar, // Background overlay outside the picker
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            timePickerTheme: TimePickerThemeData(
              cancelButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(white_writings),
                overlayColor: WidgetStateProperty.all(Colors.red),
              ),
              confirmButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(white_writings),
                overlayColor: WidgetStateProperty.all(green_logo),
              ),
              hourMinuteColor: green_logo,
              backgroundColor: dark_appbar, // Dark background for the picker
              dialBackgroundColor: dark_background, // Background for the dial
              dialTextColor: white_writings, // Color of the dial numbers
              dialHandColor: green_logo,
              hourMinuteTextColor: white_writings, // Color of the selected hour/minute
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: white_lower_writings, width: 2),
              ),
              entryModeIconColor: white_lower_writings, // Color of the toggle button icon
              dayPeriodTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? dark_background
                    : white_writings,
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

}

