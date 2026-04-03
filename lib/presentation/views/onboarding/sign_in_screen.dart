import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/auth_service.dart';
import '../../theme/app_theme.dart';
import '../shared/terms_view.dart';

/// Step 1 of onboarding — sign in with Apple (iOS) or Google (Android).
/// Mandatory: the user cannot proceed without signing in so that all data
/// is tied to a Firebase UID from the very first habit created.
class SignInScreen extends StatefulWidget {
  final VoidCallback onNext;
  const SignInScreen({super.key, required this.onNext});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _showContent = false;
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => TermsView.show(context);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  void dispose() {
    _termsTap.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn(AuthService auth) async {
    await auth.signIn();
    if (!mounted) return;
    if (auth.isAuthenticated) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isApple = AuthService.isApplePlatform;

    return Column(children: [
      Expanded(
        child: AnimatedOpacity(
          opacity: _showContent ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: AnimatedSlide(
            offset: _showContent ? Offset.zero : const Offset(0, 0.08),
            duration: const Duration(milliseconds: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        MyWalkColor.golden.withValues(alpha: 0.2),
                        MyWalkColor.golden.withValues(alpha: 0.04),
                      ]),
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      size: 32,
                      color: MyWalkColor.golden,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Heading
                  const Text(
                    'Your walk,\nalways with you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: MyWalkColor.warmWhite,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sub-heading
                  Text(
                    'Sign in so your habits, practices, and progress'
                    ' are safely backed up and available on any device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Privacy note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MyWalkColor.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MyWalkColor.cardBorder, width: 0.5),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.security_rounded,
                          size: 16, color: MyWalkColor.golden.withValues(alpha: 0.7)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'We never share your data. Sign-in is used only to'
                          ' keep your habits & practices safe and synced across your devices.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.45),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ]),
                  ),

                  // Error
                  if (auth.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      auth.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: MyWalkColor.warmCoral),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),

      // Bottom CTA
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: auth.isLoading ? null : () => _handleSignIn(auth),
              icon: auth.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MyWalkColor.charcoal),
                    )
                  : Icon(
                      isApple ? Icons.apple : Icons.g_mobiledata_rounded,
                      size: 20,
                    ),
              label: Text(
                auth.isLoading
                    ? 'Signing in\u2026'
                    : isApple
                        ? 'Continue with Apple'
                        : 'Continue with Google',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyWalkColor.golden,
                foregroundColor: MyWalkColor.charcoal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3)),
              children: [
                const TextSpan(text: 'By continuing you agree to our '),
                TextSpan(
                  text: 'Terms of Service and Privacy Policy',
                  style: const TextStyle(
                    color: MyWalkColor.softGold,
                    decoration: TextDecoration.underline,
                    decorationColor: MyWalkColor.softGold,
                  ),
                  recognizer: _termsTap,
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ]),
      ),
    ]);
  }
}
