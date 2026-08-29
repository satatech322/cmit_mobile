// lib/features/inquiries/view/edit_finalized_finding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:cmit/core/finalized_finding_service.dart';
import 'package:cmit/core/widgets/wordpad_widget.dart';
import 'package:cmit/core/utils/html_converter.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';

class EditFinalizedFindingScreen extends StatefulWidget {
  final AssignToMeModel inquiry;
  final String initialHtmlContent;

  const EditFinalizedFindingScreen({
    super.key,
    required this.inquiry,
    required this.initialHtmlContent,
  });

  @override
  State<EditFinalizedFindingScreen> createState() => _EditFinalizedFindingScreenState();
}

class _EditFinalizedFindingScreenState extends State<EditFinalizedFindingScreen> {
  late quill.QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeQuillController();
  }

  void _initializeQuillController() {
    final plainText = QuillToHtmlConverter.htmlToPlainText(widget.initialHtmlContent);
    _quillController = quill.QuillController.basic();
    if (plainText.isNotEmpty) {
      _quillController.document.insert(0, plainText);
      _quillController.moveCursorToEnd();
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _updateFinalizedFindings() async {
    if (_isLoading) return;

    final String plainText = _quillController.document.toPlainText().trim();
    if (plainText.isEmpty || plainText == '\n') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter findings before updating.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String htmlContent = QuillToHtmlConverter.convertDeltaToHtml(
        _quillController.document.toDelta(),
      ).trim();

      final response = await FinalizedFindingService.updateFinalizedFinding(
        inquiryId: widget.inquiry.id,
        combinedFindings: htmlContent,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Inquiry finalized finding updated successfully'),
            backgroundColor: const Color(0xFF014323),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update finalized findings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A1A)),
        title: const Text(
          'Edit Finalized Findings',
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
                    _buildInquiryHeaderInfo(),
                    const SizedBox(height: 12),
                    _buildQuillEditor(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryHeaderInfo() {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_document,
              size: 20,
              color: Color(0xFF014323),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.inquiry.title.isNotEmpty ? widget.inquiry.title : 'Inquiry #${widget.inquiry.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Update compiled findings for this inquiry',
                  style: TextStyle(
                    color: Colors.grey.shade600,
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

  Widget _buildQuillEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.edit_note, size: 20, color: Color(0xFF014323)),
                const SizedBox(width: 8),
                const Text(
                  'Finalized Findings Content',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                Text(
                  'Rich Text',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          WordpadWidget(
            controller: _quillController,
            focusNode: _focusNode,
            placeholder: 'Edit finalized findings and recommendations...',
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
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _updateFinalizedFindings,
          icon: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check_circle, size: 18),
          label: Text(
            _isLoading ? 'Updating Findings...' : 'Update Finalized Findings',
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
          ),
        ),
      ),
    );
  }
}
