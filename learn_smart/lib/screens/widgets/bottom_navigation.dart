import 'package:flutter/material.dart';
import 'package:motion_tab_bar_v2/motion-tab-bar.dart';
import 'package:motion_tab_bar_v2/motion-tab-controller.dart';
import 'package:get/get.dart';

class BottomNavigation extends StatelessWidget {
  final MotionTabBarController controller;
  final int currentIndex;

  BottomNavigation({
    required this.controller,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return MotionTabBar(
      labels: const ["Home", "Search", "Notifications", "Profile"],
      initialSelectedTab: _getTabLabel(currentIndex),
      tabIconColor: Colors.grey,
      tabSelectedColor: Colors.blue,
      icons: const [
        Icons.home,
        Icons.search,
        Icons.notifications,
        Icons.person
      ],
      textStyle: const TextStyle(color: Colors.blue),
      onTabItemSelected: (int index) {
        _navigateToScreen(index);
      },
      controller: controller,
    );
  }

  String _getTabLabel(int index) {
    switch (index) {
      case 0:
        return "Home";
      case 1:
        return "Search";
      case 2:
        return "Notifications";
      case 3:
        return "Profile";
      default:
        return "Home";
    }
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        Get.toNamed('/dashboard');
        break;
      case 1:
        Get.toNamed(
            '/explore'); // If you have a search screen, you can implement this
        break;
      case 2:
        Get.toNamed('/notifications');
        break;
      case 3:
        Get.toNamed('/profile'); // If you have a profile screen
        break;
      default:
        Get.toNamed('/dashboard');
        break;
    }
  }
}
