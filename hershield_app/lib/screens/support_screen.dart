import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../data/repository.dart';
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

  static const _filters = [
    'all',
    'counseling',
    'legal_aid',
    'gbv_support',
    'health',
    'shelter',
  ];

  @override
  Widget build(BuildContext context) {
    return PageBody(
      showBack: true,
      fallback: '/home',
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
                onAction: () => setState(() => _future = Repo.services()),
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
            return Column(children: [for (final s in list) _ServiceCard(s)]);
          },
        ),
        const InfoBox(
          icon: Icons.info_outline,
          title: 'SheRise does not run these services',
          text:
              'Listings are checked before they appear, but please confirm details directly before relying on them.',
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Back to home',
          icon: Icons.arrow_back,
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ],
    );
  }
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
            child: Tx(
                [s.city, s.languages].where((e) => e.isNotEmpty).join(' · '),
                style: const TextStyle(color: C.muted, fontSize: 12)),
          ),
        if (s.eligibility.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Tx(s.eligibility,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        const SizedBox(height: 12),
        if (s.phone == null && s.email == null)
          const Tx('Contact details are added after verification.',
              style: TextStyle(fontSize: 12, color: C.muted))
        else
          Row(children: [
            if (s.phone != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:${s.phone}')),
                  icon: const Icon(Icons.call, size: 18),
                  label: const Tx('Call'),
                ),
              ),
            if (s.phone != null && s.email != null) const SizedBox(width: 8),
            if (s.email != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('mailto:${s.email}')),
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Tx('Email'),
                ),
              ),
          ]),
      ]),
    );
  }
}
