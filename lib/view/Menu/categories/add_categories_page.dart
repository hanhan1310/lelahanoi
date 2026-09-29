import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lelahanoi/public/l10n/app_strings.dart';
import 'package:lelahanoi/public/l10n/language_provider.dart';
import 'package:provider/provider.dart';

class CategoryAdminPage extends StatefulWidget {
  const CategoryAdminPage({super.key});

  @override
  State<CategoryAdminPage> createState() => _CategoryAdminPageState();
}

class _CategoryAdminPageState extends State<CategoryAdminPage> {
  final TextEditingController _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFF557A58);
  final Color _bgMint = const Color(0xFFB4D3B6);
  String _searchQuery = "";

  void _showAddDialog() {
    final t = context.read<LanguageProvider>().strings;
    final TextEditingController addController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.addNewCategory, style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: addController,
          autofocus: true,
          decoration: InputDecoration(hintText: t.categoryNameHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            onPressed: () async {
              if (addController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('categories').add({
                  'name': addController.text.trim(),
                  'is_delete': false,
                  'created_at': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: Text(t.add, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().strings;

    return Scaffold(
      backgroundColor: _bgMint,
      appBar: AppBar(
        title: Text(t.manageCategories, style: GoogleFonts.merriweather(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // THANH TÌM KIẾM
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: _primaryColor),
                  hintText: t.searchCategories,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // DANH SÁCH
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('categories').where('is_delete', isEqualTo: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Lọc dữ liệu: Nếu rỗng thì lấy All
                final allDocs = snapshot.data?.docs ?? [];
                final filteredDocs = allDocs.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  // Cộng thêm 1 để hiển thị Card "Thêm mới" ở đầu nếu không đang tìm kiếm
                  itemCount: _searchQuery.isEmpty ? filteredDocs.length + 1 : filteredDocs.length,
                  itemBuilder: (context, index) {
                    // Nếu đang không search, hiển thị Card thêm mới ở vị trí 0
                    if (_searchQuery.isEmpty && index == 0) {
                      return _buildAddCard(t);
                    }

                    // Tính toán lại index dữ liệu (nếu có card đầu thì lùi 1 đơn vị)
                    final dataIndex = _searchQuery.isEmpty ? index - 1 : index;
                    final doc = filteredDocs[dataIndex];

                    return _buildCategoryItem(doc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Card "Thêm mới" nằm ở đầu danh sách
  Widget _buildAddCard(AppStrings t) {
    return GestureDetector(
      onTap: _showAddDialog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 70,
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _primaryColor, style: BorderStyle.solid, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: _primaryColor),
            const SizedBox(width: 10),
            Text(t.addNewCategory,
                style: GoogleFonts.merriweather(color: _primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(DocumentSnapshot doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => doc.reference.update({'is_delete': true}),
        ),
      ),
    );
  }
}
