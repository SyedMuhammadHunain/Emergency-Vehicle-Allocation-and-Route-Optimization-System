import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/brand/gradient_header.dart';
import '../../../core/widgets/buttons/primary_gradient_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              height: 180,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
                    child: Text(
                      'Reset Password',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _sent
                          ? Column(
                              children: [
                                const Icon(
                                  Icons.mark_email_read_rounded,
                                  color: AppColors.primaryTeal,
                                  size: 56,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Reset Link Sent',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'A password recovery link has been sent to ${_emailController.text.trim()}. (Simulated Demo)',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                                ),
                                const SizedBox(height: 24),
                                PrimaryGradientButton(
                                  label: 'Back to Sign In',
                                  onPressed: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/login');
                                    }
                                  },
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Forgot your password?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Enter your registered email address and we will send you recovery instructions.',
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                                ),
                                const SizedBox(height: 20),
                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hint: 'e.g., yourname@mail.com',
                                  prefixIcon: Icons.email_outlined,
                                ),
                                const SizedBox(height: 12),
                                PrimaryGradientButton(
                                  label: 'Send Recovery Email',
                                  onPressed: () {
                                    if (_emailController.text.contains('@')) {
                                      setState(() => _sent = true);
                                    }
                                  },
                                ),
                              ],
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
