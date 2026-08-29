// lib/features/offline/view/offline_visit_findings_screen.dart - WITH OFFLINE SUPPORT
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:cmit/core/finding_inquiry_service.dart';
import 'package:cmit/features/offline/services/offline_service.dart';
import 'package:cmit/features/offline/widgets/offline_indicator.dart';
import 'package:cmit/core/widgets/wordpad_widget.dart';
import 'package:cmit/core/utils/html_converter.dart';

class OfflineVisitFindingsScreen extends StatefulWidget {
  final Map<String, dynamic> visit;
  final String inquiryId;

  const OfflineVisitFindingsScreen({
    super.key,
    required this.visit,
    required this.inquiryId,
  });

  @override
  State<OfflineVisitFindingsScreen> createState() => _OfflineVisitFindingsScreenState();
}

class _OfflineVisitFindingsScreenState extends State<OfflineVisitFindingsScreen> {
  late quill.QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final hasInternet = await OfflineService.hasInternet();
    if (mounted) {
      setState(() => _isOnline = hasInternet);
    }
  }

  void _loadExistingData() {
    final rawContent =
        widget.visit['findings_proceedings_recommendations']?.toString() ?? '';
    final existingContent = QuillToHtmlConverter.htmlToPlainText(rawContent);

    final doc = quill.Document();
    if (existingContent.isNotEmpty) {
      doc.insert(0, existingContent);
    }

    _controller = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitFindings() async {
    final htmlContent = QuillToHtmlConverter.convertDeltaToHtml(_controller.document.toDelta()).trim();
    final plainText = _controller.document.toPlainText().trim();

    if (plainText.isEmpty || plainText == '\n') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter findings before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    await _checkConnectivity();

    if (_isOnline) {
      await _submitOnline(htmlContent);
    } else {
      if (plainText.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Findings must be at least 5 characters long in offline mode'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isSubmitting = false); 
        return;
      }
      await _submitOffline(htmlContent);
    }
  }

  Future<void> _submitOnline(String content) async {
    final visitId = widget.visit['id'];
    if (visitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit ID not found!'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    List<String>? base64Files;
    if (_selectedImages.isNotEmpty) {
      base64Files = [];
      for (var img in _selectedImages) {
        final bytes = await img.readAsBytes();
        final base64String = base64Encode(bytes);

        // Determine mime type
        final extension = img.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg';
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'gif') {
          mimeType = 'image/gif';
        }

        base64Files.add('data:$mimeType;base64,$base64String');
      }
    }

    final result = await FindingInquiryService.storeFinding(
      findings: content,
      visitId: int.parse(visitId.toString()),
      files: base64Files,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Findings submitted successfully!'),
          backgroundColor: const Color(0xFF014323),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit findings'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitOffline(String content) async {
    final visitId = widget.visit['id'];
    if (visitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit ID not found!'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    final List<String> imagePaths = _selectedImages.map((e) => e.path).toList();

    final success = await OfflineService.saveFindingOffline(
      inquiryId: int.parse(widget.inquiryId),
      visitId: visitId.toString(),
      findings: content,
      images: imagePaths,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Findings saved offline. Will sync when online.'),
          backgroundColor: Color(0xFF014323),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save findings offline'),
          backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final String dateStr = (widget.visit['visit_date'] ?? '').toString();
    final formattedDate = _formatVisitDate(dateStr);
    final String visitTime = (widget.visit['visit_time'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A1A)),
        title: const Text(
          'Findings / Proceedings / Recommendations',
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
            // Offline Indicator
            const OfflineIndicator(),

            // Offline Mode Notice
            if (!_isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF014323).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFF014323),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline mode: Findings and images will be saved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF014323).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildVisitInfoHeader(formattedDate, visitTime),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.description,
                                    size: 20, color: Color(0xFF014323)),
                                SizedBox(width: 8),
                                Text(
                                  'Finding Details',
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
                            controller: _controller,
                            focusNode: _focusNode,
                            placeholder:
                                'Enter findings, proceedings, and recommendations...',
                            minHeight: 200,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Image Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Attachments',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.add_a_photo, size: 18),
                                  label: const Text('Add Image'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF014323),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          if (_selectedImages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'No images selected',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 120,
                              padding: const EdgeInsets.all(12),
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                          image: DecorationImage(
                                            image: FileImage(File(_selectedImages[index].path)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: InkWell(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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

  Widget _buildVisitInfoHeader(String date, String time) {
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
                  Icons.calendar_today,
                  size: 18,
                  color: Color(0xFF014323),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Officer', (widget.visit['officer'] ?? 'N/A').toString()),
                const SizedBox(height: 8),
                _buildInfoRow('Driver', (widget.visit['driver'] ?? 'N/A').toString()),
                const SizedBox(height: 8),
                _buildInfoRow('Vehicle', (widget.visit['vehicle'] ?? 'N/A').toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
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
          onPressed: _isSubmitting ? null : _submitFindings,
          icon: _isSubmitting
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : Icon(_isOnline ? Icons.send : Icons.save, size: 18),
          label: Text(
            _isSubmitting
                ? 'Submitting...'
                : _isOnline
                ? 'Submit Findings'
                : 'Save Offline',
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