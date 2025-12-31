import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Import the EditProfileScreen file

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white, // Explicitly set white background for the drawer
      child: Column(
        children: [
          // User Info Section
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(), // Navigate to EditProfileScreen
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white, // Consistent white background
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey, // Fallback background color
                    backgroundImage: AssetImage("assets/images/home/arslan.jpg"), // Only the image
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Arslan Wali",
                    style: TextStyle(
                      color: Colors.black, // Black for contrast on white background
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "arsal@gmail.com",
                    style: TextStyle(
                      color: Colors.black54, // Subtle contrast for secondary text
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: Colors.black87),
                  title: const Text(
                    "Profile",
                    style: TextStyle(color: Colors.black87),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black87, size: 16), // Right arrow icon
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(), // Navigate to EditProfileScreen
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.grey), // Subtle divider
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Log out",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    // TODO: Implement logout logic (e.g., clear auth state, navigate to login screen)
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}