import 'package:flutter/material.dart';

class Task {
  String name;
  int duration; // in minutes
  IconData logo; // Change type to IconData
  int priority; // in charge of probability
  bool isCurrentTask; // This flag will be used to highlight the current task
  bool isCompleted; // New field to track task completion

  Task({
    required this.name,
    required this.duration,
    required this.logo, // IconData instead of String
    required this.priority,
    this.isCurrentTask = false, // Default value is false
    this.isCompleted = false, // Default to not completed
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'duration': duration,
        'logo': logo.codePoint, // Save as integer codePoint
        'priority': priority,
        'isCompleted': isCompleted, // Save the completion status
      };

  static Task fromJson(Map<String, dynamic> json) => Task(
        name: json['name'],
        duration: json['duration'],
        logo: IconData(json['logo'], fontFamily: 'MaterialIcons'), // Restore as IconData
        priority: json['priority'],
        isCompleted: json['isCompleted'] ?? false, // Load completion status
      );
}
