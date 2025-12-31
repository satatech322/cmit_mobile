// lib/features/inquiries/view/sections/inquiry_annex_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/inquiries/view/permissions.dart';
import '../add_annex.dart';
import '../add_attachment_annex.dart';

class InquiryAnnexSection extends StatefulWidget {
  final AssignToMeModel inquiry;
  final List<dynamic> annexes;
  final Function(Map<String, dynamic>) onNavigateToAnnexDetails;
  final Function(Map<String, dynamic>, int) onEditAnnex;
  final VoidCallback onAnnexAdded;

  const InquiryAnnexSection({
    super.key,
    required this.inquiry,
    required this.annexes,
    required this.onNavigateToAnnexDetails,
    required this.onEditAnnex,
    required this.onAnnexAdded,
  });

  @override
  State<InquiryAnnexSection> createState() => _InquiryAnnexSectionState();
}

class _InquiryAnnexSectionState extends State<InquiryAnnexSection> {
  static const String baseUrl = 'https://cmit.sata.pk';

  @override
  void didUpdateWidget(covariant InquiryAnnexSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force rebuild when annexes list changes from parent (triggered by global refresh)
    if (widget.annexes != oldWidget.annexes) {
      setState(() {
        // Trigger rebuild with new annexes
      });
    }
  }

