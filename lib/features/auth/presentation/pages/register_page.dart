import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lelahanoi/core/constants/images.dart';
import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/theme/app_colors.dart';
import 'package:lelahanoi/core/widgets/custom_toast.dart';
import 'package:lelahanoi/features/auth/presentation/bloc/auth_cubit.dart';

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
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final t = context.read<LanguageCubit>().strings;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showToast(t.fillAllFields, false);
      return;
    }
    if (password != confirmPassword) {
      showToast(t.passwordMismatch, false);
      return;
    }
    if (password.length < 6) {
      showToast(t.passwordTooShort, false);
      return;
    }
    await context.read<AuthCubit>().register(name, email, password);
  }

  String _errorMessage(String code) {
    final t = context.read<LanguageCubit>().strings;
    return switch (code) {
      'email-already-in-use' => t.emailInUse,
      'invalid-email' => t.invalidEmail,
      'weak-password' => t.weakPassword,
      'network-request-failed' => t.errorSystem,
      'too-many-requests' => t.tooManyRequests,
      _ => '${t.registerFailed}: $code',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageCubit>().strings;
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.registrationCompleted) {
          showToast('Đăng ký thành công!', true);
          Navigator.pop(context);
        } else if (state.status == AuthStatus.failure &&
            state.errorCode != null) {
          showToast(_errorMessage(state.errorCode!), false);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isLoading = authState.status == AuthStatus.checking;
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.black)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      SizedBox(
                          height: 200,
                          child: Image.asset(Images.appIconText,
                              fit: BoxFit.fill)),
                      const SizedBox(height: 8),
                      Text(t.joinUs,
                          style: GoogleFonts.merriweather(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(height: 40),
                      _RegisterField(
                          controller: _nameController,
                          hint: t.fullName,
                          icon: Icons.person_outline),
                      const SizedBox(height: 15),
                      _RegisterField(
                          controller: _emailController,
                          hint: t.email,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 15),
                      _RegisterField(
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
                      const SizedBox(height: 15),
                      _RegisterField(
                          controller: _confirmPasswordController,
                          hint: t.confirmPassword,
                          icon: Icons.lock_reset,
                          obscureText: true),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          onPressed: isLoading ? null : _register,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(t.registerButton,
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
                          Text(t.hasAccount),
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(t.signIn,
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 20),
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

class _RegisterField extends StatelessWidget {
  const _RegisterField(
      {required this.controller,
      required this.hint,
      required this.icon,
      this.obscureText = false,
      this.suffixIcon,
      this.keyboardType = TextInputType.text});

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
          ]),
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
                const EdgeInsets.symmetric(vertical: 18, horizontal: 20)),
      ),
    );
  }
}
