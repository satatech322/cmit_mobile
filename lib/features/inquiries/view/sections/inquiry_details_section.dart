// lib/features/inquiries/view/sections/inquiry_details_section.dart
import 'package:flutter/material.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';

class InquiryDetailsSection extends StatelessWidget {
  final AssignToMeModel inquiry;

  const InquiryDetailsSection({
    super.key,
    required this.inquiry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Initiated By', inquiry.initiator),
          _infoRow('Department', inquiry.department),
          _infoRow('Type', inquiry.inquiryType),
          _infoRow('Assigned To', inquiry.assignedTo),
          const SizedBox(height: 16),
          _textSection('Description', inquiry.description),
          const SizedBox(height: 16),
          _textSection('Terms of Reference', inquiry.tors),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textSection(String title, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text.isEmpty ? 'No $title provided' : text,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}