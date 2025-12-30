import 'dart:io';
import 'dart:convert';
import 'package:cmit/features/offline/services/offline_service.dart';
import 'package:cmit/core/finding_inquiry_service.dart';

class OfflineSyncService {
  /// Sync all offline data to backend (findings only)
  static Future<Map<String, dynamic>> syncAllData() async {
    int successCount = 0;
    int failCount = 0;
    List<String> errors = [];

    // Check internet
    final hasInternet = await OfflineService.hasInternet();
    if (!hasInternet) {
      return {
        'success': false,
        'message': 'No internet connection',
        'synced': 0,
        'failed': 0,
      };
    }

    // Sync findings only
    final findingResult = await _syncFindings();
    successCount += findingResult['success_count'] as int;
    failCount += findingResult['fail_count'] as int;
    if (findingResult['errors'] != null) {
      errors.addAll(findingResult['errors'] as List<String>);
    }

    // Build detailed message
    String message;
    if (failCount == 0 && successCount > 0) {
      message = 'Successfully synced $successCount finding${successCount > 1 ? 's' : ''}';
    } else if (failCount > 0 && successCount > 0) {
      message = 'Synced $successCount, failed $failCount finding${failCount > 1 ? 's' : ''}';
    } else if (failCount > 0) {
      message = 'Failed to sync $failCount finding${failCount > 1 ? 's' : ''}';
    } else {
      message = 'No findings to sync';
    }

    return {
      'success': failCount == 0,
      'message': message,
      'synced': successCount,
      'failed': failCount,
      'errors': errors,
    };
  }

  /// Sync findings to server
  static Future<Map<String, dynamic>> _syncFindings() async {
    int successCount = 0;
    int failCount = 0;
    List<String> errors = [];

    try {
      final unsyncedFindings = await OfflineService.getUnsyncedFindings();

      if (unsyncedFindings.isEmpty) {
        return {
          'success_count': 0,
          'fail_count': 0,
          'errors': <String>[],
        };
      }

      for (var finding in unsyncedFindings) {
        try {
          final visitId = finding['visit_id'].toString();
          final offlineFindingId = finding['id'].toString();

          // Parse visit ID (should be a server-generated ID from online visits)
          final serverVisitId = int.tryParse(visitId);

          if (serverVisitId == null) {
            failCount++;
            errors.add('Finding skipped: Invalid visit ID ($visitId)');
            continue;
          }

          // Process images if any
          List<String> networksFiles = [];
          if (finding['images'] != null) {
            final List<dynamic> imagePaths = finding['images'] as List<dynamic>;
            for (var path in imagePaths) {
              try {
                final file = File(path.toString());
                if (await file.exists()) {
                  final bytes = await file.readAsBytes();
                  final base64String = base64Encode(bytes);

                  // Determine mime type
                  final extension = path.toString().split('.').last.toLowerCase();
                  String mimeType = 'image/jpeg';
                  if (extension == 'png') {
                    mimeType = 'image/png';
                  } else if (extension == 'gif') {
                    mimeType = 'image/gif';
                  }

                  networksFiles.add('data:$mimeType;base64,$base64String');
                }
              } catch (e) {
                print('Error processing offline image $path: $e');
              }
            }
          }

          // Call API to store finding
          final result = await FindingInquiryService.storeFinding(
            findings: finding['findings'],
            visitId: serverVisitId,
            files: networksFiles.isNotEmpty ? networksFiles : null,
          );

          if (result['success'] == true) {
            // Mark as synced and delete
            await OfflineService.markFindingSynced(offlineFindingId);
            await OfflineService.deleteSyncedFinding(offlineFindingId);

            // Clean up local image files
            if (finding['images'] != null) {
              final List<dynamic> imagePaths = finding['images'] as List<dynamic>;
              for (var path in imagePaths) {
                try {
                  final file = File(path.toString());
                  if (await file.exists()) {
                    await file.delete();
                  }
                } catch (e) {
                  print('Error wiping offline image $path: $e');
                }
              }
            }

            successCount++;
          } else {
            failCount++;
            final errorMsg = result['message'] ?? 'Unknown error';
            errors.add('Finding sync failed: $errorMsg');
          }
        } catch (e) {
          failCount++;
          errors.add('Finding sync error: ${e.toString()}');
        }
      }
    } catch (e) {
      errors.add('Failed to get unsynced findings: ${e.toString()}');
    }

    return {
      'success_count': successCount,
      'fail_count': failCount,
      'errors': errors,
    };
  }

  /// Auto-sync when internet is restored
  static Future<void> autoSyncOnConnection() async {
    final hasInternet = await OfflineService.hasInternet();
    if (!hasInternet) return;

    final pendingCount = await OfflineService.getPendingSyncCount();
    if (pendingCount > 0) {
      await syncAllData();
    }
  }

  /// Get detailed sync status (findings only)
  static Future<Map<String, dynamic>> getSyncStatus() async {
    final hasInternet = await OfflineService.hasInternet();
    final pendingCount = await OfflineService.getPendingSyncCount();
    final unsyncedFindings = await OfflineService.getUnsyncedFindings();

    return {
      'online': hasInternet,
      'pending_count': pendingCount,
      'pending_findings': unsyncedFindings.length,
    };
  }
}