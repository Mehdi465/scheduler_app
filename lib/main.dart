import 'package:flutter/material.dart';
import 'home_page.dart'; // Import the HomePage file

void main() {
  runApp(DailyPlannerApp());
}

class DailyPlannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      title: 'Daily Planner',
      theme: ThemeData(
        primarySwatch: Colors.green, // Set the primary color theme
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(), // Set HomePage as the default screen
    );
  }
}
