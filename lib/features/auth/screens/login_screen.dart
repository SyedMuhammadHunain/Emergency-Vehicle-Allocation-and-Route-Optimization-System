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
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/inputs/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = context.read<MockRepository>();
      final session = context.read<SessionService>();

      final account = await session.loginWithCredentials(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        repo,
      );

      if (!mounted) return;

      if (account == null) {
        setState(() {
          _errorMessage =
              'Invalid credentials. Please use the valid DEMO MODE credentials listed below.';
          _isLoading = false;
        });
        return;
      }

      // Valid account: navigate directly to corresponding dashboard
      context.go('/role-shell');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Authentication error: $e';
          _isLoading = false;
        });
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
            // Gradient Header with official ResQ logo and concentric rings
            GradientHeader(
              height: 230,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: ResQWordmark(
                          fontSize: 20,
                          isLightBackground: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ResQ',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Emergency Response System · Karachi Grid',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Responsive Form Card (max width 480px on desktop/tablet)
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
                              'Sign In',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to access your role-based emergency portal',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Error banner if invalid credentials
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.statusMaintenance.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.statusMaintenance.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.statusMaintenance,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.statusMaintenance,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email input
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email address',
                              hint: 'e.g. citizen@resq.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter your email address';
                                }
                                if (!val.contains('@')) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),

                            // Password input
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Enter your password',
                              prefixIcon: Icons.lock_outline_rounded,
                              isPassword: true,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),

                            // Remember Me & Forgot Password
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: AppColors.primaryTeal,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (val) =>
                                            setState(() => _rememberMe = val ?? true),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Remember me',
                                      style: GoogleFonts.inter(fontSize: 12),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => context.push('/forgot-password'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkAccent
                                          : AppColors.lightAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Sign In CTA
                            PrimaryGradientButton(
                              label: 'Sign In',
                              isLoading: _isLoading,
                              onPressed: _handleLogin,
                            ),

                            const SizedBox(height: 12),

                            // Citizen Sign Up Button (Public account creation)
                            SecondaryButton(
                              label: "Don't have an account? Sign Up (Citizen)",
                              onPressed: () => context.push('/register'),
                            ),

                            const SizedBox(height: 24),

                            // DEMO ACCOUNTS QUICK-FILL SECTION (Strictly labeled DEMO MODE)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.darkBg
                                        : AppColors.lightBg)
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.statusPending,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'DEMO MODE CREDENTIALS',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: AppColors.statusPending,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap any role below to prefill its credentials, then tap "Sign In":',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildDemoChip('Citizen', 'citizen@resq.com', 'Citizen123', Icons.person_rounded),
                                      _buildDemoChip('Dispatcher', 'dispatcher@resq.com', 'Dispatch123', Icons.headset_mic_rounded),
                                      _buildDemoChip('Driver', 'driver@resq.com', 'Driver123', Icons.directions_car_rounded),
                                      _buildDemoChip('Admin', 'admin@resq.com', 'Admin123', Icons.admin_panel_settings_rounded),
                                    ],
                                  ),
                                ],
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

  Widget _buildDemoChip(String roleName, String email, String password, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primaryTeal),
      label: Text(
        '$roleName ($email)',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      side: BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      ),
      onPressed: () => _fillDemoCredentials(email, password),
    );
  }
}
