import 'package:flutter/material.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/inquiries/view/permissions.dart';
import 'package:cmit/core/complete_inquiry_service.dart'; // ✅ Correct import

class InquiryHeaderSection extends StatelessWidget {
  final AssignToMeModel inquiry;
  final VoidCallback? onFinalizeSuccess;

  const InquiryHeaderSection({
    super.key,
    required this.inquiry,
    this.onFinalizeSuccess,
  });

  /// Show confirmation dialog and handle API call
  Future<void> _showFinalizeConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              const Text(
                'Finalize Inquiry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to finalize this inquiry?\n\nThis action will mark the inquiry as completed and cannot be undone.',
            style: TextStyle(fontSize: 15, height: 1.5, color: AppTheme.textSecondary),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Confirm Finalize',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    // If user confirmed
    if (confirmed == true && context.mounted) {
      _handleFinalize(context);
    }
  }

  /// Call API to finalize the inquiry
  Future<void> _handleFinalize(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // ✅ Call the service with correct method
    final result = await CompleteInquiryService.completeInquiry(
      inquiryId: inquiry.id,
    );

    // Dismiss loading
    if (context.mounted) {
      Navigator.of(context).pop();

      // Show result message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Unknown response'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,

          behavior: SnackBarBehavior.floating,
        ),
      );

      // Trigger success callback
      if (result['success'] && onFinalizeSuccess != null) {
        onFinalizeSuccess!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canFinalize = InquiryPermissions.canFinalizeInquiry(inquiry);
    print("DEBUG: InquiryHeaderSection build. canFinalize: $canFinalize, userRole: ${inquiry.userRole}");

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Badges & Finalize Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      text: inquiry.statusText,
                      color: inquiry.statusColor,
                    ),
                    _PriorityChip(
                      text: inquiry.priorityText,
                      color: inquiry.priorityColor,
                    ),
                  ],
                ),
              ),
              if (canFinalize)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _FinalizeButton(
                    onPressed: () {
                        print("DEBUG: Finalize button onPressed triggered");
                        _showFinalizeConfirmation(context);
                    },
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Main Title
          Text(
            inquiry.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),

          // Metadata Grid
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _MetaRow(
                  icon: Icons.category_outlined,
                  label: "Type",
                  value: inquiry.inquiryType,
                ),
                if (inquiry.timeFrame.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _MetaRow(
                    icon: Icons.access_time_rounded,
                    label: "Timeframe",
                    value: inquiry.timeFrame,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                _MetaRow(
                  icon: Icons.calendar_today_rounded,
                  label: "Created",
                  value: inquiry.formattedDate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Private Widgets

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String text;
  final Color color;

  const _PriorityChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _FinalizeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FinalizeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        print("DEBUG: _FinalizeButton InkWell tapped");
        onPressed();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "Finalize",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}