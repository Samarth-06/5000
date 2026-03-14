import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/farm_providers.dart';
import '../widgets/glass_card.dart';
import 'dashboard_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supa = ref.read(supabaseServiceProvider);
      if (_isSignUp) {
        await supa.signUp(email, password);
      } else {
        await supa.signIn(email, password);
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardShell()),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _skipLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBackground,
              Color(0xFF0A192F),
              AppColors.primaryBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.eco,
                      size: 60,
                      color: AppColors.primaryAccent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isSignUp ? 'CREATE ACCOUNT' : 'FARMER LOGIN',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildField(
                      label: 'Email',
                      icon: Icons.email,
                      ctrl: _emailCtrl,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Password',
                      icon: Icons.lock,
                      ctrl: _passwordCtrl,
                      isObscure: true,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'SIGN UP' : 'SIGN IN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {
                        _isSignUp = !_isSignUp;
                        _error = null;
                      }),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign In'
                            : 'No account? Sign Up',
                        style: const TextStyle(
                          color: AppColors.secondaryAccent2,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _skipLogin,
                      child: const Text(
                        'Skip Login (Demo Mode)',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController ctrl,
    bool isObscure = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primaryAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryAccent.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryAccent,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
      ),
    );
  }
}
