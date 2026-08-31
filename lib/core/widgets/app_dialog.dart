// lib/core/widgets/app_dialog.dart
import 'package:flutter/material.dart';
import 'package:cmit/config/theme.dart';

class AppDialog extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String title;
  final String? message;
  final Widget? content;
  final String confirmText;
  final VoidCallback? onConfirm;
  final Color? confirmButtonColor;
  final String? cancelText;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const AppDialog({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    required this.title,
    this.message,
    this.content,
    this.confirmText = 'OK',
    this.onConfirm,
    this.confirmButtonColor,
    this.cancelText,
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    required String title,
    String? message,
    Widget? content,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
    Color? confirmButtonColor,
    String? cancelText,
    VoidCallback? onCancel,
    bool isDestructive = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AppDialog(
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        title: title,
        message: message,
        content: content,
        confirmText: confirmText,
        onConfirm: onConfirm != null
            ? () {
                Navigator.of(ctx).pop(true);
                onConfirm();
              }
            : () => Navigator.of(ctx).pop(true),
        confirmButtonColor: confirmButtonColor,
        cancelText: cancelText,
        onCancel: onCancel != null
            ? () {
                Navigator.of(ctx).pop(false);
                onCancel();
              }
            : () => Navigator.of(ctx).pop(false),
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ??
        (isDestructive ? AppTheme.errorColor : AppTheme.primaryColor);
    final effectiveIconBgColor = iconBackgroundColor ??
        effectiveIconColor.withOpacity(0.1);
    final effectiveConfirmColor = confirmButtonColor ??
        (isDestructive ? AppTheme.errorColor : AppTheme.primaryColor);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row with Icon and Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: effectiveIconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: effectiveIconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content Area
            if (content != null)
              content!
            else if (message != null)
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),

            const SizedBox(height: 24),

            // Actions Row
            Row(
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: TextButton(
                      onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        backgroundColor: Colors.grey.shade50,
                        foregroundColor: AppTheme.textSecondary,
                      ),
                      child: Text(
                        cancelText!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: effectiveConfirmColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
