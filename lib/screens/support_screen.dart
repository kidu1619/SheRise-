import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late Future<List<ServiceListing>> _future = Repo.services();
  String _filter = 'all';
  Timer? _refreshTimer;

  static const _filters = [
    'all',
    'counseling',
    'legal_aid',
    'gbv_support',
    'health',
    'shelter',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-refresh every 5 minutes.
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) setState(() => _future = Repo.services());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refresh() => setState(() => _future = Repo.services());

  @override
  Widget build(BuildContext context) {
    return PageBody(
      title: 'SupportConnect',
      subtitle: 'Find trusted counseling, legal-aid and support services.',
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final f in _filters)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Tx(f == 'all' ? 'All' : kindLabels[f]!),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        FutureBuilder<List<ServiceListing>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) {
              return StateView(
                icon: Icons.wifi_off,
                title: 'Could not load services',
                message: 'Check your connection and try again.',
                actionLabel: 'Try again',
                onAction: _refresh,
              );
            }
            final list = (snap.data ?? [])
                .where((s) => _filter == 'all' || s.kind == _filter)
                .toList();
            if (list.isEmpty) {
              return const StateView(
                icon: Icons.search_off,
                title: 'Nothing here yet',
                message:
                    'No verified services match this filter. Try another category.',
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: Column(
                  children: [for (final s in list) _ServiceCard(s)]),
            );
          },
        ),
        const InfoBox(
          icon: Icons.info_outline,
          title: 'SheRise does not run these services',
          text:
              'Listings are checked before they appear, but please confirm details directly before relying on them.',
        ),
        // ── Emergency / Get Help section ─────────────────────────────────────
        AppCard(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: const Icon(Icons.health_and_safety_outlined,
                color: C.primary),
            title: const Tx('Get help now — crisis lines',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            childrenPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Tx(
                'If you are in danger, contact one of the numbers below. '
                'SheRise does not contact emergency services automatically.',
                style: TextStyle(fontSize: 13, color: C.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              _CrisisRow(
                label: 'Ethiopia Police Emergency',
                number: '911',
                icon: Icons.local_police_outlined,
              ),
              _CrisisRow(
                label: 'Addis Ababa GBV Hotline',
                number: '8700',
                icon: Icons.call,
              ),
              _CrisisRow(
                label: 'Addis Ababa Rape Crisis Center',
                number: '011-553-5657',
                icon: Icons.support_agent,
              ),
              _CrisisRow(
                label: 'EWLA Legal Aid Helpline',
                number: '011-551-7804',
                icon: Icons.gavel_outlined,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Tx('Find more resources online'),
                onPressed: () => launchUrl(
                  Uri.parse('https://www.unwomen.org'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single crisis-line row with a direct-dial button.
class _CrisisRow extends StatelessWidget {
  const _CrisisRow({
    required this.label,
    required this.number,
    required this.icon,
  });
  final String label;
  final String number;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, size: 18, color: C.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Tx(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(number,
                  style: const TextStyle(color: C.muted, fontSize: 12)),
            ]),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10)),
            onPressed: () => launchUrl(
              Uri.parse('tel:$number'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.call, size: 16),
            label: const Tx('Call'),
          ),
        ]),
      );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard(this.s);
  final ServiceListing s;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          Pill(kindLabels[s.kind] ?? s.kind),
          s.verified
              ? const Pill('Verified', bg: C.okBg, fg: C.ok)
              : const Pill('Sample listing', bg: C.warnBg, fg: C.warn),
        ]),
        const SizedBox(height: 10),
        Tx(s.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        if (s.city.isNotEmpty || s.languages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ValueListenableBuilder<String>(
              valueListenable: languageNotifier,
              builder: (_, lang, _) => Text(
                [s.city, s.languages]
                    .where((e) => e.isNotEmpty)
                    .map((e) => trFor(lang, e))
                    .join(' · '),
                style: const TextStyle(color: C.muted, fontSize: 12),
              ),
            ),
          ),
        if (s.eligibility.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Tx(s.eligibility,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        const SizedBox(height: 12),
        if (s.phone == null && s.email == null && s.url == null)
          const Tx('Contact details are added after verification.',
              style: TextStyle(fontSize: 12, color: C.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (s.phone != null)
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('tel:${s.phone}'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Tx('Call'),
                ),
              if (s.email != null)
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('mailto:${s.email}'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Tx('Email'),
                ),
              if (s.url != null)
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(s.url!),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Tx('Visit website'),
                ),
            ],
          ),
      ]),
    );
  }
}
