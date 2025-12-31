// lib/features/inquiries/view/inquiry_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/inquiries/view/permissions.dart';
import 'package:cmit/core/auth_service.dart';
import 'dart:async';
import 'package:cmit/core/assign_to_me.dart';
import 'package:cmit/core/global_refresh_event.dart';

// Import section widgets
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

class _InquiryDetailsScreenState extends State<InquiryDetailsScreen> with SingleTickerProviderStateMixin {
  late List<dynamic> documents = [];
  late List<dynamic> allVisits = [];
  late List<dynamic> allAnnexes = [];
  String? _currentUserId;

  late AssignToMeModel _inquiry;
  StreamSubscription? _refreshSubscription;

  AssignToMeModel get i => _inquiry;

  @override
  void initState() {
    super.initState();
    _inquiry = widget.inquiry;
    allVisits = i.visits;
    documents = i.requiredDocuments;
    allAnnexes = i.annexes;
    _loadCurrentUserId();
    
    _refreshSubscription = GlobalRefreshEvent.instance.refreshStream.listen((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final result = await AssignToMe.getAssignedInquiries();
    
    if (result['success'] == true) {
      final List<AssignToMeModel> inquiries = result['inquiries'];
      try {
        final updatedInquiry = inquiries.firstWhere((inq) => inq.id == widget.inquiry.id);
        if (mounted) {
          setState(() {
            _inquiry = updatedInquiry;
            allVisits = _inquiry.visits;
            allAnnexes = _inquiry.annexes;
            documents = _inquiry.requiredDocuments;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Data updated successfully'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await AuthService.getCurrentUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  // Navigation Logic mirrors
  void _addVisit() {
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
    final String findingUserId = (finding['user_id'] ?? '').toString();

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
    if (!InquiryPermissions.canFinalizeFindings(i)) {
      _showPermissionError('Only chairperson can finalize findings');
      return;
    }

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
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Map<String, dynamic> combinedVisit = {
      'id': allVisits.first['id'],
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
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAnnexesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _AnnexesModal(
        inquiry: i,
        initialAnnexes: allAnnexes,
        onNavigateToAnnexDetails: _navigateToAnnexDetails,
        onEditAnnex: _editAnnex,
        onRefresh: () async {
          await _refreshData();
        },
      ),
    );
  }

  void _showDocumentsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _DocumentsModal(
        inquiryId: i.id,
        initialDocuments: documents,
        onRefresh: () async {
          await _refreshData();
        },
      ),
    );
  }

  int _getTotalFindings() {
    int total = 0;
    for (var visit in allVisits) {
      final visitMap = visit as Map<String, dynamic>;
      final findingsList = (visitMap['findings'] as List<dynamic>? ?? []);
      total += findingsList.length;
    }
    return total;
  }
  
  void _showFinalizeConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Finalize Inquiry'),
          content: const Text(
            'Are you sure you want to finalize this inquiry? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Trigger finalize action logic here
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Finalize', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChairperson = i.isChairperson;
    final canFinalizeFindings = InquiryPermissions.canFinalizeFindings(i);
    final totalFindings = _getTotalFindings();
    final canFinalizeInquiry = InquiryPermissions.canFinalizeInquiry(i);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildCustomHeader(isChairperson),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                
                  // Hero Card (Summary)
                  _buildHeroCard(canFinalizeInquiry),
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
                    child: Column(
                      children: [
                         InquiryVisitsSection(
                            inquiry: i,
                            visits: allVisits,
                            onNavigateToFindings: _navigateToFindings,
                            onEditFinding: _editFinding,
                            onAddVisit: _addVisit,
                            currentUserId: _currentUserId,
                          ),
                          // Add Visit Button (if visible) moved inside section for better UX? 
                          // Or kept as floated. The section handles add buttons usually.
                      ],
                    ),
                  ),

                  // Finalize Findings Button (Contextual)
                  if (canFinalizeFindings && totalFindings > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton.icon(
                        onPressed: _navigateToFinalizeAllFindings,
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text('Finalize All Findings ($totalFindings)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF014323),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  
                  // Section Title: Resources
                  _buildSectionHeader("Resources", Icons.folder_open_rounded),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Annex Card
                      Expanded(
                        child: _buildSmallSectionCard(
                          title: "Annexes",
                          count: allAnnexes.length,
                          icon: Icons.attach_file_rounded,
                          onTap: () {
                             showModalBottomSheet(
                               context: context,
                               isScrollControlled: true,
                               backgroundColor: Colors.transparent,
                               builder: (context) => Container(
                                 height: MediaQuery.of(context).size.height * 0.8,
                                 decoration: const BoxDecoration(
                                   color: Colors.white,
                                   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                 ),
                                 child: Column(
                                   children: [
                                     Padding(
                                       padding: const EdgeInsets.all(16),
                                       child: Text("Annexes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                     ),
                                     Expanded(
                                       child: InquiryAnnexSection(
                                          inquiry: i,
                                          annexes: allAnnexes,
                                          onNavigateToAnnexDetails: _navigateToAnnexDetails,
                                          onEditAnnex: _editAnnex,
                                          onAnnexAdded: _refreshAnnexes,
                                        ),
                                     ),
                                   ],
                                 ),
                               ),
                             );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Documents Card
                      Expanded(
                        child: _buildSmallSectionCard(
                          title: "Documents",
                          count: documents.length,
                          icon: Icons.description_rounded,
                          onTap: () {
                             showModalBottomSheet(
                               context: context,
                               isScrollControlled: true,
                               backgroundColor: Colors.transparent,
                               builder: (context) => Container(
                                 height: MediaQuery.of(context).size.height * 0.8,
                                 decoration: const BoxDecoration(
                                   color: Colors.white,
                                   borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                 ),
                                 child: Column(
                                   children: [
                                     Padding(
                                       padding: const EdgeInsets.all(16),
                                       child: Text("Documents", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                     ),
                                     Expanded(
                                       child: InquiryDocumentsSection(
                                          initialDocuments: documents,
                                          inquiryId: i.id,
                                          onDocumentsChanged: (updatedDocs) {
                                            setState(() => documents = updatedDocs);
                                          },
                                        ),
                                     ),
                                   ],
                                 ),
                               ),
                             );
                          },
                        ),
                      ),
                    ],
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
  
  Widget _buildHeroCard(bool canFinalize) {
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
          
          if (canFinalize) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showFinalizeConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("Finalize Inquiry", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
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

  Widget _buildSmallSectionCard({
      required String title, 
      required int count, 
      required IconData icon, 
      required VoidCallback onTap,
    }) {
    return InkWell(
      onTap: onTap,
       borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 140, 
        decoration: BoxDecoration(
          color: const Color(0xFF014323).withOpacity(0.04), // Transparent green background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF014323).withOpacity(0.1)), // Subtle green border
        ),
        child: Stack(
          children: [
            // Watermark Icon covering the box
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 100,
                color: const Color(0xFF014323).withOpacity(0.15),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox( // Ensure full width for centering
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      "$count",
                       style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87), // Increased size slightly
                    ),
                    Text(
                      title,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

// Stateful Modal for Annexes that listens to global refresh
class _AnnexesModal extends StatefulWidget {
  final AssignToMeModel inquiry;
  final List<dynamic> initialAnnexes;
  final Function(Map<String, dynamic>) onNavigateToAnnexDetails;
  final Function(Map<String, dynamic>, int) onEditAnnex;
  final Future<void> Function() onRefresh;

  const _AnnexesModal({
    required this.inquiry,
    required this.initialAnnexes,
    required this.onNavigateToAnnexDetails,
    required this.onEditAnnex,
    required this.onRefresh,
  });

  @override
  State<_AnnexesModal> createState() => _AnnexesModalState();
}

class _AnnexesModalState extends State<_AnnexesModal> {
  late List<dynamic> annexes;
  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    annexes = widget.initialAnnexes;
    
    // Subscribe to global refresh events
    _refreshSubscription = GlobalRefreshEvent.instance.refreshStream.listen((_) async {
      await widget.onRefresh();
      // Fetch the updated inquiry data
      final result = await AssignToMe.getAssignedInquiries();
      if (result['success'] == true && mounted) {
        final inquiries = result['inquiries'] as List<AssignToMeModel>;
        try {
          final updated = inquiries.firstWhere((inq) => inq.id == widget.inquiry.id);
          setState(() {
            annexes = updated.annexes;
          });
        } catch (e) {
          // Inquiry not found
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Annexes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: InquiryAnnexSection(
              inquiry: widget.inquiry,
              annexes: annexes,
              onNavigateToAnnexDetails: widget.onNavigateToAnnexDetails,
              onEditAnnex: widget.onEditAnnex,
              onAnnexAdded: () {}, // No need to call back since we're listening to global refresh
            ),
          ),
        ],
      ),
    );
  }
}

// Stateful Modal for Documents that listens to global refresh
class _DocumentsModal extends StatefulWidget {
  final dynamic inquiryId;
  final List<dynamic> initialDocuments;
  final Future<void> Function() onRefresh;

  const _DocumentsModal({
    required this.inquiryId,
    required this.initialDocuments,
    required this.onRefresh,
  });

  @override
  State<_DocumentsModal> createState() => _DocumentsModalState();
}

class _DocumentsModalState extends State<_DocumentsModal> {
  late List<dynamic> documents;
  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    documents = widget.initialDocuments;
    
    // Subscribe to global refresh events
    _refreshSubscription = GlobalRefreshEvent.instance.refreshStream.listen((_) async {
      await widget.onRefresh();
      // Fetch the updated inquiry data
      final result = await AssignToMe.getAssignedInquiries();
      if (result['success'] == true && mounted) {
        final inquiries = result['inquiries'] as List<AssignToMeModel>;
        try {
          final updated = inquiries.firstWhere((inq) => inq.id == widget.inquiryId);
          setState(() {
            documents = updated.requiredDocuments;
          });
        } catch (e) {
          // Inquiry not found
        }
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Documents", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: InquiryDocumentsSection(
              initialDocuments: documents,
              inquiryId: widget.inquiryId,
              onDocumentsChanged: (updatedDocs) {
                setState(() => documents = updatedDocs);
              },
            ),
          ),
        ],
      ),
    );
  }
}