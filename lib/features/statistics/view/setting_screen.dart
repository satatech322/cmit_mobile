import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/core/widgets/app_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _enableReminders = false;
  Map<String, bool> _reminderTypes = {
    'Workout Session': true,
    'Stretching': false,
    'Track Run': true,
    'Recovery Rest': false,
    'Nutrition Log': true,
  };
  TimeOfDay _notificationTime = TimeOfDay.now();
  bool _darkMode = false;
  String _language = 'English';
  bool _imperialUnits = false;
  bool _workoutGoalTracking = true;
  String _performanceMetric = 'Pace';
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  // Show time picker dialog
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  // Handle Change Password
  void _changePassword() {
    if (_newPasswordController.text == _confirmPasswordController.text) {
      // Implement password change logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
    }
  }

  // Handle Delete Account
  void _deleteAccount() {
    AppDialog.show(
      context: context,
      icon: Icons.delete_forever_rounded,
      iconColor: AppTheme.errorColor,
      title: 'Delete Account',
      message: 'Are you sure you want to delete your account? This action cannot be undone.',
      confirmText: 'Delete',
      confirmButtonColor: AppTheme.errorColor,
      cancelText: 'Cancel',
      isDestructive: true,
      onConfirm: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.teal[400]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Customize Your TrackTribe Experience",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 20),
            _buildNotificationPreferences(),
            const SizedBox(height: 20),
            _buildAppPreferences(),
            const SizedBox(height: 20),
            _buildAccountManagement(),
            const SizedBox(height: 20),
            _buildTrainingResources(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreferences() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Notification Preferences",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal[400],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Enable Reminders",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[900],
                  ),
                ),
                Switch(
                  value: _enableReminders,
                  onChanged: (value) {
                    setState(() {
                      _enableReminders = value;
                    });
                  },
                  activeColor: Colors.teal[400],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Reminder Types",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            ..._reminderTypes.keys.map((type) {
              return CheckboxListTile(
                title: Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[900],
                  ),
                ),
                value: _reminderTypes[type],
                onChanged: _enableReminders
                    ? (bool? value) {
                  setState(() {
                    _reminderTypes[type] = value ?? false;
                  });
                }
                    : null,
                activeColor: Colors.teal[400],
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
            const SizedBox(height: 16),
            Text(
              "Preferred Notification Time",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _enableReminders ? () => _selectTime(context) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _notificationTime.format(context),
                      style: TextStyle(
                        fontSize: 14,
                        color: _enableReminders ? Colors.grey[900] : Colors.grey[400],
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      color: _enableReminders ? Colors.teal[400] : Colors.grey[400],
                      size: 20,
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

  Widget _buildAppPreferences() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "App Preferences",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal[400],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Workout Goal Tracking",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[900],
                  ),
                ),
                Switch(
                  value: _workoutGoalTracking,
                  onChanged: (value) {
                    setState(() {
                      _workoutGoalTracking = value;
                    });
                  },
                  activeColor: Colors.teal[400],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Performance Metric",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _performanceMetric,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal[400]!),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              items: ['Pace', 'Distance', 'Calories', 'Heart Rate'].map((String metric) {
                return DropdownMenuItem<String>(
                  value: metric,
                  child: Text(metric),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _performanceMetric = newValue ?? 'Pace';
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Imperial Units (lb, ft/in)",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[900],
                  ),
                ),
                Switch(
                  value: _imperialUnits,
                  onChanged: (value) {
                    setState(() {
                      _imperialUnits = value;
                    });
                  },
                  activeColor: Colors.teal[400],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Language",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _language,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal[400]!),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              items: ['English', 'Spanish', 'French'].map((String language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _language = newValue ?? 'English';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountManagement() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Account Management",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal[400],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Athlete Profile',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[900],
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              onTap: () {
                // Navigate to athlete profile page
              },
            ),
            const SizedBox(height: 16),
            Text(
              "Change Password",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal[400]!),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.teal[400]!),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Center(
                child: Text(
                  'Change Password',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Center(
                child: Text(
                  'Delete Account',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingResources() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Training Resources",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal[400],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Workout Guides',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[900],
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              onTap: () {
                // Navigate to workout guides page
              },
            ),
            ListTile(
              title: Text(
                'Coaching Support',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[900],
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              onTap: () {
                // Navigate to coaching support page
              },
            ),
            ListTile(
              title: Text(
                'FAQs',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[900],
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              onTap: () {
                // Navigate to FAQs page
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}