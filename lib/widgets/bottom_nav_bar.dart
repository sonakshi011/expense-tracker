import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isChartView;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isChartView,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: buildItem(
                currentIndex == 0 && isChartView
                    ? Icons.list
                    : Icons.pie_chart,
                isChartView ? "List" : "Overview",
                0,
              ),
            ),
            Expanded(child: buildItem(Icons.add_card_rounded, "Cash In", 1)),
            const SizedBox(width: 25),
            Expanded(
                child: buildItem(Icons.credit_card_off_sharp, "Cash Out", 2)),
            Expanded(
                child: buildItem(Icons.settings_applications, "Settings", 3)),
          ],
        ),
      ),
    );
  }

  // Widget buildItem(IconData icon, String label, int index) {
  //   final isSelected = currentIndex == index;
  //
  //   Color getBaseColor() {
  //     if (index == 1) return Colors.green;
  //     if (index == 2) return Colors.red;
  //     return isSelected ? Colors.deepPurple : Colors.grey.shade600;
  //   }
  //
  //   return Expanded(
  //     child: GestureDetector(
  //       onTap: () => onTap(index),
  //       behavior: HitTestBehavior.opaque,
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //
  //           AnimatedContainer(
  //             duration: const Duration(milliseconds: 200),
  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  //             decoration: BoxDecoration(
  //
  //               color: isSelected ? getBaseColor().withOpacity(0.1) : Colors
  //                   .transparent,
  //               borderRadius: BorderRadius.circular(20),
  //             ),
  //             child: Icon(
  //               icon,
  //               size: 26,
  //               color: getBaseColor(),
  //             ),
  //           ),
  //           const SizedBox(height: 4),
  //           Text(
  //             label,
  //             style: TextStyle(
  //               fontSize: 11,
  //               fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
  //               color: getBaseColor(),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget buildItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;

    Color getBaseColor() {
      if (index == 1) return Colors.green;
      if (index == 2) return Colors.red;
      return isSelected ? Colors.deepPurple : Colors.grey.shade600;
    }

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? getBaseColor().withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 26,
              color: getBaseColor(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: getBaseColor(),
            ),
          ),
        ],
      ),
    );
  }
}