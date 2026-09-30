import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/widgets/custom_toast.dart';
import 'package:lelahanoi/features/order/presentation/bloc/cart_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/core/models/category.dart';
import 'package:lelahanoi/core/models/menu.dart';
import 'package:lelahanoi/features/menu/presentation/pages/add_product_page.dart';
import 'package:lelahanoi/features/menu/presentation/pages/category_admin_page.dart';
import 'package:lelahanoi/features/menu/presentation/bloc/menu_cubit.dart';
import 'package:lelahanoi/features/order/presentation/pages/cart_page.dart';

class MenuPage extends StatefulWidget {
  final bool isManager;
  const MenuPage({super.key, this.isManager = false});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final Color _primaryColor = const Color(0xFF557A58);
  final Color _bgColor = const Color(0xFFB4D3B6);
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final List<String> _sliderImages = [
    'https://images.unsplash.com/photo-1544145945-f90425340c7e?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1517701604599-bb29b565090c?q=80&w=1000&auto=format&fit=crop',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageCubit>().strings;
    return BlocBuilder<MenuCubit, MenuState>(
      builder: (context, state) {
        if (state.status == MenuStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == MenuStatus.failure) {
          return Center(child: Text('${t.errorSystem}: ${state.error}'));
        }
        if (state.categories.isEmpty) {
          return Center(child: Text(t.noData));
        }

        final categories = state.categories;
        return DefaultTabController(
          length: categories.length + 1,
          key: ValueKey(categories.length),
          child: Scaffold(
            backgroundColor: _bgColor,
            floatingActionButton:
                widget.isManager ? _buildSpeedDial(categories, t) : null,
            appBar: AppBar(
              backgroundColor: _bgColor,
              elevation: 0,
              centerTitle: true,
              title: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      if (mounted)
                        context.read<MenuCubit>().setSearchQuery(value);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: t.searchMenu,
                    prefixIcon:
                        const Icon(Icons.search, size: 20, color: Colors.grey),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              context.read<MenuCubit>().setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              actions: [
                _buildCartBadge(),
                const SizedBox(width: 10),
              ],
            ),
            body: SafeArea(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildBrandName(),
                          _buildAutoSlider(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context),
                      sliver: SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          Container(
                            color: _bgColor,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            width: double.infinity,
                            child: TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              indicatorSize: TabBarIndicatorSize.label,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: _primaryColor,
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: _primaryColor,
                              tabs: [
                                _buildTabItem(t.allCategories),
                                ...categories
                                    .map((cat) => _buildTabItem(cat.name)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    _buildResponsiveGrid("all", categories, t),
                    ...categories.map(
                        (cat) => _buildResponsiveGrid(cat.id, categories, t)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandName() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          "Le La Hanoi",
          style: GoogleFonts.merriweather(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 120,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        viewportFraction: 0.85,
      ),
      items: _sliderImages.map((imageUrl) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildSpeedDial(List<CategoryModel> categories, dynamic t) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      buttonSize: const Size(56, 56),
      children: [
        SpeedDialChild(
          child: const Icon(Icons.category_outlined),
          backgroundColor: Colors.white,
          foregroundColor: _primaryColor,
          label: t.categories,
          labelStyle: GoogleFonts.merriweather(fontWeight: FontWeight.w500),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CategoryAdminPage()),
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.restaurant_menu),
          backgroundColor: Colors.white,
          foregroundColor: _primaryColor,
          label: t.addProduct,
          labelStyle: GoogleFonts.merriweather(fontWeight: FontWeight.w500),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductPage(categories: categories),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartBadge() {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final count =
            state.quantities.values.fold<int>(0, (sum, value) => sum + value);
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.shopping_cart_outlined, color: Colors.black),
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const CartPage()));
              },
            ),
            if (count > 0)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
          ],
        );
      },
    );
  }

  Widget _buildResponsiveGrid(
      String categoryId, List<CategoryModel> categories, dynamic t) {
    return Builder(
      builder: (nestedContext) {
        final state = nestedContext.watch<MenuCubit>().state;
        final filteredItems = state.itemsFor(categoryId);
        if (filteredItems.isEmpty) {
          return Center(
            child: Text(
              state.searchQuery.isEmpty
                  ? t.noItems
                  : "${t.noItems}: '${state.searchQuery}'",
            ),
          );
        }

        return CustomScrollView(
          key: PageStorageKey<String>('grid_$categoryId'),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  nestedContext),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildModernCard(filteredItems[index], categories, t),
                  childCount: filteredItems.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernCard(
      MenuModel item, List<CategoryModel> categories, dynamic t) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Stack(
        children: [
          if (widget.isManager)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  _buildAdminCircleButton(
                    icon: Icons.visibility_outlined,
                    color: _primaryColor,
                    onTap: () => _showImagePreview(item, t),
                  ),
                  const SizedBox(width: 6),
                  _buildAdminCircleButton(
                    icon: Icons.edit,
                    color: Colors.blue,
                    onTap: () => _editProduct(item, categories),
                  ),
                  const SizedBox(width: 6),
                  _buildAdminCircleButton(
                    icon: Icons.delete,
                    color: Colors.red,
                    onTap: () => _confirmDelete(item, t),
                  ),
                ],
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    item.image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image,
                          color: Colors.grey, size: 40),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${_formatCurrency(item.price)}đ",
                            style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showImagePreview(item, t),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _primaryColor.withOpacity(0.2)),
                                ),
                                child: Icon(Icons.image_outlined,
                                    color: _primaryColor, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: widget.isManager
                                  ? () =>
                                      _showManagerActions(item, categories, t)
                                  : () => _addToCart(item),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Icon(
                                    widget.isManager
                                        ? Icons.more_horiz
                                        : Icons.add,
                                    color: Colors.white,
                                    size: 18),
                              ),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MenuModel item, dynamic t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${t.delete}?", style: GoogleFonts.merriweather()),
        content: Text("${t.delete} '${item.name}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(t.noData)),
          TextButton(
            onPressed: () async {
              await context.read<MenuCubit>().deleteItem(item.id);
              if (mounted) Navigator.pop(context);
              showToast(t.delete, false);
            },
            child: Text(t.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editProduct(MenuModel item, List<CategoryModel> categories) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddProductPage(categories: categories, editItem: item),
      ),
    );
  }

  void _showManagerActions(
      MenuModel item, List<CategoryModel> categories, dynamic t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: _primaryColor),
              title: Text(t.edit),
              onTap: () {
                Navigator.pop(context);
                _editProduct(item, categories);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(t.delete),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(item, t);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(MenuModel item, dynamic t) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: InteractiveViewer(
            child: Image.network(
              item.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => SizedBox(
                height: 260,
                child: Center(
                  child:
                      Text(t.viewImage, style: TextStyle(color: _primaryColor)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCircleButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Future<void> _addToCart(MenuModel item) async {
    await context.read<CartCubit>().add(item);
    final t = context.read<LanguageCubit>().strings;
    showToast(t.addedToCart, true);
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Widget _buildTabItem(String text) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primaryColor, width: 1.5),
        ),
        child: Text(text),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 65;

  @override
  double get maxExtent => 65;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
