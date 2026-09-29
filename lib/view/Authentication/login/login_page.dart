import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lelahanoi/public/image/images_file.dart';
import 'package:lelahanoi/public/l10n/language_provider.dart';
import 'package:lelahanoi/public/widget/app_colors.dart';
import 'package:lelahanoi/public/widget/custom_toast.dart';
import 'package:lelahanoi/utils/auth_service.dart';
import 'package:lelahanoi/view/Authentication/register/register_page.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final Color _primaryColor = AppColors.primary;
  final Color _bgMint = AppColors.background;
  final Color _cream = AppColors.cream;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ShowToast(context.read<LanguageProvider>().strings.fillAllFields, false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // StreamBuilder trong main.dart sẽ tự điều hướng sang MainPage
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
      case 'user-not-found': return t.emailNotFound;
      case 'wrong-password': return t.wrongPassword;
      case 'invalid-credential': return t.loginFailed;
      case 'invalid-email': return t.invalidEmail;
      case 'user-disabled': return t.loginFailed;
      case 'too-many-requests': return t.tooManyRequests;
      case 'network-request-failed': return t.errorSystem;
      default: return '${t.loginFailed}: $code';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().strings;
    return Scaffold(
      backgroundColor: _bgMint,
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
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 250,
                  child: Image.asset(Images.appIconText, fit: BoxFit.fill),
                ),
              Text(t.welcomeBack, style: GoogleFonts.merriweather(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
              )),
              const SizedBox(height: 30),
              _buildTextField(
                controller: _emailController,
                hint: t.email,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 5,
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(t.loginButton,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.noAccount),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                    child: Text(t.signUpNow,
                        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
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
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }
}
