import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme color 
Color dark_background = const Color.fromARGB(255, 32, 32, 32);
Color dark_appbar = const Color.fromARGB(255, 46, 46, 46);

Color green_foreground = Color.fromARGB(255, 153, 214, 177);
Color green_logo = const Color.fromARGB(255, 75, 141, 77);
Color green_mid = const Color.fromARGB(255, 131, 204, 134);
Color green_highlight = const Color.fromARGB(255, 209, 240, 207);
Color green_logo_highlight = const Color.fromARGB(255, 95, 187, 98);

Color white_writings = const Color.fromARGB(255, 235, 235, 235);
Color white_lower_writings = const Color.fromARGB(255, 180, 180, 180);
Color white = Color.fromARGB(255, 245, 245, 245);

// Pomodoro timer
int pomodoroWorkDuration = 25; // Default work time in minutes
int pomodoroBreakDuration = 5; // Default break time in minutes

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('dark_mode') ?? false;
      pomodoroWorkDuration = prefs.getInt('pomodoro_work_duration') ?? 25;
      pomodoroBreakDuration = prefs.getInt('pomodoro_break_duration') ?? 5;
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDarkMode);
    await prefs.setInt('pomodoro_work_duration', pomodoroWorkDuration);
    await prefs.setInt('pomodoro_break_duration', pomodoroBreakDuration);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark_background,
      appBar: AppBar(
        foregroundColor: white_lower_writings,
        title: Text('Settings',style: TextStyle(color: green_foreground)),
        centerTitle: true,
        backgroundColor: dark_appbar,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Dark/Light Mode Toggle
            SwitchListTile(
              hoverColor: dark_appbar,
              activeColor: green_logo,
              thumbColor: WidgetStateProperty.all(white_writings),
              title: Text('Dark Mode',style: TextStyle(color: white_writings),),
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
                saveSettings();
              },
            ),
            SizedBox(height: 20),

            // Pomodoro Working Time Duration
            ListTile(
              hoverColor: dark_appbar,
              title: Text('Pomodoro Work Duration',style: TextStyle(color: white_writings),),
              subtitle: Text('${pomodoroWorkDuration ~/ 60} hrs ${pomodoroWorkDuration % 60} mins',style: TextStyle(color: white_lower_writings)),
              trailing: Icon(Icons.edit,color: white_lower_writings,),
              onTap: () async {
                final newDuration = await showTimePickerModal(
                  context,
                  initialDuration: pomodoroWorkDuration,
                );
                if (newDuration != null) {
                  setState(() {
                    pomodoroWorkDuration = newDuration;
                  });
                  saveSettings();
                }
              },
            ),
            SizedBox(height: 10),

            // Pomodoro Break Time Duration
            ListTile(
              hoverColor: dark_appbar,
              title: Text('Pomodoro Break Duration',style: TextStyle(color: white_writings)),
              subtitle: Text('${pomodoroBreakDuration ~/ 60} hrs ${pomodoroBreakDuration % 60} mins',style: TextStyle(color: white_lower_writings)),
              trailing: Icon(Icons.edit,color: white_lower_writings,),
              onTap: () async {
                final newDuration = await showTimePickerModal(
                  context,
                  initialDuration: pomodoroBreakDuration,
                );
                if (newDuration != null) {
                  setState(() {
                    pomodoroBreakDuration = newDuration;
                  });
                  saveSettings();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show Time Picker Modal
  Future<int?> showTimePickerModal(BuildContext context, {required int initialDuration}) {
    int selectedHours = initialDuration ~/ 60;
    int selectedMinutes = initialDuration % 60;

    return showModalBottomSheet<int>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: Column(
            children: [
              // Picker Header
              Container(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Duration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              // Pickers for Hours and Minutes
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hour Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: selectedHours),
                        itemExtent: 40,
                        onSelectedItemChanged: (int index) {
                          selectedHours = index;
                        },
                        children: List<Widget>.generate(24, (int index) {
                          return Center(child: Text('$index hrs'));
                        }),
                      ),
                    ),

                    // Minute Picker
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(initialItem: selectedMinutes),
                        itemExtent: 40,
                        onSelectedItemChanged: (int index) {
                          selectedMinutes = index;
                        },
                        children: List<Widget>.generate(60, (int index) {
                          return Center(child: Text('$index mins'));
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Cancel action
                      },
                      child: Text('Cancel', style: TextStyle(fontSize: 16)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, selectedHours * 60 + selectedMinutes);
                      },
                      child: Text('Save', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
