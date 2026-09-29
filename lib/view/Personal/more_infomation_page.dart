import 'package:flutter/material.dart';
import 'package:lelahanoi/public/l10n/language_provider.dart';
import 'package:lelahanoi/public/widget/custom_toast.dart';
import 'package:lelahanoi/utils/auth_service.dart';
import 'package:provider/provider.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final Color _bgMint = const Color(0xFFB4D3B6);
  final Color _primaryTeal = const Color(0xFF719B75);
  final Color _textDark = const Color(0xFF2C3E50);

  String _name = '';
  String _email = '';
  String _image = '';
  String _phone = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await AuthService.getUserData();
    if (!mounted) return;
    setState(() {
      _name = data?['name'] ?? '';
      _email = AuthService.currentUser?.email ?? '';
      _image = data?['image'] ?? '';
      _phone = data?['phone'] ?? '';
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    ShowToast(context.read<LanguageProvider>().strings.logoutSuccess, true);
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật thông tin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ và tên')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              await AuthService.updateCurrentUser({
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
              });
              if (!mounted) return;
              Navigator.pop(context);
              await _loadUser();
              ShowToast("Đã cập nhật thông tin", true);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().strings;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: _bgMint,
      appBar: AppBar(
        title: Text(t.more, style: const TextStyle(fontWeight: FontWeight.w400)),
        backgroundColor: _bgMint,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileHeader(t),
                    const SizedBox(height: 20),
                    _buildSectionTitle(t.store),
                    _buildMenuItem(Icons.storefront_outlined, t.storeDetails, () => _showStoreInfo()),
                    // _buildMenuItem(Icons.phone_outlined, t.contactManager, () => _showContactInfo()),
                    const SizedBox(height: 20),
                    _buildSectionTitle(t.appSettings),
                    _buildMenuItem(Icons.language, "${t.changeLanguage}: ${languageProvider.currentCode.toUpperCase()}", () => _showLanguagePicker()),
                    _buildMenuItem(Icons.settings_outlined, t.editInfo, _editProfile),
                    // _buildMenuItem(Icons.help_outline, t.faq, () {}),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: Text(
                          t.logout,
                          style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.white.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(dynamic t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _primaryTeal.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryTeal, width: 2),
              image: DecorationImage(
                image: _image.isNotEmpty
                    ? NetworkImage(_image)
                    : const NetworkImage('https://upload.wikimedia.org/wikipedia/commons/8/89/Portrait_Placeholder.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Text(_name.isNotEmpty ? _name : 'Customer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
                const SizedBox(height: 4),
                Text(_email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(_phone.isNotEmpty ? _phone : t.phoneNumber, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(onPressed: _editProfile, icon: Icon(Icons.edit_square, color: _bgMint)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10, top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _bgMint.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _primaryTeal, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: _textDark)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
      ),
    );
  }

  void _showStoreInfo() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text("Store details"),
        content: Text(
          "369 Altstadt, 84028 Landshut\n"
          "015226673930\n"
          "manager@lelahanoi.de",
        ),
      ),
    );
  }

  void _showContactInfo() {
    final t = context.read<LanguageProvider>().strings;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.contactManager),
        content: const Text("015226673930 / manager@lelahanoi.de"),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    final provider = context.read<LanguageProvider>();
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: LanguageProvider.supportedLanguages.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              trailing: provider.currentCode == entry.key ? const Icon(Icons.check) : null,
              onTap: () async {
                await provider.setLanguage(entry.key);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
