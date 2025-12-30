// lib/features/inquiries/view/sections/inquiry_visits_section.dart
import 'package:flutter/material.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/inquiries/view/permissions.dart';

class InquiryVisitsSection extends StatefulWidget {
  final AssignToMeModel inquiry;
  final List<dynamic> visits;
  final Function(Map<String, dynamic>) onNavigateToFindings;
  final Function(Map<String, dynamic>, Map<String, dynamic>, int) onEditFinding;
  final VoidCallback onAddVisit;

  const InquiryVisitsSection({
    super.key,
    required this.inquiry,
    required this.visits,
    required this.onNavigateToFindings,
    required this.onEditFinding,
    required this.onAddVisit,
  });

  @override
  State<InquiryVisitsSection> createState() => _InquiryVisitsSectionState();
}

class _InquiryVisitsSectionState extends State<InquiryVisitsSection> {
  Map<int, bool> _visitExpansionState = {};
  static const String baseUrl = 'https://cmit.sata.pk';

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.visits.length; i++) {
      _visitExpansionState[i] = false;
    }
  }

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Remove leading slash if present
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Check if path already includes storage
    if (cleanPath.startsWith('storage/')) {
      return '$baseUrl/$cleanPath';
    }

    // For finding attachments and other relative paths, add storage prefix
    return '$baseUrl/storage/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    // Check permissions
    final bool canAddVisit = InquiryPermissions.canAddFieldVisit(widget.inquiry);
    final bool canEditFinding = InquiryPermissions.canEditFinding(widget.inquiry);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.visits.isEmpty)
            _emptyState('No field visits recorded yet')
          else
            ...widget.visits.asMap().entries.map((entry) {
              final int visitNumber = entry.key + 1;
              final visit = entry.value as Map<String, dynamic>;
              return _visitCard(
                visit,
                visitNumber,
                canEditFinding: canEditFinding,
              );
            }).toList(),

          const SizedBox(height: 12),

          // Add Visit Button - Only show to chairperson
          if (canAddVisit)
            Center(
              child: OutlinedButton.icon(
                onPressed: widget.onAddVisit,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Field Visit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF014323),
                  side: const BorderSide(color: Color(0xFF014323)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _visitCard(
      Map<String, dynamic> visit,
      int visitNumber, {
        required bool canEditFinding,
      }) {
    final findingsList = (visit['findings'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final String dateStr = (visit['visit_date'] ?? '').toString();
    final String formattedDate = _formatVisitDate(dateStr);
    final bool isExpanded = _visitExpansionState[visitNumber - 1] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _visitExpansionState[visitNumber - 1] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isExpanded ? Radius.zero : const Radius.circular(12),
                  bottomRight: isExpanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF014323),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Visit $visitNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today, size: 13, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF014323),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      Text(
                        (visit['visit_time'] ?? '').toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _visitInfo('Officer', (visit['officer'] ?? '').toString()),
                  const SizedBox(height: 6),
                  _visitInfo('Driver', (visit['driver'] ?? '').toString()),
                  const SizedBox(height: 6),
                  _visitInfo('Vehicle', (visit['vehicle'] ?? '').toString()),
                ],
              ),
            ),
            if (findingsList.isNotEmpty) ...[
              Divider(height: 1, color: Colors.grey[300]),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Findings (${findingsList.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...findingsList.asMap().entries.map((entry) {
                      final int index = entry.key + 1;
                      final Map<String, dynamic> finding = entry.value;
                      return _findingItem(
                        user: (finding['user'] ?? 'Unknown').toString(),
                        findingsText: (finding['findings'] ?? '').toString(),
                        attachments: finding['attachments'] as List<dynamic>? ?? [],
                        number: index,
                        canEdit: canEditFinding,
                        onEdit: () => widget.onEditFinding(visit, finding, index),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
            Divider(height: 1, color: Colors.grey[300]),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => widget.onNavigateToFindings(visit),
                  icon: const Icon(Icons.assignment, size: 18),
                  label: const Text('Findings/Proceedings/Recommendations'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF014323),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _visitInfo(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _findingItem({
    required String user,
    required String findingsText,
    required List<dynamic> attachments,
    required int number,
    required bool canEdit,
    required VoidCallback onEdit,
  }) {
    final int attachmentCount = attachments.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF014323),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              // Edit button - Only show to chairperson
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit, size: 16, color: Color(0xFF014323)),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit Finding',
                ),
            ],
          ),
          if (findingsText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              findingsText,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
          // Display attachments if available
          if (attachmentCount > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.attachment, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Attachments ($attachmentCount)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _viewAllAttachments(attachments, user, number),
                  icon: const Icon(Icons.visibility, size: 14),
                  label: Text(
                    attachmentCount > 1 ? 'View All' : 'View',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF014323),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildAttachmentsPreview(attachments),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentsPreview(List<dynamic> attachments) {
    final displayCount = attachments.length > 3 ? 3 : attachments.length;
    final remaining = attachments.length - displayCount;

    return Row(
      children: [
        ...attachments.take(displayCount).map((attachment) {
          if (attachment is! Map<String, dynamic>) return const SizedBox.shrink();

          final String fileType = (attachment['file_type'] ?? '').toString();
          final String link = (attachment['link'] ?? '').toString();
          final fullUrl = _getFullUrl(link);

          return _buildAttachmentThumbnail(
            fileType: fileType,
            link: fullUrl,
            onTap: () => _openAttachment(fullUrl, fileType, 'Attachment'),
          );
        }).toList(),
        if (remaining > 0)
          Container(
            margin: const EdgeInsets.only(right: 6),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF014323).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF014323).withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                '+$remaining',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF014323),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentThumbnail({
    required String fileType,
    required String link,
    required VoidCallback onTap,
  }) {
    final bool isImage = fileType.toLowerCase().contains('image') ||
        fileType.toLowerCase().contains('jpeg') ||
        fileType.toLowerCase().contains('jpg') ||
        fileType.toLowerCase().contains('png') ||
        link.toLowerCase().endsWith('.jpg') ||
        link.toLowerCase().endsWith('.jpeg') ||
        link.toLowerCase().endsWith('.png');

    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isImage
                ? Image.network(
              link,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Image load error: $error for URL: $link');
                return _buildFileIcon(Icons.broken_image, Colors.red);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF014323)),
                  ),
                );
              },
            )
                : _buildFileIcon(Icons.insert_drive_file, const Color(0xFF014323)),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(IconData icon, Color color) {
    return Center(
      child: Icon(
        icon,
        size: 28,
        color: color,
      ),
    );
  }

  void _viewAllAttachments(List<dynamic> attachments, String user, int findingNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finding #$findingNumber - $user',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${attachments.length} ${attachments.length == 1 ? 'attachment' : 'attachments'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = attachments[index] as Map<String, dynamic>;
                      return _buildAttachmentListItem(attachment, index);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttachmentListItem(Map<String, dynamic> attachment, int index) {
    final fileType = attachment['file_type']?.toString() ?? '';
    final link = attachment['link']?.toString() ?? '';
    final fullUrl = _getFullUrl(link);

    IconData icon;
    Color iconColor;

    if (fileType.contains('image') ||
        link.toLowerCase().endsWith('.jpg') ||
        link.toLowerCase().endsWith('.jpeg') ||
        link.toLowerCase().endsWith('.png')) {
      icon = Icons.image;
      iconColor = Colors.blue[700]!;
    } else if (fileType.contains('pdf') || link.toLowerCase().endsWith('.pdf')) {
      icon = Icons.picture_as_pdf;
      iconColor = Colors.red[700]!;
    } else {
      icon = Icons.insert_drive_file;
      iconColor = Colors.grey[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          'Attachment ${index + 1}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Text(
          fileType.isNotEmpty ? fileType : 'File',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: IconButton(
          onPressed: () {
            Navigator.pop(context);
            _openAttachment(fullUrl, fileType, 'Attachment ${index + 1}');
          },
          icon: const Icon(Icons.open_in_new),
          color: const Color(0xFF014323),
          tooltip: 'Open',
        ),
      ),
    );
  }

  void _openAttachment(String url, String fileType, String title) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attachment URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (fileType.contains('image') ||
        url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.png')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindingImageViewer(
            imageUrl: url,
            title: title,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening: $title'),
          backgroundColor: const Color(0xFF014323),
        ),
      );
    }
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
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