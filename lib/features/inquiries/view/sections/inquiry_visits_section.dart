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

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.visits.length; i++) {
      _visitExpansionState[i] = false;
    }
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
    required int number,
    required bool canEdit,
    required VoidCallback onEdit,
  }) {
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
        ],
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