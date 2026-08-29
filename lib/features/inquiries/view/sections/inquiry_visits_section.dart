// lib/features/inquiries/view/sections/inquiry_visits_section.dart
import 'package:flutter/material.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/inquiries/view/permissions.dart';

class InquiryVisitsSection extends StatefulWidget {
  final AssignToMeModel inquiry;
  final List<dynamic> visits;
  final Function(Map<String, dynamic>) onNavigateToFindings;
  final Function(Map<String, dynamic>, Map<String, dynamic>, int) onEditFinding;
  final VoidCallback onAddVisit;
  final String? currentUserId;

  const InquiryVisitsSection({
    super.key,
    required this.inquiry,
    required this.visits,
    required this.onNavigateToFindings,
    required this.onEditFinding,
    required this.onAddVisit,
    this.currentUserId,
  });

  @override
  State<InquiryVisitsSection> createState() => _InquiryVisitsSectionState();
}

class _InquiryVisitsSectionState extends State<InquiryVisitsSection> {
  final Map<int, bool> _visitExpansionState = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant InquiryVisitsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when visits list changes from parent (triggered by global refresh)
    if (widget.visits != oldWidget.visits) {
      setState(() {
        // Trigger rebuild with new visits
      });
    }
  }

  String _getFullUrl(String? path) {
    return ApiConfig.getFullUrl(path, ensureStorage: true);
  }

  @override
  Widget build(BuildContext context) {
    final bool canAddVisit = InquiryPermissions.canAddFieldVisit(widget.inquiry);

    // Loading State
    if (widget.currentUserId == null && !widget.inquiry.isChairperson) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    // Empty State
    if (widget.visits.isEmpty) {
        return Column(
          children: [
            _emptyState('No field visits recorded yet'),
             if (canAddVisit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                      onPressed: widget.onAddVisit,
                      icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                      label: const Text('Add First Visit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ),
          ],
        );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Timeline
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.visits.length,
            itemBuilder: (context, index) {
              final visit = widget.visits[index] as Map<String, dynamic>;
              final isLast = index == widget.visits.length - 1;
              return _buildTimelineItem(visit, index + 1, isLast);
            },
          ),
          
          if (canAddVisit) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: widget.onAddVisit,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Another Visit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> visit, int visitNumber, bool isLast) {
    final bool isExpanded = _visitExpansionState[visitNumber] ?? false;
    final String dateStr = (visit['visit_date'] ?? '').toString();
    final String formattedDate = _formatVisitDate(dateStr);
    final String timeStr = (visit['visit_time'] ?? '').toString();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Timeline strip
          SizedBox(
            width: 50,
            child: Column(
             children: [
               Container(
                 width: 36,
                 height: 36,
                 decoration: BoxDecoration(
                   color: AppTheme.primaryColor.withOpacity(0.1),
                   shape: BoxShape.circle,
                   border: Border.all(color: AppTheme.primaryColor, width: 1.5),
                 ),
                 child: Center(
                   child: Text(
                     "$visitNumber",
                     style: const TextStyle(
                       color: AppTheme.primaryColor,
                       fontWeight: FontWeight.bold,
                       fontSize: 14,
                     ),
                   ),
                 ),
               ),
               if (!isLast)
                 Expanded(
                   child: Container(
                     width: 2,
                     color: Colors.grey.shade200,
                     margin: const EdgeInsets.symmetric(vertical: 4),
                   ),
                 ),
             ], 
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Right Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isExpanded ? 0.05 : 0.02),
                      blurRadius: isExpanded ? 12 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Header (Always Visible)
                    InkWell(
                      onTap: () {
                         setState(() {
                           _visitExpansionState[visitNumber] = !isExpanded;
                         });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                if (timeStr.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                ]
                              ],
                            ),
                            const Spacer(),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Expanded Details
                    if (isExpanded) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                         padding: const EdgeInsets.all(16),
                         child: Column(
                           children: [
                             _buildDetailRow(Icons.person_outline, "Officer", visit['officer']),
                             const SizedBox(height: 12),
                             _buildDetailRow(Icons.drive_eta_outlined, "Driver", visit['driver']),
                             const SizedBox(height: 12),
                             _buildDetailRow(Icons.directions_car_outlined, "Vehicle", visit['vehicle']),
                           ],
                         ),
                      ),
                      
                      // Findings Section
                      _buildFindingsSection(visit, visitNumber),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text("$label:", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            (value ?? 'N/A').toString(),
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFindingsSection(Map<String, dynamic> visit, int visitNumber) {
     final findingsList = (visit['findings'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
     
     return Container(
       decoration: BoxDecoration(
         color: Colors.grey.shade50,
         borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
       ),
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(
                 "Findings (${findingsList.length})",
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
               ),
               TextButton(
                 onPressed: () => widget.onNavigateToFindings(visit),
                 style: TextButton.styleFrom(
                   padding: EdgeInsets.zero,
                   minimumSize: Size.zero,
                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                   foregroundColor: AppTheme.primaryColor
                 ),
                 child: const Text("Add", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
               ),
             ],
           ),
           const SizedBox(height: 12),
           
           if (findingsList.isEmpty)
             const Text("No findings recorded yet.", style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic))
           else
            ...findingsList.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final finding = entry.value;
                return _buildFindingSummaryItem(finding, index, visit);
            }).toList(),
         ],
       ),
     );
  }
  
  Widget _buildFindingSummaryItem(Map<String, dynamic> finding, int index, Map<String, dynamic> visit) {
      final List attachments = finding['attachments'] as List<dynamic>? ?? [];
      final String findingUserId = (finding['user_id'] ?? '').toString();
      final String userName = (finding['user'] ?? 'Unknown').toString();
      final bool canEdit = InquiryPermissions.canEditFinding(
                        widget.inquiry,
                        findingUserId: findingUserId,
                        currentUserId: widget.currentUserId,
       );

      return InkWell(
        onTap: () => _showFindingDetails(finding, index, visit, canEdit),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(
                   color: Colors.grey.shade100,
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Text("#$index", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   userName,
                   style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                   maxLines: 1, overflow: TextOverflow.ellipsis,
                 ),
               ),
               if (attachments.isNotEmpty) ...[
                  Icon(Icons.attachment, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    "${attachments.length}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
               ],
               Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
            ],
          ),
        ),
      );
  }

  void _showFindingDetails(Map<String, dynamic> finding, int index, Map<String, dynamic> visit, bool canEdit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                           "Finding #$index",
                           style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (finding['user'] ?? 'Unknown').toString(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 20),
                    ),
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (finding['findings'] ?? 'No details available').toString(),
                      style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                      textAlign: TextAlign.left,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    if ((finding['attachments'] as List?)?.isNotEmpty ?? false) ...[
                      const Text(
                        "Attachments", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildAttachmentsPreview(finding['attachments'] as List),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer Action
            if (canEdit) 
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onEditFinding(visit, finding, index);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text("Edit Finding Record"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsPreview(List<dynamic> attachments) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((attachment) {
        if (attachment is! Map<String, dynamic>) return const SizedBox.shrink();
        final String link = (attachment['link'] ?? '').toString();
        final fullUrl = _getFullUrl(link);
        return InkWell(
          onTap: () => _openAttachment(fullUrl, 'Attachment'),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              image: (link.endsWith('.jpg') || link.endsWith('.png') || link.endsWith('.jpeg')) ?
                   DecorationImage(image: NetworkImage(fullUrl), fit: BoxFit.cover) : null,
            ),
            child: (link.endsWith('.jpg') || link.endsWith('.png') || link.endsWith('.jpeg')) 
                ? null 
                : const Center(child: Icon(Icons.insert_drive_file, color: Colors.grey)),
          ),
        );
      }).toList(),
    );
  }

  void _openAttachment(String url, String title) {
     if (url.isEmpty) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindingImageViewer(imageUrl: url, title: title),
        ),
      );
  }

  String _formatVisitDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr.split(' ').first);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Image Viewer Screen for Findings
class FindingImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;

  const FindingImageViewer({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}