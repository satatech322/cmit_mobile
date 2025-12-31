import 'package:flutter/material.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/config/routes.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/core/local_storage.dart';
import 'package:cmit/core/auth_service.dart';
import 'package:cmit/core/profile_service.dart';
import 'package:cmit/features/profile/model/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileModel? _profile;
  ImageProvider? _profileImage;

  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);

    final result = await ProfileService.getProfileData();

    print("Profile fetch result: $result");

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _profile = result['data'] as ProfileModel;

        print("Profile loaded - Name: ${_profile!.name}, Email: ${_profile!.email}, CNIC: ${_profile!.cnicNumber}, Phone: ${_profile!.cellNumber}");

        // Load profile picture if exists
        final picPath = _profile!.profilePicture;
        if (picPath != null && picPath.trim().isNotEmpty) {
          final cleanedPath = picPath.replaceAll('\\', '/');
          print("Loading profile picture from: ${ApiConfig.assetBaseUrl}/$cleanedPath");
          _profileImage = NetworkImage('${ApiConfig.assetBaseUrl}/$cleanedPath');
        } else {
          print("No profile picture available");
        }
      });
    } else {
      print("Failed to load profile: ${result['message']}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to load profile')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _onRefresh() async {
    await _fetchProfileData();
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _profile == null
          ? _buildErrorState()
          : SafeArea(
        child: Column(
          children: [
            // Custom Header matching Home Screen
            _buildCustomHeader(context),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.primaryColor,
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Profile Card
                      _buildProfileCard(),

                      const SizedBox(height: 30),

                      // Personal Information Section Header
                      const Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Information Cards
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: "Email Address",
                        value: _profile!.email,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.credit_card_outlined,
                        title: "CNIC Number",
                        value: _profile!.cnicNumber,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        icon: Icons.phone_outlined,
                        title: "Phone Number",
                        value: _profile!.cellNumber,
                      ),

                      const SizedBox(height: 30),

                      // Logout Button
                      _buildLogoutButton(),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      child: const Center(
        child: Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF014323), Color(0xFF0F5132)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF014323).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Transparent Logo Watermark overlay
          Positioned(
            right: -12,
            top: 0,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/splash/logo.png',
                height: 180,
                width: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Profile content
          Column(
            children: [
              // Profile Picture
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _profileImage != null
                    ? CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _profileImage,
                  onBackgroundImageError: (_, __) {
                    if (mounted) setState(() => _profileImage = null);
                  },
                )
                    : CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                _profile!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Team Member",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF014323), Color(0xFF0F5132)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    if (_isLoggingOut) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          "Logout",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "Failed to load profile",
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchProfileData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}