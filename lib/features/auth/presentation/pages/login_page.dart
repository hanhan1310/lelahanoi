import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lelahanoi/core/constants/images.dart';
import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/theme/app_colors.dart';
import 'package:lelahanoi/core/widgets/custom_toast.dart';
import 'package:lelahanoi/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:lelahanoi/features/auth/presentation/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showToast(context.read<LanguageCubit>().strings.fillAllFields, false);
      return;
    }
    await context.read<AuthCubit>().login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  String _errorMessage(String code) {
    final t = context.read<LanguageCubit>().strings;
    return switch (code) {
      'user-not-found' => t.emailNotFound,
      'wrong-password' ||
      'invalid-credential' ||
      'user-disabled' =>
        t.loginFailed,
      'invalid-email' => t.invalidEmail,
      'too-many-requests' => t.tooManyRequests,
      'network-request-failed' => t.errorSystem,
      _ => '${t.loginFailed}: $code',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageCubit>().strings;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.failure && state.errorCode != null) {
          showToast(_errorMessage(state.errorCode!), false);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isLoading = authState.status == AuthStatus.checking;
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    AppColors.cream.withOpacity(0.4)
                  ],
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
                          child: Image.asset(Images.appIconText,
                              fit: BoxFit.fill)),
                      Text(
                        t.welcomeBack,
                        style: GoogleFonts.merriweather(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _Field(
                          controller: _emailController,
                          hint: t.email,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 20),
                      _Field(
                        controller: _passwordController,
                        hint: t.password,
                        icon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.primary),
                          onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            elevation: 5,
                          ),
                          onPressed: isLoading ? null : _login,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(t.loginButton,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t.noAccount),
                          TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterPage())),
                            child: Text(t.signUpNow,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }
}
