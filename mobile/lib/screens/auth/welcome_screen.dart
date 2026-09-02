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

/// First screen: accept Terms, then pick an account. Only Google is live.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;
  bool _loaded = false;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    AuthService.readAgreementAccepted().then((accepted) {
      if (mounted) {
        setState(() {
          _accepted = accepted;
          _loaded = true;
        });
      }
    });
  }

  Future<void> _setAccepted(bool value) async {
    setState(() => _accepted = value);
    try {
      await ref.read(authServiceProvider).persistAgreementAccepted(value);
    } catch (_) {
      // Tick is local; prefs must not block agreeing.
    }
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

  Future<void> _signInGoogle() async {
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

  void _comingSoon(String name) {
    if (!_accepted) {
      _showMessage('Tick the box after you have read the documents.');
      return;
    }
    _showMessage('$name is coming soon. Sign in with Google for now.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
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
                    if (!_loaded)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    else if (_accepted)
                      Text(
                        'You already accepted the Terms. Sign in to continue. '
                        'The full documents stay in Account → Legal. '
                        'They appear here again only after you delete your data.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      )
                    else ...[
                      Text(
                        'Read the Terms of use, Privacy notice, and README, then tick that you agree. '
                        'Sign in with Google. Other accounts are listed but not active yet.',
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
                  ],
                ),
              ),
              Material(
                color: Colors.white,
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_accepted) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _accepted,
                              onChanged: (_busy || !_loaded)
                                  ? null
                                  : (value) => _setAccepted(value ?? false),
                              activeColor: AppColors.primaryBlue,
                              checkColor: Colors.white,
                            ),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'I have read the Terms of use, Privacy notice and README and I agree',
                                  style: TextStyle(
                                    color: Color(0xFF111111),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6, top: 4),
                          child: Text(
                            'Sign in with',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF3A3A3C),
                            ),
                          ),
                        ),
                      ),
                      _AccountButton(
                        enabled: !_busy && _loaded && _accepted,
                        busy: _busy,
                        icon: const GoogleMark(size: 20),
                        label: _busy ? 'Signing in…' : 'Google',
                        onTap: () {
                          if (!_accepted) {
                            _showMessage(
                              'Tick the box after you have read the documents.',
                            );
                            return;
                          }
                          _signInGoogle();
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _AccountButton(
                              enabled: false,
                              icon: const Icon(Icons.phone_iphone, size: 20),
                              label: 'iPhone',
                              soon: true,
                              onTap: () => _comingSoon('iPhone (Apple)'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _AccountButton(
                              enabled: false,
                              icon: const Icon(Icons.laptop_mac, size: 20),
                              label: 'Mac',
                              soon: true,
                              onTap: () => _comingSoon('Mac (Apple)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _AccountButton(
                              enabled: false,
                              icon: const Icon(Icons.desktop_windows, size: 20),
                              label: 'Microsoft',
                              soon: true,
                              onTap: () => _comingSoon('Microsoft'),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _AccountButton(
                              enabled: false,
                              icon: const Icon(Icons.facebook, size: 20),
                              label: 'Facebook',
                              soon: true,
                              onTap: () => _comingSoon('Facebook'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _AccountButton(
                        enabled: false,
                        icon: const Icon(Icons.email_outlined, size: 20),
                        label: 'Email',
                        soon: true,
                        onTap: () => _comingSoon('Email'),
                      ),
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

class _AccountButton extends StatelessWidget {
  const _AccountButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.busy = false,
    this.soon = false,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool busy;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    final live = enabled && !soon;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: live ? AppColors.textPrimary : const Color(0xFF8E8E93),
          backgroundColor: live ? Colors.white : const Color(0xFFF2F2F7),
          side: BorderSide(
            color: live ? const Color(0xFFD1D1D6) : const Color(0xFFE5E5EA),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconTheme(
                data: IconThemeData(
                  color: live ? const Color(0xFF111111) : const Color(0xFF8E8E93),
                  size: 20,
                ),
                child: icon,
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                soon ? '$label — soon' : label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: live ? const Color(0xFF111111) : const Color(0xFF8E8E93),
                ),
              ),
            ),
            if (soon) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock_outline, size: 14, color: Color(0xFF8E8E93)),
            ],
          ],
        ),
      ),
    );
  }
}
