// lib/features/offline/services/offline_service.dart
// UPDATED: Removed all visit offline functionality - only findings remain
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';

class OfflineService {
  static const String _keyOfflineFindings = 'offline_findings';

  // Check internet connectivity
  static Future<bool> hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    // Handle List<ConnectivityResult>
    return connectivityResult.isNotEmpty &&
        !connectivityResult.contains(ConnectivityResult.none);
  }

  // Listen to connectivity changes
  static Stream<List<ConnectivityResult>> get connectivityStream {
    return Connectivity().onConnectivityChanged;
  }

  // OFFLINE FINDINGS MANAGEMENT ONLY

  /// Save finding offline
  static Future<bool> saveFindingOffline({
    required int inquiryId,
    required String visitId,
    required String findings,
    List<String>? images,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get persistent directory
      final directory = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${directory.path}/offline_images');
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }

      List<String> persistentImagePaths = [];

      // Process and move images to persistent storage
      if (images != null) {
        for (String sourcePath in images) {
          try {
            final sourceFile = File(sourcePath);
            if (await sourceFile.exists()) {
              final fileName = sourcePath.split(Platform.pathSeparator).last;
              final newPath = '${offlineDir.path}/$fileName';
              await sourceFile.copy(newPath);
              persistentImagePaths.add(newPath);
            }
          } catch (e) {
            print('Error copying image: $e');
          }
        }
      }

      // Get existing offline findings
      final existingData = prefs.getString(_keyOfflineFindings);
      List<Map<String, dynamic>> offlineFindings = [];

      if (existingData != null) {
        offlineFindings = List<Map<String, dynamic>>.from(
            jsonDecode(existingData) as List
        );
      }

      // Create new finding entry
      final newFinding = {
        'id': 'offline_${DateTime.now().millisecondsSinceEpoch}',
        'inquiry_id': inquiryId,
        'visit_id': visitId,
        'findings': findings,
        'images': persistentImagePaths, // Store PERSISTENT paths
        'timestamp': DateTime.now().toIso8601String(),
        'synced': false,
      };

      offlineFindings.add(newFinding);

      // Save back to storage
      await prefs.setString(_keyOfflineFindings, jsonEncode(offlineFindings));
      return true;
    } catch (e) {
      print('Error saving finding offline: $e');
      return false;
    }
  }

  /// Get offline findings for a visit
  static Future<List<Map<String, dynamic>>> getOfflineFindings(String visitId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyOfflineFindings);

      if (data == null) return [];

      final List<Map<String, dynamic>> allFindings =
      List<Map<String, dynamic>>.from(jsonDecode(data) as List);

      // Filter by visit ID
      return allFindings
          .where((f) => f['visit_id'] == visitId && f['synced'] != true)
          .toList();
    } catch (e) {
      print('Error getting offline findings: $e');
      return [];
    }
  }

  /// Get all unsynced findings
  static Future<List<Map<String, dynamic>>> getUnsyncedFindings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyOfflineFindings);

      if (data == null) return [];

      final List<Map<String, dynamic>> allFindings =
      List<Map<String, dynamic>>.from(jsonDecode(data) as List);

      return allFindings.where((f) => f['synced'] != true).toList();
    } catch (e) {
      print('Error getting unsynced findings: $e');
      return [];
    }
  }

  /// Mark finding as synced
  static Future<bool> markFindingSynced(String offlineId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyOfflineFindings);

      if (data == null) return false;

      List<Map<String, dynamic>> findings =
      List<Map<String, dynamic>>.from(jsonDecode(data) as List);

      // Find and update the finding
      for (var finding in findings) {
        if (finding['id'] == offlineId) {
          finding['synced'] = true;
          finding['synced_at'] = DateTime.now().toIso8601String();
          break;
        }
      }

      // Save back
      await prefs.setString(_keyOfflineFindings, jsonEncode(findings));
      return true;
    } catch (e) {
      print('Error marking finding synced: $e');
      return false;
    }
  }

  /// Delete synced finding
  static Future<bool> deleteSyncedFinding(String offlineId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyOfflineFindings);

      if (data == null) return false;

      List<Map<String, dynamic>> findings =
      List<Map<String, dynamic>>.from(jsonDecode(data) as List);

      // Remove the finding
      findings.removeWhere((f) => f['id'] == offlineId);

      // Save back
      await prefs.setString(_keyOfflineFindings, jsonEncode(findings));
      return true;
    } catch (e) {
      print('Error deleting synced finding: $e');
      return false;
    }
  }

  /// Get pending sync count (findings only)
  static Future<int> getPendingSyncCount() async {
    final findings = await getUnsyncedFindings();
    return findings.length;
  }

  /// Clear all offline data (findings only)
  static Future<bool> clearAllOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOfflineFindings);
      return true;
    } catch (e) {
      print('Error clearing offline data: $e');
      return false;
    }
  }

  /// Get sync statistics (findings only)
  static Future<Map<String, int>> getSyncStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Count findings only
      final findingsData = prefs.getString(_keyOfflineFindings);
      int totalFindings = 0;
      int syncedFindings = 0;

      if (findingsData != null) {
        final findings = List<Map<String, dynamic>>.from(jsonDecode(findingsData) as List);
        totalFindings = findings.length;
        syncedFindings = findings.where((f) => f['synced'] == true).length;
      }

      return {
        'total_findings': totalFindings,
        'synced_findings': syncedFindings,
        'pending_findings': totalFindings - syncedFindings,
      };
    } catch (e) {
      print('Error getting sync stats: $e');
      return {};
    }
  }
}