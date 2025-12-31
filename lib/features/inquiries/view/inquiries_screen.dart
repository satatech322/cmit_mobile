// lib/features/inquiries/view/inquiries_screen.dart - WITH OFFLINE NAVIGATION
import 'package:flutter/material.dart';
import 'package:cmit/config/theme.dart';
import 'package:cmit/core/assign_to_me.dart';
import 'package:cmit/features/inquiries/view/inquiry_card.dart';
import 'package:cmit/features/inquiries/view/inquiry_details_screen.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/offline/services/offline_service.dart';
import 'package:cmit/features/offline/services/inquiry_cache_service.dart';
import 'package:cmit/features/offline/widgets/offline_indicator.dart';
import 'package:cmit/features/offline/view/offline_details_screen.dart';
import 'package:cmit/features/offline/view/offline_inquiry_detail_screen.dart';

class InquiriesScreen extends StatefulWidget {
  const InquiriesScreen({super.key});

  @override
  State<InquiriesScreen> createState() => _InquiriesScreenState();
}

class _InquiriesScreenState extends State<InquiriesScreen> {
  List<AssignToMeModel> _inquiries = [];
  List<AssignToMeModel> _filtered = [];
  bool _isLoading = true;
  bool _isOnline = true;
  bool _isFromCache = false;
  String _error = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndLoad();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Check connectivity and load data accordingly
  Future<void> _checkConnectivityAndLoad() async {
    final hasInternet = await OfflineService.hasInternet();

    setState(() {
      _isOnline = hasInternet;
      _isLoading = true;
    });

    if (hasInternet) {
      await _loadFromAPI();
    } else {
      await _loadFromCache();
    }
  }

  /// Load data from API
  Future<void> _loadFromAPI() async {
    try {
      final result = await AssignToMe.getAssignedInquiries();

      if (!mounted) return;

      if (result['success'] == true) {
        final inquiries = result['inquiries'] as List<AssignToMeModel>;

        // Cache the fresh data
        await InquiryCacheService.cacheInquiries(inquiries);

        setState(() {
          _isLoading = false;
          _isFromCache = false;
          _inquiries = inquiries;
          _filtered = List.from(_inquiries);
          _error = '';
        });
      } else {
        // API error - fallback to cache
        await _loadFromCache();
      }
    } catch (e) {
      // Network error - fallback to cache
      if (!mounted) return;
      await _loadFromCache();
    }
  }

  /// Load data from cache
  Future<void> _loadFromCache() async {
    try {
      final cachedInquiries = await InquiryCacheService.getCachedInquiries();

      if (!mounted) return;

      if (cachedInquiries != null && cachedInquiries.isNotEmpty) {
        setState(() {
          _isLoading = false;
          _isFromCache = true;
          _inquiries = cachedInquiries;
          _filtered = List.from(_inquiries);
          _error = '';
        });
      } else {
        // No cache available
        setState(() {
          _isLoading = false;
          _isFromCache = false;
          _error = _isOnline
              ? 'Failed to load inquiries'
              : 'No offline data available. Please connect to internet.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isFromCache = false;
        _error = 'Failed to load data';
      });
    }
  }

  /// Show cache information dialog
  Future<void> _showCacheInfo() async {
    if (!mounted) return;

    final metadata = await InquiryCacheService.getCacheMetadata();
    final ageHours = metadata['cache_age_hours'] as int?;

    String message = 'Viewing cached data';
    if (ageHours != null) {
      if (ageHours < 1) {
        message = 'Cache is less than 1 hour old';
      } else if (ageHours == 1) {
        message = 'Cache is 1 hour old';
      } else if (ageHours < 24) {
        message = 'Cache is $ageHours hours old';
      } else {
        final days = (ageHours / 24).floor();
        message = 'Cache is $days ${days == 1 ? 'day' : 'days'} old';
      }
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 24),
              SizedBox(width: 12),
              Text('Cache Information'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 12),
              Text(
                'You are viewing offline data. Connect to internet to get the latest updates.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        ),
      );
    }
  }

  /// Manual refresh
  Future<void> _loadInquiries() async {
    final hasInternet = await OfflineService.hasInternet();

    setState(() => _isOnline = hasInternet);

    if (hasInternet) {
      await _loadFromAPI();
    } else {
      await _loadFromCache();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No internet connection. Showing cached data.'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _filter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? List.from(_inquiries)
          : _inquiries.where((i) {
        return i.title.toLowerCase().contains(query) ||
            i.department.toLowerCase().contains(query) ||
            i.initiator.toLowerCase().contains(query) ||
            i.assignedTo.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _navigateToOfflineDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OfflineDetailsScreen()),
    ).then((_) => _checkConnectivityAndLoad());
  }

  Future<void> _navigateToInquiryDetails(AssignToMeModel inquiry) async {
    final hasInternet = await OfflineService.hasInternet();
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => hasInternet
            ? InquiryDetailsScreen(inquiry: inquiry)
            : OfflineInquiryDetailsScreen(inquiry: inquiry),
      ),
    );

    if (result == true) {
      _loadInquiries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildCustomHeader(),
            
            // Offline Indicator
            const OfflineIndicator(),
        
            if (!_isOnline && _isFromCache)
              InkWell(
                onTap: _navigateToOfflineDetails,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off, size: 18, color: AppTheme.secondaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offline Mode',
                              style: TextStyle(
                                fontSize: 13, 
                                color: AppTheme.secondaryColor, 
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Viewing cached data. Tap for details.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.secondaryColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: AppTheme.secondaryColor),
                    ],
                  ),
                ),
              ),
            
            // Main Content Area
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInquiries,
                color: AppTheme.primaryColor,
                backgroundColor: Colors.white,
                child: Column(
                  children: [
                    // Search Bar Section
                     Padding(
                       padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                       child: _buildPremiumSearchBar(),
                     ),
                    
                    // List
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                          : _error.isNotEmpty
                            ? _buildErrorState()
                            : _filtered.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: _filtered.length,
                                  itemBuilder: (context, i) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: InquiryCard(
                                        inquiry: _filtered[i],
                                        onTap: () => _navigateToInquiryDetails(_filtered[i]),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "My Inquiries",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          
          Row(
            children: [
              if (_isFromCache)
                _buildHeaderInfoButton(
                  Icons.info_outline,
                  AppTheme.primaryColor,
                  _showCacheInfo,
                ),
              const SizedBox(width: 8),
              _buildHeaderActionButton(
                Icons.tune_rounded,
                Colors.black87,
                () {
                   // Filter or Settings action
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OfflineDetailsScreen()),
                  ).then((_) => _checkConnectivityAndLoad());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF014323), Color(0xFF0F5132)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF014323).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

    Widget _buildHeaderInfoButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildPremiumSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search inquiries...",
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOnline ? Icons.error_outline : Icons.cloud_off_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error,
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInquiries,
              child: Text(_isOnline ? 'Retry' : 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'No inquiries assigned' : 'No inquiries found',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}