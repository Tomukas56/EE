import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../legal/privacy_policy.dart';
import '../../legal/service_agreement.dart';
import '../../legal/third_party_services.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sessions_provider.dart';
import '../../providers/stations_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/legal_document_card.dart';

class LegalAccountScreen extends ConsumerStatefulWidget {
  const LegalAccountScreen({super.key});

  @override
  ConsumerState<LegalAccountScreen> createState() => _LegalAccountScreenState();
}

class _LegalAccountScreenState extends ConsumerState<LegalAccountScreen> {
  bool _busy = false;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDelete() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all my data?'),
        content: const Text(
          'This removes your session, vehicle profile, and legal tick from this device. '
          'The lab API will delete charging sessions, arrival reports, and pending station marks '
          'for your reporter id. Stations already published on the map stay; your name is removed from them.\n\n'
          'This cannot be undone. Google’s own account is not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    await _erase();
  }

  Future<void> _erase() async {
    setState(() => _busy = true);
    String? serverError;
    try {
      final user = ref.read(sessionProvider);
      final reporterId = labReporterId(user);
      try {
        await ref.read(apiServiceProvider).eraseAccount(reporterId);
      } catch (error) {
        serverError = '$error';
      }
      await ref.read(vehicleProvider.notifier).clear();
      await ref.read(sessionProvider.notifier).afterRemoteErase();
      if (!mounted) return;
      if (serverError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This device was wiped. Server erase failed — rows may remain. $serverError',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final limited = ref.watch(sessionProvider)?.limitedAccess == true;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Legal & privacy'),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (limited) ...[
            Material(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'You have not accepted the Terms yet. Skip is only a map preview for this session.',
                  style: TextStyle(fontSize: 13, height: 1.35),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(sessionProvider.notifier).signOut(),
                icon: const Icon(Icons.login),
                label: const Text('Sign in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
          _ThirdPartyCard(onOpen: _open),
          if (!limited) ...[
            const SizedBox(height: 24),
            const Text(
              'Delete all my data',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Erasure covers this device and lab server rows for your reporter id (GDPR Art. 17). '
              'It does not close your Google account.',
              style: TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF3A3A3C)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _confirmDelete,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.delete_forever),
                label: Text(_busy ? 'Deleting…' : 'Delete all my data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ThirdPartyCard extends StatelessWidget {
  const _ThirdPartyCard({required this.onOpen});

  final Future<void> Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              ThirdPartyServices.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              ThirdPartyServices.subtitle,
              style: TextStyle(color: Color(0xFF3A3A3C), fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              ThirdPartyServices.intro,
              style: TextStyle(color: Color(0xFF111111), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            for (final item in ThirdPartyServices.items) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text(item.role, style: const TextStyle(fontSize: 12, height: 1.3)),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => onOpen(item.privacyUrl),
                    child: const Text('Privacy'),
                  ),
                  TextButton(
                    onPressed: () => onOpen(item.termsUrl),
                    child: const Text('Terms'),
                  ),
                ],
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}
