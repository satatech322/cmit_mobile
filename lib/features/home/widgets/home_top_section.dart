import 'package:flutter/material.dart';
import 'package:cmit/features/home/view/inquiries_details_screen.dart';
import 'package:cmit/core//inquiry_statistics_service.dart';
import 'package:cmit/features/home/model/inquiry_statistics_model.dart';

class HomeTopSection extends StatefulWidget {
  const HomeTopSection({super.key});

  @override
  State<HomeTopSection> createState() => _HomeTopSectionState();
}

class _HomeTopSectionState extends State<HomeTopSection> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  // Sample inquiries (replace with API list later if needed)
  List<Map<String, dynamic>> inquiries = [
    {
      'ref': 'REF-00123',
      'title': 'Financial Audit of MIT Department',
      'dept': 'Finance',
      'assignedTo': 'Malik Afzal',
      'date': 'July 01 2025',
      'status': 'Open',
      'description':
      'Detailed financial audit inquiry regarding MIT department budget allocation and spending.',
      'color': Colors.green[100]!,
    },
    {
      'ref': 'REF-00124',
      'title': 'IT Infrastructure Upgrade',
      'dept': 'IT',
      'assignedTo': 'Haider Ali',
      'date': 'July 03 2025',
      'status': 'In Progress',
      'description':
      'Upgrade of servers, network equipment, and storage for IT infrastructure.',
      'color': Colors.orange[100]!,
    },
    {
      'ref': 'REF-00125',
      'title': 'Library System Update',
      'dept': 'Library',
      'assignedTo': 'Sara Khan',
      'date': 'July 05 2025',
      'status': 'Closed',
      'description':
      'Update and maintenance of digital library management system.',
      'color': Colors.grey[300]!,
    },
  ];

  List<Map<String, dynamic>> filteredInquiries = [];

  // Statistics state
  int totalInquiries = 0;
  int pendingInquiries = 0;
  int completedInquiries = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    filteredInquiries = inquiries;
    _searchController.addListener(_filterInquiries);
    _loadStatistics(); // Initial load
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterInquiries);
    _searchController.dispose();
    super.dispose();
  }

  /// Combined refresh function - called on pull-to-refresh
  Future<void> _onRefresh() async {
    await _loadStatistics();
    // You can also refresh the inquiries list here if it's from API
    // await _loadInquiriesList();
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

  void _filterInquiries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredInquiries = inquiries.where((inquiry) {
        final ref = inquiry['ref'].toString().toLowerCase();
        final title = inquiry['title'].toString().toLowerCase();
        final dept = inquiry['dept'].toString().toLowerCase();
        return ref.contains(query) || title.contains(query) || dept.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _onRefresh,
      color: const Color(0xFF379E4B), // Matches your app theme
      backgroundColor: Colors.white,
      strokeWidth: 3.0,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Important for refresh even when content is short
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

            /// Inquiry Cards
            ...filteredInquiries.map((inquiry) => _buildInquiryCard(
              context: context,
              ref: inquiry['ref'],
              title: inquiry['title'],
              dept: inquiry['dept'],
              assignedTo: inquiry['assignedTo'],
              date: inquiry['date'],
              status: inquiry['status'],
              description: inquiry['description'],
              color: inquiry['color'],
            )),

            // Add some bottom padding so user can pull down even at the end
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // All your existing helper widgets remain unchanged
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
            hintText: "Enter inquiry ref, title, or department",
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
    required String ref,
    required String title,
    required String dept,
    required String assignedTo,
    required String date,
    required String status,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InquiryDetailsScreen(
                ref: ref,
                title: title,
                dept: dept,
                assignedTo: assignedTo,
                date: date,
                status: status,
                description: description,
              ),
            ),
          );
        },
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
                Text(
                  ref,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$dept : Created on $date",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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