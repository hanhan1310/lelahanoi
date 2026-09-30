import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/widgets/custom_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/core/models/category.dart';
import 'package:lelahanoi/core/models/menu.dart';
import 'package:lelahanoi/features/menu/presentation/bloc/menu_cubit.dart';
import 'package:lelahanoi/core/services/image_upload_service.dart';

class AddProductPage extends StatefulWidget {
  final List<CategoryModel> categories;
  final MenuModel? editItem;

  const AddProductPage({super.key, required this.categories, this.editItem});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCatId;
  File? _imageFile;
  bool _isUploading = false;
  final _imageUploadService = const ImageUploadService();

  final Color _primaryColor = const Color(0xFF557A58);
  final Color _bgMint = const Color(0xFFB4D3B6);

  bool get _isEditMode => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    if (item != null) {
      _nameController.text = item.name;
      _priceController.text = item.price.toString();
      _selectedCatId = item.categories;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(File file) async {
    return _imageUploadService.uploadMenuImage(file);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageCubit>().strings;

    return Scaffold(
      backgroundColor: _bgMint,
      appBar: AppBar(
        title: Text(
          _isEditMode ? t.editFood : t.addProduct,
          style: GoogleFonts.merriweather(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => _showPicker(context),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: _imageFile == null
                          ? Stack(
                              children: [
                                if (widget.editItem?.image.isNotEmpty ?? false)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(21),
                                      child: Image.network(
                                          widget.editItem!.image,
                                          fit: BoxFit.cover),
                                    ),
                                  ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(
                                        widget.editItem?.image.isNotEmpty ??
                                                false
                                            ? 0.55
                                            : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(21),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 48,
                                            color: _primaryColor,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _isEditMode
                                                ? t.keepOldOrPickNew
                                                : t.addImage,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.merriweather(
                                              color: _primaryColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(21),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(t.foodInformation,
                    style: GoogleFonts.merriweather(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTextField(
                    _nameController, t.productName, Icons.restaurant_menu),
                const SizedBox(height: 16),
                _buildTextField(
                    _priceController, t.price, Icons.payments_outlined,
                    isNumber: true),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.category_outlined,
                          color: Color(0xFF557A58)),
                      labelText: t.category,
                    ),
                    value: _selectedCatId,
                    items:
                        widget.categories.map<DropdownMenuItem<String>>((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.id,
                        child: Text(cat.name,
                            style: const TextStyle(fontSize: 15)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCatId = val),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      elevation: 8,
                      shadowColor: _primaryColor.withOpacity(0.4),
                    ),
                    onPressed: _isUploading ? null : _saveProduct,
                    child: Text(
                      _isEditMode ? t.updateFood : t.saveProduct,
                      style: GoogleFonts.merriweather(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    final t = context.read<LanguageCubit>().strings;

    if (_nameController.text.isEmpty || _selectedCatId == null) {
      showToast(t.fillProductFields, false);
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? url = _imageFile != null
          ? await _uploadImage(_imageFile!)
          : widget.editItem?.image;

      if (url == null || url.isEmpty) {
        showToast(t.uploadFailed, false);
        return;
      }

      final payload = {
        'name': _nameController.text.trim(),
        'price': int.tryParse(_priceController.text) ?? 0,
        'image': url,
        'categories': _selectedCatId,
        'is_delete': false,
        'status': 'active',
      };

      if (_isEditMode) {
        await context
            .read<MenuCubit>()
            .updateMenu(widget.editItem!.id, payload);
        showToast(t.foodUpdated, true);
      } else {
        await context.read<MenuCubit>().addMenu(payload);
        showToast(t.addSuccess, true);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      showToast("${t.errorSystem}: $e", false);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showPicker(BuildContext context) {
    final t = context.read<LanguageCubit>().strings;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_library, color: _primaryColor),
                  title: Text(t.imageLibrary),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: _primaryColor),
                  title: Text(t.takePhoto),
                  onTap: () {
                    _pickImage(ImageSource.camera);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }
}
