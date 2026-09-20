import 'package:flutter/material.dart';
import '../state/store_controller.dart';
import '../widgets/bottom_nav.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'trends_screen.dart';

class ShellScreen extends StatelessWidget {
  final StoreController controller;
  const ShellScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: controller.tabIndex,
              children: [
                HomeScreen(controller: controller),
                CategoriesScreen(controller: controller),
                TrendsScreen(controller: controller),
                CartScreen(controller: controller),
                AccountScreen(controller: controller),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: TakhfidBottomNav(
              currentIndex: controller.tabIndex,
              cartCount: controller.cartCount,
              onChanged: controller.selectTab,
            ),
          ),
        );
      },
    );
  }
}