  String _getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$cleanPath';
  }

  void _navigateToAddAnnex() async {
    // Check permission
    if (!InquiryPermissions.canAddAnnex(widget.inquiry)) {
      _showSnackBar('Only chairperson can add annexes', isError: true);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAnnexScreen(
          inquiryId: widget.inquiry.id,
          onAnnexAdded: widget.onAnnexAdded,
        ),
      ),
    );

    if (result == true) {
      widget.onAnnexAdded();
    }
  }

  void _viewAnnexFiles(Map<String, dynamic> annex, int annexNumber) {
    final List<dynamic> files = (annex['annex_files'] ?? []) as List<dynamic>;

    if (files.isEmpty) {
      _showSnackBar('No files attached to this annex', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilesSheet(annex, files, annexNumber),
    );
  }

  Widget _buildFilesSheet(Map<String, dynamic> annex, List files, int annexNumber) {
    final annexTitle = annex['title']?.toString() ?? 'Annex $annexNumber';
    final bool canAddAttachment = InquiryPermissions.canAddAttachmentToAnnex(widget.inquiry);

    return DraggableScrollableSheet(
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Annex $annexNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      annexTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${files.length} ${files.length == 1 ? 'file' : 'files'}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index] as Map<String, dynamic>;
                    return _buildFileItem(file, index);
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Add Attachment Button - Only show to chairperson
              if (canAddAttachment)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToAddAttachment(annex, annexNumber);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Attachment'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileItem(Map<String, dynamic> file, int index) {
    final String link = (file['link'] ?? '').toString();
    final String fileType = (file['file_type'] ?? '').toString();
    final fullUrl = _getFullUrl(link);

    IconData icon;
    Color iconColor;

    if (fileType.contains('image') || link.toLowerCase().endsWith('.jpg') ||
        link.toLowerCase().endsWith('.jpeg') || link.toLowerCase().endsWith('.png')) {
      icon = Icons.image;
      iconColor = Colors.blue[700]!;
    } else if (fileType.contains('pdf') || link.toLowerCase().endsWith('.pdf')) {
      icon = Icons.picture_as_pdf;
      iconColor = Colors.red[700]!;
    } else {
      icon = Icons.insert_drive_file;
      iconColor = Colors.grey[700]!;
    }

    String filename = link.split('/').last;
    if (filename.length > 35) {
      filename = '${filename.substring(0, 32)}...';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
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
          filename,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          fileType.isNotEmpty ? fileType : 'File',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: IconButton(
          onPressed: () => _openFile(fullUrl, fileType, filename),
          icon: const Icon(Icons.open_in_new),
          color: AppTheme.primaryColor,
          tooltip: 'Open',
        ),
      ),
    );
  }

  void _openFile(String url, String fileType, String title) {
    if (url.isEmpty) {
      _showSnackBar('File URL not available', isError: true);
      return;
    }

    if (fileType.contains('image') || url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') || url.toLowerCase().endsWith('.png')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerScreen(
            imageUrl: url,
            title: title,
          ),
        ),
      );
    } else if (fileType.contains('pdf') || url.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(
            pdfUrl: url,
            title: title,
          ),
        ),
      );
    } else {
      _showSnackBar('Opening: $title', isError: false);
    }
  }

  void _navigateToAddAttachment(Map<String, dynamic> annex, int annexNumber) async {
    // Check permission
    if (!InquiryPermissions.canAddAttachmentToAnnex(widget.inquiry)) {
      _showSnackBar('Only chairperson can add attachments', isError: true);
      return;
    }

    final annexId = int.tryParse((annex['id'] ?? annex['annex_id']).toString()) ?? 0;
    final annexTitle = annex['title']?.toString() ?? 'Annex $annexNumber';

    if (annexId == 0) {
      _showSnackBar('Invalid annex ID', isError: true);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAttachmentAnnexScreen(
          annexId: annexId,
          annexTitle: annexTitle,
          onAttachmentAdded: widget.onAnnexAdded,
        ),
      ),
    );

    if (result == true) {
      widget.onAnnexAdded();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canAddAnnex = InquiryPermissions.canAddAnnex(widget.inquiry);
    final bool canAddAttachment = InquiryPermissions.canAddAttachmentToAnnex(widget.inquiry);
    final bool canEditAnnex = InquiryPermissions.canEditAnnex(widget.inquiry);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.annexes.isEmpty)
            _emptyState('No annexes added yet')
          else
            ...widget.annexes.asMap().entries.map((entry) {
              final int annexNumber = entry.key + 1;
              final annex = entry.value as Map<String, dynamic>;
              return _annexItem(
                annex,
                annexNumber,
                canAddAttachment: canAddAttachment,
                canEditAnnex: canEditAnnex,
              );
            }).toList(),

          const SizedBox(height: 12),

          if (canAddAnnex)
            Center(
              child: OutlinedButton.icon(
                onPressed: _navigateToAddAnnex,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Annex'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
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

  Widget _annexItem(
      Map<String, dynamic> annex,
      int annexNumber, {
        required bool canAddAttachment,
        required bool canEditAnnex,
      }) {
    final String title = (annex['title'] ?? 'Untitled').toString();
    final List<dynamic> files = (annex['annex_files'] ?? []) as List<dynamic>;
    final bool hasFiles = files.isNotEmpty;
    final int fileCount = files.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasFiles
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasFiles
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasFiles ? Icons.folder_special : Icons.folder_outlined,
                color: hasFiles ? AppTheme.primaryColor : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Annex $annexNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFiles
                        ? '$fileCount ${fileCount == 1 ? 'file' : 'files'} attached'
                        : 'No files attached',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFiles
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight: hasFiles ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            if (hasFiles)
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _viewAnnexFiles(annex, annexNumber),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: Text(
                      fileCount > 1 ? 'View All' : 'View',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  ),
                  if (canAddAttachment) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18, color: AppTheme.primaryColor),
                      onPressed: () => _navigateToAddAttachment(annex, annexNumber),
                      tooltip: 'Add Attachment',
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else
              Row(
                children: [
                  if (canAddAttachment)
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddAttachment(annex, annexNumber),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Files', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                    ),
                  if (canEditAnnex) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18, color: AppTheme.primaryColor),
                      onPressed: () => widget.onEditAnnex(annex, annexNumber),
                      tooltip: 'Edit Annex',
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Image Viewer Screen (unchanged)
class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageViewerScreen({
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

// PDF Viewer Screen (unchanged)
class PDFViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PDFViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localFilePath;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int currentPage = 0;
  int totalPages = 0;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePDF();
  }

  Future<void> _downloadAndSavePDF() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      String fullUrl = widget.pdfUrl;
      if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
        final cleanPath = fullUrl.startsWith('/') ? fullUrl.substring(1) : fullUrl;
        fullUrl = 'https://cmit.sata.pk/$cleanPath';
      }

      debugPrint('Downloading PDF from: $fullUrl');

      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_annex_${DateTime.now().millisecondsSinceEpoch}.pdf');

        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            localFilePath = file.path;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PDF download error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Failed to load PDF: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16),
            ),
            if (totalPages > 0)
              Text(
                'Page ${currentPage + 1} of $totalPages',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load PDF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _downloadAndSavePDF,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (localFilePath != null) {
      return PDFView(
        filePath: localFilePath!,
        enableSwipe: true,
        swipeHorizontal: false, // Vertical scrolling is usually better on mobile
        autoSpacing: true,
        pageFling: false,
        onRender: (pages) {
          setState(() {
            totalPages = pages!;
          });
        },
        onError: (error) {
          setState(() {
            hasError = true;
            errorMessage = error.toString();
          });
        },
        onPageError: (page, error) {
          debugPrint('$page: ${error.toString()}');
        },
        onViewCreated: (PDFViewController pdfViewController) {
          // You can use the controller to interact with the PDF
        },
        onPageChanged: (int? page, int? total) {
          setState(() {
            currentPage = page!;
          });
        },
      );
    }
    
    return const SizedBox.shrink();
  }
}