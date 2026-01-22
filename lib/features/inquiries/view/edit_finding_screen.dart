// lib/features/inquiries/view/edit_finding_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cmit/core/finding_update_service.dart'; // Adjust path if needed
import 'package:cmit/core/widgets/wordpad_widget.dart';
import 'package:cmit/core/utils/html_converter.dart';

class EditFindingScreen extends StatefulWidget {
  final Map<String, dynamic> visit;
  final Map<String, dynamic> finding;
  final int findingIndex;
  final String inquiryId;
  final VoidCallback onSave;

  const EditFindingScreen({
    super.key,
    required this.visit,
    required this.finding,
    required this.findingIndex,
    required this.inquiryId,
    required this.onSave,
  });

  @override
  State<EditFindingScreen> createState() => _EditFindingScreenState();
}

class _EditFindingScreenState extends State<EditFindingScreen> {
  late QuillController _controller;
  bool _isSaving = false;
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _selectedImages = [];           // Newly picked images
  List<String> _existingImages = [];          // Existing images from server
  List<String> _removedExistingImages = [];   // For future use if you add delete endpoint

  @override
  void initState() {
    super.initState();
    _initializeController();
    _loadExistingImages();
  }

  void _initializeController() {
    final String findingText = widget.finding['findings']?.toString() ?? '';

    Document document;
    try {
      final deltaJson = jsonDecode(findingText);
      document = Document.fromJson(deltaJson);
    } catch (e) {
      document = Document()..insert(0, findingText);
    }

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _loadExistingImages() {
    final images = widget.finding['files'] ?? widget.finding['images'] ?? [];
    if (images is List) {
      setState(() {
        _existingImages = images.map((e) => e.toString()).toList();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Image Picker Methods
  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        setState(() => _selectedImages.addAll(images));
        _showSnackBar('${images.length} image(s) selected');
      }
    } catch (e) {
      _showSnackBar('Failed to pick images', isError: true);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedImages.add(image));
        _showSnackBar('Image captured');
      }
    } catch (e) {
      _showSnackBar('Failed to capture image', isError: true);
    }
  }

  void _removeNewImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() {
      _removedExistingImages.add(_existingImages[index]);
      _existingImages.removeAt(index);
    });
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Images',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.photo_library, color: Color(0xFF014323)),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.camera_alt, color: Color(0xFF1976D2)),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // Convert new images to base64
  Future<List<String>> _convertImagesToBase64() async {
    List<String> base64Images = [];
    for (var image in _selectedImages) {
      try {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final extension = image.path.split('.').last.toLowerCase();
        final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
        base64Images.add('data:$mimeType;base64,$base64String');
      } catch (e) {
        print('Error converting image: $e');
      }
    }
    return base64Images;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF014323),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Save with API call
  Future<void> _saveFinding() async {
    // Generate HTML content
    final htmlContent = QuillToHtmlConverter.convertDeltaToHtml(_controller.document.toDelta()).trim();
    // Use plain text for validation
    final plainText = _controller.document.toPlainText().trim();
    
    if (plainText.isEmpty) {
      _showSnackBar('Please enter finding details', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Use htmlContent instead of deltaJson
      final newBase64Images = await _convertImagesToBase64();

      final List<String> finalImageList = [
        ..._existingImages,
        ...newBase64Images,
      ];

      final int? findingId = widget.finding['id'] as int? ?? widget.finding['finding_id'] as int?;
      if (findingId == null) {
        _showSnackBar('Finding ID is missing', isError: true);
        return;
      }

      final result = await FindingInquiryService.updateFindingInquiry(
        findingId: findingId,
        findings: htmlContent, // Send HTML
        files: finalImageList,
      );

      if (!mounted) return;

      if (result['success']) {
        // Update local object with new HTML content
        widget.finding['findings'] = htmlContent;
        widget.finding['files'] = finalImageList;

        widget.onSave();
        Navigator.pop(context);
        _showSnackBar('Finding updated successfully');
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update finding', isError: true);
      }
    } catch (e) {
      print('Save finding error: $e');
      if (mounted) {
        _showSnackBar('Network error. Please try again.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String user = widget.finding['user']?.toString() ?? 'Unknown';
    final String visitDate = widget.visit['visit_date']?.toString() ?? '';

    // DECLARE totalImages BEFORE USING IT
    final int totalImages = _existingImages.length + _selectedImages.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A1A)),
        title: const Text(
          'Edit Finding',
          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E5E5), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInfoCard(user, visitDate),
                  const SizedBox(height: 8),
                  _buildQuillEditor(),
                  const SizedBox(height: 8),
                  if (totalImages > 0) _buildImagePreview(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (MediaQuery.of(context).viewInsets.bottom == 0)
            _buildBottomBar(totalImages),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String user, String visitDate) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF014323), borderRadius: BorderRadius.circular(6)),
                child: Text('#${widget.findingIndex}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1A1A1A))),
                    if (visitDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(_formatDate(visitDate), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
                Icon(Icons.description, size: 20, color: Color(0xFF014323)),
                SizedBox(width: 8),
                Text('Finding Details',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
              ],
            ),
          ),
          WordpadWidget(
            controller: _controller,
            focusNode: _focusNode,
            placeholder: 'Enter finding details...',
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final int totalImages = _existingImages.length + _selectedImages.length; // Local reference if needed

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, size: 20, color: Color(0xFF014323)),
              const SizedBox(width: 8),
              Text(
                'Attached Images ($totalImages)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Existing Images
              ..._existingImages.asMap().entries.map((entry) {
                int idx = entry.key;
                String url = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                          loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeExistingImage(idx),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              // New Images
              ..._selectedImages.asMap().entries.map((entry) {
                int idx = entry.key;
                XFile file = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        image: DecorationImage(
                          image: FileImage(File(file.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeNewImage(idx),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 4,
                      left: 4,
                      child: Chip(
                        label: Text('NEW', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        backgroundColor: Color(0xFF014323),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int totalImages) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _showImagePickerOptions,
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: Text(
                totalImages == 0 ? 'Add Images' : 'Add More Images ($totalImages)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF014323),
                side: const BorderSide(color: Color(0xFF014323)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveFinding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF014323),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                        : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr.split(' ').first);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}