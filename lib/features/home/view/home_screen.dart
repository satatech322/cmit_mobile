import 'package:flutter/material.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/features/home/view/custom_drawer.dart';
import 'package:cmit/features/home/view/notification_screen.dart';
import 'package:cmit/features/inquiries/view/inquiries_screen.dart';
import 'package:cmit/features/profile/view/profile_screen.dart';
import 'package:cmit/features/home/widgets/custom_bottom_nav_bar.dart';
import 'package:cmit/core/auth_service.dart';
import 'package:cmit/features/inquiries/view/inquiry_details_screen.dart';
import 'package:cmit/core/inquiry_statistics_service.dart';
import 'package:cmit/features/home/model/inquiry_statistics_model.dart';
import 'package:cmit/core/assign_to_me.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/offline/services/offline_service.dart';
import 'package:cmit/features/offline/view/offline_inquiry_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation State
  int _currentIndex = 0;
  
  // User State
  String _greeting = 'Welcome back';
  String _userName = 'User';
  
  // Dashboard Data State
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  List<AssignToMeModel> inquiries = [];
  List<AssignToMeModel> filteredInquiries = [];
  bool isLoadingInquiries = true;
  String inquiriesError = '';

  int totalInquiries = 0;
  int pendingInquiries = 0;
  int completedInquiries = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _setGreeting();
    _searchController.addListener(_filterInquiries);
    _loadData();
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_filterInquiries);
    _searchController.dispose();
    super.dispose();
  }

  // --- Helper Methods ---

  Future<void> _loadUserInfo() async {
    final name = await AuthService.getCurrentUserName();
    if (mounted) {
      setState(() {
        _userName = name ?? 'User';
      });
    }
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadStatistics(),
      _loadRecentInquiries(),
    ]);
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  Future<void> _loadStatistics() async {
    setState(() => isLoadingStats = true);
    final result = await InquiryStatisticsService.getInquiryStatistics();
    
    if (mounted) {
      if (result['success'] == true) {
        final InquiryStatisticsModel stats = result['data'];
        setState(() {
          totalInquiries = stats.total;
          pendingInquiries = stats.pending;
          completedInquiries = stats.completed;
          isLoadingStats = false;
        });
      } else {
        setState(() {
          totalInquiries = 0;
          pendingInquiries = 0;
          completedInquiries = 0;
          isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadRecentInquiries() async {
    setState(() {
      isLoadingInquiries = true;
      inquiriesError = '';
    });

    try {
      final result = await AssignToMe.getAssignedInquiries().timeout(const Duration(seconds: 10));

      if (mounted) {
        if (result['success'] == true) {
          final allInquiries = result['inquiries'] as List<AssignToMeModel>;
          final recentInquiries = allInquiries.take(4).toList();
          setState(() {
            inquiries = recentInquiries;
            filteredInquiries = List.from(inquiries);
            isLoadingInquiries = false;
          });
        } else {
          setState(() {
            inquiries = [];
            filteredInquiries = [];
            isLoadingInquiries = false;
            inquiriesError = result['message']?.toString() ?? 'Failed to load inquiries';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          inquiries = [];
          filteredInquiries = [];
          isLoadingInquiries = false;
          inquiriesError = 'Unable to load inquiries';
        });
      }
    }
  }

  void _filterInquiries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredInquiries = inquiries.where((inquiry) {
        return inquiry.title.toLowerCase().contains(query) ||
            inquiry.department.toLowerCase().contains(query) ||
            inquiry.initiator.toLowerCase().contains(query) ||
            inquiry.assignedTo.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _navigateToInquiryDetails(AssignToMeModel inquiry) async {
    final hasInternet = await OfflineService.hasInternet();
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => hasInternet
            ? InquiryDetailsScreen(inquiry: inquiry)
            : OfflineInquiryDetailsScreen(inquiry: inquiry),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: CustomDrawer(
        onProfileTap: () => _onTabTapped(2),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  // Custom Header (Visible only on Home Tab)
                  if (_currentIndex == 0) _buildCustomHeader(context),
                  
                  // Main Content
                  Expanded(
                    child: _getPage(_currentIndex),
                  ),
                ],
              );
            }
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildDashboard();
      case 1:
        return const InquiriesScreen();
      case 2:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _onRefresh,
      color: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Stack(
          children: [
             // Transparent Logo Watermark - Right Side
             Positioned(
               right: -20,
               top: 60,
               child: Opacity(
                 opacity: 0.05,
                 child: Image.asset(
                   'assets/images/splash/logo.png',
                   height: 250,
                   width: 250,
                   fit: BoxFit.contain,
                 ),
               ),
             ),
             
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Search Bar
            _buildPremiumSearchBar(),
            
            const SizedBox(height: 24),

            // Statistics Section
            Text(
              "Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // Modern Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    isLoadingStats ? "-" : totalInquiries.toString(),
                    "Total\nInquiries",
                    AppTheme.textPrimary, // Lighter black (0xFF212529)
                    Colors.white,
                    Icons.folder_open_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildSmallStatCard(
                        isLoadingStats ? "-" : pendingInquiries.toString(),
                        "Pending",
                        AppTheme.secondaryColor.withOpacity(0.1),
                        AppTheme.secondaryColor,
                        Icons.access_time_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildSmallStatCard(
                        isLoadingStats ? "-" : completedInquiries.toString(),
                        "Completed",
                        Colors.green.withOpacity(0.1),
                        Colors.green,
                        Icons.check_circle_outline_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Recent Inquiries Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Inquiries",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                TextButton(
                  onPressed: _onRefresh,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Refresh",
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Inquiries List
            _buildInquiriesList(),
            
             // Bottom Padding
            const SizedBox(height: 80),
          ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Menu Button with custom style
              InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Notification Bell
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search inquiries...",
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildStatCard(String count, String label, Color bgColor, Color iconColor, IconData icon) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(0), // Removed padding from container to let Stack fill it
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
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
          // Background Decor
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String count, String label, Color iconBgColor, Color accentColor, IconData icon) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInquiriesList() {
    if (isLoadingInquiries) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }
    if (inquiriesError.isNotEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.grey, size: 40),
            const SizedBox(height: 8),
            Text(inquiriesError, style: const TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: _loadRecentInquiries,
              child: const Text("Retry", style: TextStyle(color: AppTheme.primaryColor)),
            )
          ],
        ),
      );
    }
    if (filteredInquiries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                "No inquiries found",
                style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: filteredInquiries.map((inquiry) => _buildInquiryCard(inquiry)).toList(),
    );
  }

  Widget _buildInquiryCard(AssignToMeModel inquiry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300), // Darker, more visible border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, // Reduced blur
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToInquiryDetails(inquiry),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  child: const Center(
                    child: Icon(
                      Icons.assignment_outlined,
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
                        inquiry.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.business_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              inquiry.department,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade300, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}