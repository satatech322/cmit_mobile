import 'package:flutter/material.dart';
import 'package:cmit/config/routes.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/core/auth_service.dart';
import 'package:cmit/core/local_storage.dart';


class CustomDrawer extends StatefulWidget {
  final VoidCallback onProfileTap;

  const CustomDrawer({
    super.key,
    required this.onProfileTap,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String _userName = 'User';
  String _userRole = 'CMIT User'; // Default role or email placeholder
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await AuthService.getCurrentUserName();
    if (mounted) {
      setState(() {
        _userName = name ?? 'User';
        // In a real app, you might fetch role/email here too
      });
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    try {
      final success = await AuthService.logout();

      if (!mounted) return;

      if (success) {
        await LocalStorage.logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
      } else {
        // Force local logout if server fails
        await LocalStorage.logout();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out locally')),
        );
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      await LocalStorage.logout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out due to an error')),
      );
      Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // User Info Section
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.onProfileTap();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Logo
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "assets/images/splash/logo.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // User Name
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // User Role / Email
                  Text(
                    _userRole,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: "Profile",
                  onTap: () {
                    Navigator.pop(context);
                    widget.onProfileTap();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(color: Colors.grey.shade100, thickness: 1),
                ),
                _isLoggingOut
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: AppTheme.primaryColor),
                        ),
                      )
                    : _buildDrawerItem(
                        icon: Icons.logout_rounded,
                        title: "Log out",
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: _logout,
                      ),
              ],
            ),
          ),
          
          // Version Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Version 1.0.0",
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = AppTheme.textPrimary,
    Color iconColor = AppTheme.textSecondary,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
      onTap: onTap,
    );
  }
}