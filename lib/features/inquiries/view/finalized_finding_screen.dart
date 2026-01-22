// lib/features/inquiries/view/finalized_finding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';

import 'package:cmit/core/finalized_finding_service.dart'; // Adjust path if needed
import 'package:cmit/core/widgets/wordpad_widget.dart';
import 'package:cmit/core/utils/html_converter.dart';

class FinalizedFindingScreen extends StatefulWidget {
  final Map<String, dynamic> visit;
  final String inquiryId;

  const FinalizedFindingScreen({
    super.key,
    required this.visit,
    required this.inquiryId,
  });

  @override
  State<FinalizedFindingScreen> createState() => _FinalizedFindingScreenState();
}

class _FinalizedFindingScreenState extends State<FinalizedFindingScreen> {
  final _formKey = GlobalKey<FormState>();
  late quill.QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeQuillController();
  }

  void _initializeQuillController() {
    final findingsList = (widget.visit['findings'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    // Build combined findings text from all visits
    String combinedFindings = '';
    for (int i = 0; i < findingsList.length; i++) {
      final finding = findingsList[i];
      final user = (finding['user'] ?? 'Unknown').toString();
      final findingsText = (finding['findings'] ?? '').toString();

      if (i > 0) combinedFindings += '\n\n';
      combinedFindings += 'Finding #${i + 1} - $user\n$findingsText';
    }

    // Initialize QuillController with plain text
    _quillController = quill.QuillController.basic();
    if (combinedFindings.isNotEmpty) {
      _quillController.document.insert(0, combinedFindings);
      // Move cursor to end
      _quillController.moveCursorToEnd();
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitFinalization() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Get HTML content
      final String htmlContent = QuillToHtmlConverter.convertDeltaToHtml(_quillController.document.toDelta()).trim();
      // Get plain text for validation
      final String plainText = _quillController.document.toPlainText().trim();

      if (plainText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter some findings before finalizing.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final int visitId = widget.visit['id'] as int;

      print("Submitting finalized finding for visit_id: $visitId");
      
      final response = await FinalizedFindingService.storeFinalizedFinding(
        combinedFindings: htmlContent, // Send HTML
        visitId: visitId,
        inquiryId: int.parse(widget.inquiryId),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'All findings finalized successfully'),
            backgroundColor: const Color(0xFF014323),
          ),
        );
        Navigator.pop(context, true); // Return success flag
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to finalize findings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print("Error in _submitFinalization: $e\n$stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final findingsList = (widget.visit['findings'] as List<dynamic>? ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A1A)),
        title: const Text(
          'Finalize All Findings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            fontSize: 16,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E5E5),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSummaryInfo(findingsList.length),
                    const SizedBox(height: 12),
                    _buildQuillEditor(),
                  ],
                ),
              ),
            ),
            if (MediaQuery.of(context).viewInsets.bottom == 0)
              _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryInfo(int totalFindings) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assessment,
                  size: 18,
                  color: Color(0xFF014323),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Combined Findings Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total Findings: $totalFindings',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFFF57C00)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will finalize all findings from all field visits into a single document.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuillEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.edit_document, size: 20, color: Color(0xFF014323)),
                SizedBox(width: 8),
                Text(
                  'Edit Combined Findings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          WordpadWidget(
            controller: _quillController,
            focusNode: _focusNode,
            placeholder: 'Edit all findings here...',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  foregroundColor: const Color(0xFF1A1A1A),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitFinalization,
                icon: _isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.check_circle, size: 20),
                label: Text(
                  _isLoading ? 'Finalizing...' : 'Finalize All Findings',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF014323),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}