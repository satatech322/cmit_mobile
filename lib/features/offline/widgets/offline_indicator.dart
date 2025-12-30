// lib/features/offline/widgets/offline_indicator.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cmit/features/offline/services/offline_service.dart';
import 'package:cmit/features/offline/services/offline_sync_service.dart';

class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;
  int _pendingCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadPendingCount();
    _listenToConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final hasInternet = await OfflineService.hasInternet();
    if (mounted) {
      setState(() => _isOnline = hasInternet);
    }
  }

  Future<void> _loadPendingCount() async {
    final count = await OfflineService.getPendingSyncCount();
    if (mounted) {
      setState(() => _pendingCount = count);
    }
  }

  void _listenToConnectivity() {
    OfflineService.connectivityStream.listen((results) async {
      // FIX: connectivity_plus now returns List<ConnectivityResult>
      final isOnline = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);

      // Force refresh pending count to avoid stale state
      final currentPending = await OfflineService.getPendingSyncCount();

      if (mounted) {
        setState(() {
          _isOnline = isOnline;
          _pendingCount = currentPending;
        });
      }

      // Auto-sync when connection restored
      if (isOnline && currentPending > 0 && !_isSyncing) {
        await _syncData();
      }
    });
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    final result = await OfflineSyncService.syncAllData();

    if (mounted) {
      setState(() => _isSyncing = false);
      await _loadPendingCount();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Sync completed'),
          backgroundColor: result['success'] == true
              ? const Color(0xFF014323)
              : Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline && _pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isOnline
            ? const Color(0xFFE8F5E9) // Light green for pending sync
            : Colors.red.shade50,      // Red for no connection
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isOnline
              ? const Color(0xFF014323).withOpacity(0.3)
              : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isOnline ? Icons.cloud_upload : Icons.cloud_off,
            size: 20,
            color: _isOnline
                ? const Color(0xFF014323)
                : Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isOnline ? 'Pending Sync' : 'No Internet Connection',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _isOnline
                        ? const Color(0xFF014323)
                        : Colors.red.shade900,
                  ),
                ),
                if (_pendingCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$_pendingCount finding${_pendingCount > 1 ? 's' : ''} pending sync',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isOnline
                          ? const Color(0xFF014323).withOpacity(0.7)
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isOnline && _pendingCount > 0)
            TextButton(
              onPressed: _isSyncing ? null : _syncData,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: _isSyncing
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF014323),
                  ),
                ),
              )
                  : const Text(
                'Sync Now',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF014323),
                ),
              ),
            ),
        ],
      ),
    );
  }
}