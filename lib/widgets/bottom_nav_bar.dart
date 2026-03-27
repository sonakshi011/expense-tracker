import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget{
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
});
  @override
  Widget build(BuildContext context){
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildItem(Icons.list, "Overview", 0),
            buildItem(Icons.add_card_rounded, "Cash In", 1),
            const SizedBox(width: 40),
            buildItem(Icons.credit_card_off_sharp, "Cash Out", 2),
            buildItem(Icons.settings_applications, "Settings",3),
          ],
        ),
      ),
    );
  }

  Widget buildItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;

    Color getColor() {

      if (index == 1) return Colors.green;

      if (index == 2) return Colors.red;


      return isSelected ? Colors.red : Colors.grey;
    }

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: getColor(),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: getColor(),
            ),
          ),
        ],
      ),
    );
  }
  }