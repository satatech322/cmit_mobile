// lib/features/offline/view/offline_inquiry_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/offline/services/offline_service.dart';
import 'package:cmit/features/offline/view/offline_visit_findings_screen.dart';
import 'package:cmit/core/auth_service.dart';

// Import section widgets (reuse from main inquiry details)
import 'package:cmit/features/inquiries/view/sections/inquiry_details_section.dart';
import 'package:cmit/features/inquiries/view/sections/inquiry_visits_section.dart';

class OfflineInquiryDetailsScreen extends StatefulWidget {
  final AssignToMeModel inquiry;

  const OfflineInquiryDetailsScreen({
    super.key,
    required this.inquiry,
  });

  @override
  State<OfflineInquiryDetailsScreen> createState() => _OfflineInquiryDetailsScreenState();
}

class _OfflineInquiryDetailsScreenState extends State<OfflineInquiryDetailsScreen> {
  late List<dynamic> allVisits = [];
  bool _isOnline = true;
  String? _currentUserId;

  AssignToMeModel get i => widget.inquiry;

  @override
  void initState() {
    super.initState();
    allVisits = i.visits;
    _checkConnectivity();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await AuthService.getCurrentUserId();
    if (mounted) {
      setState(() => _currentUserId = userId);
    }
  }

  Future<void> _checkConnectivity() async {
    final hasInternet = await OfflineService.hasInternet();
    if (mounted) {
      setState(() => _isOnline = hasInternet);
    }
  }

  void _showOfflineMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is not available in offline mode'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToOfflineVisitFindings(Map<String, dynamic> visit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfflineVisitFindingsScreen(
          visit: visit,
          inquiryId: i.id.toString(),
        ),
      ),
    );
  }
  
  // Navigation Callbacks (Read-Only / Offline handled)

  void _onNavigateToFindings(Map<String, dynamic> visit) {
     _navigateToOfflineVisitFindings(visit);
  }
  
  void _onEditFinding(Map<String, dynamic> visit, Map<String, dynamic> finding, int index) {
      _showOfflineMessage('Editing findings');
  }
  
  void _onAddVisit() {
      _showOfflineMessage('Adding visits');
  }

  @override
  Widget build(BuildContext context) {
    // Offline usually means we can't act as chairperson fully, 
    // but we display the badge if the data says so.
    final isChairperson = i.isChairperson; 

    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background matching online
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildCustomHeader(isChairperson),
            
             // Offline Indicator Strip
             if (!_isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: const Color(0xFF014323),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_off, size: 14, color: Colors.white),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Offline Mode - You can add findings in offline mode", 
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  // Hero Card (Summary)
                  _buildHeroCard(),
                  const SizedBox(height: 24),

                  // Section Title: Details
                  _buildSectionHeader("Overview", Icons.info_outline),
                  _buildContentCard(
                    child: InquiryDetailsSection(inquiry: i),
                  ),
                  const SizedBox(height: 24),

                  // Section Title: Activity
                  _buildSectionHeader("Field Visits", Icons.location_on_outlined),
                  _buildContentCard(
                    padding: EdgeInsets.zero,
                    child: InquiryVisitsSection(
                      inquiry: i,
                      visits: allVisits,
                      onNavigateToFindings: _onNavigateToFindings,
                      onEditFinding: _onEditFinding,
                      onAddVisit: _onAddVisit,
                      currentUserId: _currentUserId ?? "", 
                      isOffline: true,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader(bool isChairperson) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Inquiry Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          if (isChairperson)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.star_rounded, size: 14, color: AppTheme.primaryColor),
                  SizedBox(width: 4),
                  Text(
                    'Chairperson',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF014323), Color(0xFF0F5132)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.formattedDate,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      i.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Badges
          Wrap(
            spacing: 8,
            children: [
               _buildBadge(i.statusText, i.statusColor),
               _buildBadge(i.priorityText, i.priorityColor),
               if (i.timeFrame.isNotEmpty)
                _buildBadge(i.timeFrame, Colors.grey.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
         border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
