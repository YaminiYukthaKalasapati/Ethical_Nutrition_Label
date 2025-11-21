import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Ethical Nutrition Label';
  static const String appVersion = 'Beta 1.0.0';

  // Database Tables
  static const String dataTableName = 'dnl_experiment_data';

  // Device Models
  static const List<String> deviceModels = [
    "iPhone 13",
    "iPhone 14",
    "iPhone 15",
    "Pixel 7",
    "Pixel 8",
    "Samsung S22",
    "Samsung S23",
    "Macbook Pro",
    "Dell XPS",
    "Not Listed",
  ];

  // Apps
  static const List<String> appOptions = [
    "Headspace",
    "Calm",
    "Woebot",
    "Moodnotes",
    "Sanvello",
    "Talkspace",
    "BetterHelp",
    "Other",
  ];

  // Data Categories
  static const List<String> dataLinkedOptions = [
    "Usage Data",
    "Purchases",
    "Identifiers",
    "Location",
    "Contact Info",
    "User Id",
    "Health Data",
    "Financial Info",
  ];

  static const List<String> dataNotLinkedOptions = [
    "Diagnostics",
    "Contact Info",
    "Usage Data",
    "Crash Data",
    "Performance Data",
    "Other",
  ];

  static const List<String> dataTrackedOptions = [
    "Purchases",
    "Identifiers",
    "Usage Data",
    "Location",
    "Contact Info",
    "Other",
  ];

  // Permissions
  static const List<String> permissionsOptions = [
    "Location",
    "Camera",
    "Microphone",
    "Contacts",
    "Storage",
    "Calendar",
    "Files",
    "Photos",
    "Videos",
    "Notifications",
    "Health",
    "Financial",
    "User Id",
    "Bluetooth",
    "Motion & Fitness",
  ];

  // Validation
  static const int minPasswordLength = 6;
  static const int maxObservationLength = 1000;

  // UI
  static const double maxContentWidth = 600.0;
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets largePadding = EdgeInsets.all(32.0);

  // Colors
  static const Color primaryColor = Colors.teal;
  static final Color primaryLightColor = Colors.teal.shade50;
  static final Color primaryDarkColor = Colors.teal.shade900;
}
