import 'package:flutter/material.dart';
import 'package:cmit/features/inquiries/view/inquiry_details_screen.dart';
import 'package:cmit/core/inquiry_statistics_service.dart';
import 'package:cmit/features/home/model/inquiry_statistics_model.dart';
import 'package:cmit/core/assign_to_me.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/offline/services/offline_service.dart';
import 'package:cmit/features/offline/view/offline_inquiry_detail_screen.dart';

class HomeTopSection extends StatefulWidget {
  const HomeTopSection({super.key});

  @override
  State<HomeTopSection> createState() => _HomeTopSectionState();
}

class _HomeTopSectionState extends State<HomeTopSection> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  // Recent inquiries from API
  List<AssignToMeModel> inquiries = [];
  List<AssignToMeModel> filteredInquiries = [];
  bool isLoadingInquiries = true;
  String inquiriesError = '';

  // Statistics state
  int totalInquiries = 0;
  int pendingInquiries = 0;
  int completedInquiries = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterInquiries);
    _loadData(); // Initial load
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterInquiries);
    _searchController.dispose();
    super.dispose();
  }

  /// Combined load function - loads both statistics and inquiries
  Future<void> _loadData() async {
    await Future.wait([
      _loadStatistics(),
      _loadRecentInquiries(),
    ]);
  }

  /// Combined refresh function - called on pull-to-refresh
  Future<void> _onRefresh() async {
    await _loadData();
  }

  /// Load statistics from API
  Future<void> _loadStatistics() async {
    setState(() {
      isLoadingStats = true;
    });

    final result = await InquiryStatisticsService.getInquiryStatistics();

    if (mounted) {
      if (result['success'] == true) {
        final InquiryStatisticsModel stats = result['data'];
        setState(() {
          totalInquiries = stats.total;
          pendingInquiries = stats.pending;
          completedInquiries = stats.completed;
          isLoadingStats = false;
        });
      } else {
        setState(() {
          totalInquiries = 0;
          pendingInquiries = 0;
          completedInquiries = 0;
          isLoadingStats = false;
        });
      }
    }
  }

  /// Load recent 4 inquiries from API
  Future<void> _loadRecentInquiries() async {
    setState(() {
      isLoadingInquiries = true;
      inquiriesError = '';
    });

    try {
      final result = await AssignToMe.getAssignedInquiries()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return {
            'success': false,
            'message': 'Request timed out. Please try again.',
          };
        },
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final allInquiries = result['inquiries'] as List<AssignToMeModel>;

        // Take only the first 4 inquiries
        final recentInquiries = allInquiries.take(4).toList();

        setState(() {
          inquiries = recentInquiries;
          filteredInquiries = List.from(inquiries);
          isLoadingInquiries = false;
          inquiriesError = '';
        });
      } else {
        // API returned error
        setState(() {
          inquiries = [];
          filteredInquiries = [];
          isLoadingInquiries = false;
          inquiriesError = result['message']?.toString() ?? 'Failed to load inquiries';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        inquiries = [];
        filteredInquiries = [];
        isLoadingInquiries = false;
        inquiriesError = 'Unable to load inquiries';
      });
    }
  }

  void _filterInquiries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredInquiries = inquiries.where((inquiry) {
        return inquiry.title.toLowerCase().contains(query) ||
            inquiry.department.toLowerCase().contains(query) ||
            inquiry.initiator.toLowerCase().contains(query) ||
            inquiry.assignedTo.toLowerCase().contains(query);
      }).toList();
    });
  }

  /// Navigate to inquiry details - checks online status
  Future<void> _navigateToInquiryDetails(AssignToMeModel inquiry) async {
    final hasInternet = await OfflineService.hasInternet();

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => hasInternet
            ? InquiryDetailsScreen(inquiry: inquiry) // Online: regular screen
            : OfflineInquiryDetailsScreen(inquiry: inquiry), // Offline: read-only screen
      ),
    );

    // Refresh if changes were made (only possible when online)
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _onRefresh,
      color: const Color(0xFF379E4B),
      backgroundColor: Colors.white,
      strokeWidth: 3.0,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Stats Row: Total | Pending | Completed
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      isLoadingStats ? "-" : totalInquiries.toString(),
                      "Total",
                      Colors.green[100]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      isLoadingStats ? "-" : pendingInquiries.toString(),
                      "Pending",
                      Colors.orange[100]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      isLoadingStats ? "-" : completedInquiries.toString(),
                      "Completed",
                      Colors.grey[300]!,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            /// Search Bar
            _buildSearchBar(context),
            const SizedBox(height: 20),

            /// Recent Inquiries Title
            const Text(
              "Recent Inquiries",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            /// Loading or Inquiry Cards
            if (isLoadingInquiries)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF379E4B),
                  ),
                ),
              )
            else if (inquiriesError.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        inquiriesError,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadRecentInquiries,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF379E4B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (filteredInquiries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No recent inquiries'
                              : 'No inquiries found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredInquiries.map((inquiry) => _buildInquiryCard(
                  context: context,
                  inquiry: inquiry,
                )),

            // Add some bottom padding
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Search Inquiries",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Enter inquiry title, department, or person",
            hintStyle: const TextStyle(color: Colors.black38),
            counterText: '',
            contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: _buildBorder(const Color(0xFF379E4B)),
            enabledBorder: _buildBorder(const Color(0xFF379E4B)),
            focusedBorder: _buildBorder(const Color(0xFF1B5E20), width: 2.0),
            suffixIcon: _buildSearchButton(context),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF379E4B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            final input = _searchController.text.trim();
            if (input.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a search query.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            _filterInquiries();
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryCard({
    required BuildContext context,
    required AssignToMeModel inquiry,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToInquiryDetails(inquiry),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  inquiry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Department Row
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        inquiry.department,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Assigned To Row
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        inquiry.assignedTo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}