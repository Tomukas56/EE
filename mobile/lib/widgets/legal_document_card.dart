import 'package:flutter/material.dart';

class LegalDocumentCard extends StatelessWidget {
  const LegalDocumentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
    this.initiallyExpanded = false,
  });

  final String title;
  final String subtitle;
  final List<({String heading, String body})> sections;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: const Color(0xFF111111),
          collapsedIconColor: const Color(0xFF111111),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF3A3A3C), fontSize: 13),
          ),
          children: [
            for (final section in sections) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  section.heading,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                section.body,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
