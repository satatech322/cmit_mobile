// lib/features/offline/widgets/offline_indicator.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cmit/features/offline/services/offline_service.dart';
import 'package:cmit/features/offline/services/offline_sync_service.dart';

class OfflineIndicator extends StatefulWidget {
  final EdgeInsetsGeometry? margin;

  const OfflineIndicator({
    super.key,
    this.margin,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;
  int _pendingCount = 0;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadPendingCount();
    _listenToConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
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
    _connectivitySubscription = OfflineService.connectivityStream.listen((results) async {
      final isOnline = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);

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
      if (!mounted) return;

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
    // If online and no pending items to sync, hide completely
    if (_isOnline && _pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final isOffline = !_isOnline;

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOffline
            ? const Color(0xFFFFFBEB) // Amber-50
            : const Color(0xFFE8F5E9), // Light green
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOffline
              ? const Color(0xFFFDE68A) // Amber-200
              : const Color(0xFF014323).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOffline
                  ? const Color(0xFFFDE68A).withOpacity(0.5)
                  : const Color(0xFF014323).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.cloud_upload_rounded,
              size: 18,
              color: isOffline
                  ? const Color(0xFFB45309) // Amber-700
                  : const Color(0xFF014323),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOffline ? 'You are in offline mode' : 'Pending Sync',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isOffline
                        ? const Color(0xFF92400E) // Amber-800
                        : const Color(0xFF014323),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOffline
                      ? (_pendingCount > 0
                          ? '$_pendingCount finding${_pendingCount > 1 ? 's' : ''} pending sync • Viewing cached data'
                          : 'Viewing cached data. Changes will sync when online.')
                      : '$_pendingCount finding${_pendingCount > 1 ? 's' : ''} ready to sync to server',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isOffline
                        ? const Color(0xFFB45309).withOpacity(0.9)
                        : const Color(0xFF014323).withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isOffline && _pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: TextButton(
                onPressed: _isSyncing ? null : _syncData,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF014323),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Sync Now',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}