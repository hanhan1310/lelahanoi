import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/theme/app_colors.dart';
import 'package:lelahanoi/features/home/presentation/bloc/navigation_cubit.dart';
import 'package:lelahanoi/features/loyalty/presentation/pages/loyalty_page.dart';
import 'package:lelahanoi/features/loyalty/presentation/bloc/loyalty_cubit.dart';
import 'package:lelahanoi/features/manager/presentation/pages/manager_orders_page.dart';
import 'package:lelahanoi/features/manager/presentation/pages/manager_reports_page.dart';
import 'package:lelahanoi/features/manager/presentation/pages/manager_settings_page.dart';
import 'package:lelahanoi/features/manager/presentation/bloc/manager_settings_cubit.dart';
import 'package:lelahanoi/features/menu/presentation/pages/menu_page.dart';
import 'package:lelahanoi/features/menu/presentation/bloc/menu_cubit.dart';
import 'package:lelahanoi/features/order/presentation/bloc/cart_cubit.dart';
import 'package:lelahanoi/features/order/presentation/bloc/order_cubit.dart';
import 'package:lelahanoi/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:lelahanoi/features/order/presentation/pages/order_history_page.dart';
import 'package:lelahanoi/features/profile/presentation/pages/profile_page.dart';
import 'package:lelahanoi/features/profile/presentation/bloc/profile_cubit.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key, this.isManager = false});

  final bool isManager;

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.userId;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider(create: (_) => CartCubit()..load()),
        BlocProvider(create: (_) => MenuCubit()),
        BlocProvider(
            create: (_) => OrderCubit(userId: isManager ? null : userId)),
        if (isManager)
          BlocProvider(create: (_) => ManagerSettingsCubit()..load()),
        if (!isManager) BlocProvider(create: (_) => LoyaltyCubit()..load()),
        if (!isManager) BlocProvider(create: (_) => ProfileCubit()..load()),
      ],
      child: BlocBuilder<NavigationCubit, int>(
        builder: (context, selectedIndex) {
          final pages = isManager
              ? const <Widget>[
                  ManagerOrdersPage(),
                  MenuPage(isManager: true),
                  ManagerReportsPage(),
                  ManagerSettingsPage(),
                ]
              : const <Widget>[
                  MenuPage(),
                  OrderHistoryPage(),
                  LoyaltyPage(),
                  MorePage(),
                ];
          final t = context.watch<LanguageCubit>().strings;
          final navItems = isManager
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
            backgroundColor: AppColors.background,
            body: pages[selectedIndex],
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
                  children: List.generate(
                    navItems.length,
                    (index) => _NavItemButton(
                      item: navItems[index],
                      selected: selectedIndex == index,
                      onTap: () =>
                          context.read<NavigationCubit>().select(index),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItemButton extends StatelessWidget {
  const _NavItemButton(
      {required this.item, required this.selected, required this.onTap});

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        padding: selected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.background.withOpacity(0.55)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: selected ? AppColors.primary : Colors.grey),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
