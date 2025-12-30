// lib/features/inquiries/view/inquiry_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/inquiries/view/permissions.dart';
import 'package:cmit/core/auth_service.dart'; // Add this import

// Import section widgets
import 'sections/inquiry_header_section.dart';
import 'sections/inquiry_details_section.dart';
import 'sections/inquiry_visits_section.dart';
import 'sections/inquiry_annex_section.dart';
import 'sections/inquiry_documents_section.dart';

// Import navigation screens
import 'add_visits.dart';
import 'visit_findings_screen.dart';
import 'edit_finding_screen.dart';
import 'finalized_finding_screen.dart';
import 'add_annex.dart';

class InquiryDetailsScreen extends StatefulWidget {
  final AssignToMeModel inquiry;

  const InquiryDetailsScreen({
    super.key,
    required this.inquiry,
  });

  @override
  State<InquiryDetailsScreen> createState() => _InquiryDetailsScreenState();
}

class _InquiryDetailsScreenState extends State<InquiryDetailsScreen> {
  late List<dynamic> documents = [];
  late List<dynamic> allVisits = [];
  late List<dynamic> allAnnexes = [];
  String? _currentUserId; // Add this

  // Track expansion state
  bool _detailsExpanded = false;
  bool _visitsExpanded = false;
  bool _annexExpanded = false;
  bool _documentsExpanded = false;

  AssignToMeModel get i => widget.inquiry;

  @override
  void initState() {
    super.initState();
    allVisits = i.visits;
    documents = i.requiredDocuments;
    allAnnexes = i.annexes;
    _loadCurrentUserId(); // Add this
  }

  /// ✅ Load current user ID from AuthService
  Future<void> _loadCurrentUserId() async {
    final userId = await AuthService.getCurrentUserId();
    setState(() {
      _currentUserId = userId;
    });
    print("🔹 Loaded current user ID: $_currentUserId");
  }

