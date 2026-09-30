import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lelahanoi/core/l10n/app_strings.dart';
import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/models/category.dart';
import 'package:lelahanoi/features/menu/presentation/bloc/menu_cubit.dart';

class CategoryAdminPage extends StatefulWidget {
  const CategoryAdminPage({super.key});

  @override
  State<CategoryAdminPage> createState() => _CategoryAdminPageState();
}

class _CategoryAdminPageState extends State<CategoryAdminPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    final t = context.read<LanguageCubit>().strings;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.addNewCategory,
            style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: t.categoryNameHint)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF557A58)),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await context.read<MenuCubit>().addCategory(name);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(t.add, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageCubit>().strings;
    return Scaffold(
      backgroundColor: const Color(0xFFB4D3B6),
      appBar: AppBar(
        title: Text(t.manageCategories,
            style: GoogleFonts.merriweather(
                color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: InputDecoration(
                    icon: const Icon(Icons.search, color: Color(0xFF557A58)),
                    hintText: t.searchCategories,
                    border: InputBorder.none),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<MenuCubit, MenuState>(
              builder: (context, state) {
                if (state.status == MenuStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final categories = state.categories
                    .where((category) =>
                        category.name.toLowerCase().contains(_searchQuery))
                    .toList();
                final itemCount = _searchQuery.isEmpty
                    ? categories.length + 1
                    : categories.length;
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (_searchQuery.isEmpty && index == 0) {
                      return _buildAddCard(t);
                    }
                    final category =
                        categories[_searchQuery.isEmpty ? index - 1 : index];
                    return _buildCategoryItem(category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCard(AppStrings t) {
    return GestureDetector(
      onTap: _showAddDialog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 70,
        decoration: BoxDecoration(
            color: const Color(0xFF557A58).withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF557A58), width: 1.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_circle_outline, color: Color(0xFF557A58)),
          const SizedBox(width: 10),
          Text(t.addNewCategory,
              style: GoogleFonts.merriweather(
                  color: const Color(0xFF557A58), fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () =>
              context.read<MenuCubit>().deleteCategory(category.id),
        ),
      ),
    );
  }
}
