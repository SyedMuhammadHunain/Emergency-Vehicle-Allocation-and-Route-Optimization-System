import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_repository.dart';
import '../../../core/services/session_service.dart';
import '../../../core/widgets/brand/gradient_header.dart';
import '../../../core/widgets/brand/resq_wordmark.dart';
import '../../../core/widgets/buttons/primary_gradient_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = context.read<MockRepository>();
      final session = context.read<SessionService>();

      // Registers as citizen in centralized mock repository
      final account = repo.registerCitizen(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
      );

      // Automatically saves session
      await session.loginAsRegisteredCitizen(account);

      if (mounted) {
        // Direct navigation to Citizen Dashboard without re-login
        context.go('/role-shell');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusMaintenance,
            content: Text('Registration error: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              height: 200,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      tooltip: 'Back to Sign In',
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/login');
                        }
                      },
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ResQWordmark(fontSize: 26),
                        const SizedBox(height: 6),
                        Text(
                          'Citizen Registration',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create Citizen Account',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Staff roles (Dispatcher, Driver, Admin) are provisioned by agency administration.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),

                            CustomTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'e.g., Ali Khan',
                              prefixIcon: Icons.badge_outlined,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Required' : null,
                            ),

                            CustomTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'e.g., ali@mail.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) =>
                                  val == null || !val.contains('@') ? 'Enter a valid email' : null,
                            ),

                            CustomTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: 'e.g., +92 300 1234567',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'Required' : null,
                            ),

                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Create a secure password',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (val) =>
                                  val == null || val.length < 6 ? 'Minimum 6 characters' : null,
                            ),

                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hint: 'Re-enter your password',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (val) {
                                if (val != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 10),

                            PrimaryGradientButton(
                              label: 'Create Account',
                              isLoading: _isLoading,
                              onPressed: _handleRegister,
                            ),

                            const SizedBox(height: 12),

                            TextButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/login');
                                }
                              },
                              child: Text(
                                'Already have an account? Sign In',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkAccent
                                      : AppColors.lightAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