  void _addVisit() {
    // Check permission
    if (!InquiryPermissions.canAddFieldVisit(i)) {
      _showPermissionError('Only chairperson can add field visits');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVisitsScreen(
          inquiryId: i.id,
          onVisitAdded: () {
            setState(() {
              allVisits = i.visits;
            });
          },
        ),
      ),
    );
  }

  void _navigateToFindings(Map<String, dynamic> visit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisitFindingsScreen(
          visit: visit,
          inquiryId: i.id.toString(),
        ),
      ),
    ).then((_) {
      setState(() {
        allVisits = i.visits;
      });
    });
  }

  void _editFinding(Map<String, dynamic> visit, Map<String, dynamic> finding, int index) {
    // Get the finding's user ID
    final String findingUserId = (finding['user_id'] ?? '').toString();

    // Check permission with user-specific logic
    if (!InquiryPermissions.canEditFinding(
      i,
      findingUserId: findingUserId,
      currentUserId: _currentUserId,
    )) {
      _showPermissionError('You can only edit your own findings');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditFindingScreen(
          visit: visit,
          finding: finding,
          findingIndex: index,
          inquiryId: i.id.toString(),
          onSave: () {
            setState(() {
              allVisits = i.visits;
            });
          },
        ),
      ),
    );
  }

  void _navigateToFinalizeAllFindings() {
    // Check permission
    if (!InquiryPermissions.canFinalizeFindings(i)) {
      _showPermissionError('Only chairperson can finalize findings');
      return;
    }

    // Collect all findings from all visits
    List<Map<String, dynamic>> allFindings = [];

    for (var visit in allVisits) {
      final visitMap = visit as Map<String, dynamic>;
      final findingsList = (visitMap['findings'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      if (findingsList.isNotEmpty) {
        allFindings.addAll(findingsList);
      }
    }

    if (allFindings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No findings available to finalize'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create a combined visit object with all findings
    Map<String, dynamic> combinedVisit = {
      'id': allVisits.first['id'], // Use first visit's ID
      'visit_date': 'All Visits',
      'visit_time': '',
      'officer': 'Multiple Officers',
      'driver': 'Multiple Drivers',
      'vehicle': 'Multiple Vehicles',
      'findings': allFindings,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinalizedFindingScreen(
          visit: combinedVisit,
          inquiryId: i.id.toString(),
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {
          allVisits = i.visits;
        });
      }
    });
  }

  void _refreshAnnexes() {
    setState(() {
      allAnnexes = i.annexes;
    });
  }

  void _navigateToAnnexDetails(Map<String, dynamic> annex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(annex['title'] ?? 'Annex Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${annex['id'] ?? annex['annex_id']}'),
            const SizedBox(height: 8),
            Text('Sort Order: ${annex['sort_order'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Files: ${(annex['annex_files'] as List?)?.length ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editAnnex(Map<String, dynamic> annex, int annexNumber) {
    // Check permission
    if (!InquiryPermissions.canEditAnnex(i)) {
      _showPermissionError('Only chairperson can edit annexes');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit Annex #$annexNumber - Coming soon')),
    );
  }

  void _showPermissionError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Get total number of findings across all visits
  int _getTotalFindings() {
    int total = 0;
    for (var visit in allVisits) {
      final visitMap = visit as Map<String, dynamic>;
      final findingsList = (visitMap['findings'] as List<dynamic>? ?? []);
      total += findingsList.length;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isChairperson = i.isChairperson;
    final canFinalizeFindings = InquiryPermissions.canFinalizeFindings(i);
    final totalFindings = _getTotalFindings();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A1A)),
        title: const Text(
          'Inquiry Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E5E5),
            height: 1,
          ),
        ),
        actions: [
          if (isChairperson)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF014323).withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: Color(0xFF014323)),
                  SizedBox(width: 4),
                  Text(
                    'Chairperson',
                    style: TextStyle(
                      color: Color(0xFF014323),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Finalize button (only for chairperson)
            InquiryHeaderSection(inquiry: i),

            const SizedBox(height: 8),

            // Details Section
            _buildCollapsibleSection(
              title: 'Details',
              icon: Icons.info_outline,
              isExpanded: _detailsExpanded,
              onToggle: () => setState(() => _detailsExpanded = !_detailsExpanded),
              child: InquiryDetailsSection(inquiry: i),
            ),

            // Field Visits Section
            _buildCollapsibleSection(
              title: 'Field Visits',
              icon: Icons.location_on,
              count: allVisits.length,
              isExpanded: _visitsExpanded,
              onToggle: () => setState(() => _visitsExpanded = !_visitsExpanded),
              child: InquiryVisitsSection(
                inquiry: i,
                visits: allVisits,
                onNavigateToFindings: _navigateToFindings,
                onEditFinding: _editFinding,
                onAddVisit: _addVisit,
                currentUserId: _currentUserId, // Pass the current user ID
              ),
            ),

            // Centralized Finalize All Findings Button
            if (canFinalizeFindings && totalFindings > 0)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToFinalizeAllFindings,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text('Finalize All Findings ($totalFindings)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF014323),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Annex Section
            _buildCollapsibleSection(
              title: 'Annex',
              icon: Icons.folder_special,
              count: allAnnexes.length,
              isExpanded: _annexExpanded,
              onToggle: () => setState(() => _annexExpanded = !_annexExpanded),
              child: InquiryAnnexSection(
                inquiry: i,
                annexes: allAnnexes,
                onNavigateToAnnexDetails: _navigateToAnnexDetails,
                onEditAnnex: _editAnnex,
                onAnnexAdded: _refreshAnnexes,
              ),
            ),

            // Documents Section
            _buildCollapsibleSection(
              title: 'Documents',
              icon: Icons.description_outlined,
              count: documents.length,
              isExpanded: _documentsExpanded,
              onToggle: () => setState(() => _documentsExpanded = !_documentsExpanded),
              child: InquiryDocumentsSection(
                initialDocuments: documents,
                inquiryId: i.id,
                onDocumentsChanged: (updatedDocs) {
                  setState(() {
                    documents = updatedDocs;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    int? count,
    required bool isExpanded,
    required VoidCallback onToggle,
    VoidCallback? onAdd,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF014323)),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (count != null && count > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF014323),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            child,
          ],
        ],
      ),
    );
  }
}