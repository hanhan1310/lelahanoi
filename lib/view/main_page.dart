import 'package:flutter/material.dart';
import 'package:lelahanoi/public/widget/app_colors.dart';
import 'package:lelahanoi/public/l10n/language_provider.dart';
import 'package:provider/provider.dart';

import 'Menu/list_menu/menu_page.dart';
import 'Order/list_order/order_page.dart';
import 'Service/loyalty_page.dart';
import 'personal/more_infomation_page.dart';
import 'manager/manager_orders_page.dart';
import 'manager/manager_reports_page.dart';
import 'manager/manager_settings_page.dart';

class MainPage extends StatefulWidget {
  final bool isManager;

  const MainPage({super.key, this.isManager = false});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  List<Widget> get _pages => widget.isManager
      ? const <Widget>[
          ManagerOrdersPage(),
          MenuPage(isManager: true),
          ManagerReportsPage(),
          ManagerSettingsPage(),
        ]
      : const <Widget>[
          MenuPage(isManager: false),
          OrderHistoryPage(),
          LoyaltyPage(),
          MorePage(),
        ];

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().strings;
    final themeColor = AppColors.background;
    final bottomBarColor = AppColors.primary;
    final navItems = widget.isManager
        ? <_NavItem>[
            _NavItem(Icons.receipt_long, t.orders),
            _NavItem(Icons.restaurant_menu, t.menu),
          _NavItem(Icons.analytics_outlined, t.manageReports),
            _NavItem(Icons.settings, t.settings),
          ]
        : <_NavItem>[
            _NavItem(Icons.menu_book, t.menu),
            _NavItem(Icons.shopping_cart, t.order),
            _NavItem(Icons.card_giftcard, t.loyalty),
            _NavItem(Icons.more_horiz, t.more),
          ];

    return Scaffold(
      backgroundColor: themeColor,
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              return _buildNavItem(index, item.icon, item.label, themeColor, bottomBarColor);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color themeColor, Color bottomBarColor) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        padding: isSelected ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10) : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.55) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? bottomBarColor : Colors.grey),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: bottomBarColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
