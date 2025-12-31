import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2), // Floating effect
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, "Home", 0),
          _buildNavItem(Icons.question_answer, "Inquiries", 1),
          _buildNavItem(Icons.person, "Profile", 2),
        ],
      ),
    );
  }

  /// Builds a Custom Navigation Item
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: isSelected
                ? BoxDecoration(
              color: const Color(0xFF014323), // Updated to custom color
              borderRadius: BorderRadius.circular(20),
            )
                : null,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.black,
                  size: 24,
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF014323), // Updated to custom color
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}