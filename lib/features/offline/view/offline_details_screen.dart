// lib/features/offline/view/offline_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/core/widgets/app_dialog.dart';
import 'package:cmit/features/offline/services/offline_service.dart';
import 'package:cmit/features/offline/services/inquiry_cache_service.dart';

class OfflineDetailsScreen extends StatefulWidget {
  const OfflineDetailsScreen({super.key});

  @override
  State<OfflineDetailsScreen> createState() => _OfflineDetailsScreenState();
}

class _OfflineDetailsScreenState extends State<OfflineDetailsScreen> {
  bool _isOnline = true;
  bool _isLoading = true;
  bool _isSyncing = false;

  // Cache info
  int _cachedInquiriesCount = 0;
  String _lastCacheUpdate = 'Never';
  int _cacheAgeHours = 0;
  double _cacheSizeMB = 0.0;

  // Pending operations
  int _pendingFindings = 0;

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    setState(() => _isLoading = true);

    try {
      // Check connectivity
      final hasInternet = await OfflineService.hasInternet();

      // Get cache metadata
      final metadata = await InquiryCacheService.getCacheMetadata();
      final cachedInquiries = await InquiryCacheService.getCachedInquiries();

      // Get sync stats
      final syncStats = await OfflineService.getSyncStats();

      if (!mounted) return;

      setState(() {
        _isOnline = hasInternet;
        _cachedInquiriesCount = cachedInquiries?.length ?? 0;
        _lastCacheUpdate = metadata['last_cache_time'] ?? 'Never';
        _cacheAgeHours = metadata['cache_age_hours'] ?? 0;
        _cacheSizeMB = (metadata['cache_size_bytes'] ?? 0) / (1024 * 1024);

        // Only findings are tracked
        _pendingFindings = syncStats['pending_findings'] ?? 0;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load offline data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncPendingChanges() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync while offline'),
          backgroundColor: Color(0xFF014323),
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      // Get unsynced findings
      final unsyncedFindings = await OfflineService.getUnsyncedFindings();

      if (unsyncedFindings.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No pending changes to sync'),
            backgroundColor: Color(0xFF014323),
          ),
        );

        setState(() => _isSyncing = false);
        return;
      }

      int syncedCount = 0;
      int failedCount = 0;

      // Sync each finding
      for (var finding in unsyncedFindings) {
        try {
          // TODO: Call your API to sync the finding
          // final result = await YourAPI.syncFinding(finding);

          // For now, simulate success
          await Future.delayed(const Duration(milliseconds: 500));

          // Mark as synced
          await OfflineService.markFindingSynced(finding['id']);
          syncedCount++;
        } catch (e) {
          failedCount++;
          print('Failed to sync finding ${finding['id']}: $e');
        }
      }

      if (!mounted) return;

      if (syncedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced $syncedCount ${syncedCount == 1 ? 'finding' : 'findings'} successfully'
                  '${failedCount > 0 ? ' ($failedCount failed)' : ''}',
            ),
            backgroundColor: failedCount > 0 ? const Color(0xFF014323) : const Color(0xFF014323),
          ),
        );

        await _loadOfflineData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync findings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await AppDialog.show(
      context: context,
      icon: Icons.delete_outline_rounded,
      iconColor: AppTheme.errorColor,
      title: 'Clear Cache',
      message: 'Are you sure you want to clear all cached data? This will remove offline access until you reconnect.',
      confirmText: 'Clear Cache',
      confirmButtonColor: AppTheme.errorColor,
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      // Clear cached inquiries
      await InquiryCacheService.clearCache();
      
      // Clear pending sync data (findings)
      await OfflineService.clearAllOfflineData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache and pending data cleared successfully'),
          backgroundColor: Color(0xFF014323),
        ),
      );

      await _loadOfflineData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to clear cache: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCacheAge() {
    if (_cacheAgeHours == 0) return 'Just now';
    if (_cacheAgeHours < 1) return 'Less than 1 hour';
    if (_cacheAgeHours == 1) return '1 hour ago';
    if (_cacheAgeHours < 24) return '$_cacheAgeHours hours ago';

    final days = (_cacheAgeHours / 24).floor();
    return '$days ${days == 1 ? 'day' : 'days'} ago';
  }

  int get _totalPending => _pendingFindings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: const Color(0xFF1A1A1A)),
        title: const Text(
          'Offline Center',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            fontSize: 20
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF014323),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadOfflineData,
        color: const Color(0xFF014323),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Connection Status Hero Card
              _buildConnectionHeroCard(),
              
              const SizedBox(height: 24),

              // 2. Pending Sync Section (if any)
              if (_totalPending > 0) ...[
                _buildSectionTitle("Pending Synchronization"),
                const SizedBox(height: 12),
                _buildPendingSyncCard(),
                const SizedBox(height: 24),
              ],

              // 3. Cache Statistics
              _buildSectionTitle("Storage & Cache"),
              const SizedBox(height: 12),
              _buildCacheGrid(),

              const SizedBox(height: 24),

              // 4. Actions
              _buildSectionTitle("Management"),
              const SizedBox(height: 12),
               _buildActionButtons(),

              const SizedBox(height: 32),
              
              // 5. Info Footer
               Center(
                 child: Text(
                  'Changes made offline will auto-sync when connected.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                               ),
               ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF666666),
        letterSpacing: 0.5,
      )
    );
  }

  Widget _buildConnectionHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF014323),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF014323).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isOnline ? 'You are Online' : 'You are Offline',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isOnline
                ? 'App is fully synchronized'
                : 'Viewing local cached data',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSyncCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sync_problem_rounded, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_totalPending Pending Changes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Data waiting to be uploaded',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          InkWell(
            onTap: _isSyncing || !_isOnline ? null : _syncPendingChanges,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: _isSyncing
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF014323))
                  )
                : Text(
                  _isOnline ? "Sync Now" : "Connect internet to sync",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isOnline ? const Color(0xFF014323) : Colors.grey,
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: 'Inquiries',
            value: '$_cachedInquiriesCount',
            icon: Icons.assignment_outlined,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            title: 'Storage',
            value: '${_cacheSizeMB.toStringAsFixed(1)} MB',
            icon: Icons.sd_storage_outlined,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 2),
           Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildListButton(
          icon: Icons.refresh_rounded,
          title: "Refresh Cache",
          subtitle: "Update local data from server",
          color: const Color(0xFF014323),
          onTap: _isOnline ? _loadOfflineData : null,
        ),
        const SizedBox(height: 12),
        _buildListButton(
          icon: Icons.delete_outline_rounded,
          title: "Clear Storage",
          subtitle: "Remove all cached data",
          color: Colors.red,
          onTap: _clearCache,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildListButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final isDisabled = onTap == null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDisabled 
                    ? Colors.grey.shade100 
                    : (isDestructive ? Colors.red.shade50 : color.withOpacity(0.1)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDisabled ? Colors.grey.shade400 : color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? Colors.grey.shade400 : const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
