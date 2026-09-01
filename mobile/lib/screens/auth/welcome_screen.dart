import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../legal/app_readme.dart';
import '../../legal/privacy_policy.dart';
import '../../legal/service_agreement.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/splash_screen.dart';
import '../../widgets/app_emblem.dart';
import '../../widgets/google_mark.dart';
import '../../widgets/legal_document_card.dart';

/// First screen: accept Terms, Privacy, and README, then sign in with Google.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    AuthService.readAgreementAccepted().then((accepted) {
      if (mounted) setState(() => _accepted = accepted);
    });
  }

  Future<void> _setAccepted(bool value) async {
    setState(() => _accepted = value);
    await ref.read(authServiceProvider).persistAgreementAccepted(value);
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).enterSkippedGuest();
    } catch (error) {
      if (!mounted) return;
      _showMessage('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
    if (_busy || !_accepted) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).signInWithGoogle();
    } on AuthException catch (error) {
      if (!mounted) return;
      if (error.message == 'Sign-in cancelled') {
        _showMessage('Google Sign-In was cancelled.');
        return;
      }
      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;
      _showMessage('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  children: [
                    const AppEmblem(size: 96),
                    const SizedBox(height: 12),
                    const Text(
                      'Energy Eniwhere',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const AppMottoBanner(compact: true),
                    const SizedBox(height: 10),
                    Text(
                      'Read the Terms of use, Privacy notice, and README, tick that you agree, '
                      'then continue with Google. Skip opens only the Stations map.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LegalDocumentCard(
                      title: ServiceAgreement.title,
                      subtitle: ServiceAgreement.subtitle,
                      sections: ServiceAgreement.sections,
                      initiallyExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    LegalDocumentCard(
                      title: PrivacyPolicy.title,
                      subtitle: PrivacyPolicy.subtitle,
                      sections: PrivacyPolicy.sections,
                    ),
                    const SizedBox(height: 12),
                    LegalDocumentCard(
                      title: AppReadme.title,
                      subtitle: AppReadme.subtitle,
                      sections: AppReadme.sections,
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white,
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _accepted,
                        onChanged: _busy
                            ? null
                            : (value) => _setAccepted(value ?? false),
                        activeColor: AppColors.primaryBlue,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'I have read the Terms of use, Privacy notice and README and I agree',
                          style: TextStyle(
                            color: Color(0xFF111111),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: (_busy || !_accepted) ? null : _signIn,
                          icon: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const GoogleMark(),
                          label: Text(
                            _busy ? 'Signing in…' : 'I agree — Continue with Google',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textPrimary,
                            disabledBackgroundColor: const Color(0xFFE8E8ED),
                            disabledForegroundColor: const Color(0xFF636366),
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFFD1D1D6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (!_accepted) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Tick the box after you have read the documents.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF636366),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _busy ? null : _skip,
                        child: const Text('Skip — map only'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
