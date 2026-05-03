import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'signup_screen.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainShell()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, constraints) {
          final wide = constraints.maxWidth > 720;
          final form = _buildForm(auth);
          if (wide) {
            return Row(children: [
              Expanded(child: _buildHero()),
              Expanded(child: Center(child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48), child: form))),
            ]);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: form,
          );
        }),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      color: AppColors.primary,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.accent, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 24),
        Text('StudyFlow',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 12),
        Text('Your AI-powered study companion',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, color: Colors.white60)),
      ]),
    );
  }

  Widget _buildForm(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Logo for mobile
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Text('StudyFlow',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ]),
        const SizedBox(height: 36),
        Text('Welcome back',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 6),
        Text('Sign in to continue your study journey',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.secondary)),
        const SizedBox(height: 32),

        // Email
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.secondary),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.secondary),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.muted),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your password';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 28),

        // Submit
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : _submit,
            child: auth.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Sign In'),
          ),
        ),
        const SizedBox(height: 24),

        // Navigate to signup
        Center(
          child: GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SignupScreen())),
            child: RichText(
              text: TextSpan(
                text: "Don't have an account? ",
                style: GoogleFonts.plusJakartaSans(color: AppColors.secondary, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Sign Up',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
