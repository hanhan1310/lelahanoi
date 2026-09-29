import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lelahanoi/public/image/images_file.dart';
import 'package:lelahanoi/public/l10n/language_provider.dart';
import 'package:lelahanoi/public/widget/app_colors.dart';
import 'package:lelahanoi/public/widget/custom_toast.dart';
import 'package:lelahanoi/utils/auth_service.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final Color _primaryColor = AppColors.primary;
  final Color _bgMint = AppColors.background;
  final Color _cream = AppColors.cream;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ShowToast(context.read<LanguageProvider>().strings.fillAllFields, false);
      return;
    }
    if (password != confirmPassword) {
      ShowToast(context.read<LanguageProvider>().strings.passwordMismatch, false);
      return;
    }
    if (password.length < 6) {
      ShowToast(context.read<LanguageProvider>().strings.passwordTooShort, false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.register(name, email, password);
      ShowToast("Đăng ký thành công!", true);
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ShowToast(_parseError(e.code), false);
    } catch (e) {
      ShowToast('Lỗi: ${e.toString()}', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String code) {
    final t = context.read<LanguageProvider>().strings;
    switch (code) {
      case 'email-already-in-use': return t.emailInUse;
      case 'invalid-email': return t.invalidEmail;
      case 'weak-password': return t.weakPassword;
      case 'network-request-failed': return t.errorSystem;
      case 'too-many-requests': return t.tooManyRequests;
      default: return '${t.registerFailed}: $code';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: _bgMint,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgMint, _cream.withOpacity(0.4)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: Image.asset(Images.appIconText, fit: BoxFit.fill),
                ),
                const SizedBox(height: 8),
                Text(t.joinUs, style: GoogleFonts.merriweather(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
              )),
                const SizedBox(height: 40),
              _buildTextField(controller: _nameController, hint: t.fullName, icon: Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _emailController,
                hint: t.email,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _passwordController,
                hint: t.password,
                icon: Icons.lock_outline,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: _primaryColor),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: t.confirmPassword,
                icon: Icons.lock_reset,
                obscureText: true,
              ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(t.registerButton,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.hasAccount),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(t.signIn, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: _primaryColor),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}
