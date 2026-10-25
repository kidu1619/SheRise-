import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../theme.dart';
import '../widgets.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _tab = 0;
  late Future<List<Opportunity>> _future = Repo.opportunities();
  String _filter = 'all';

  static const _filters = [
    'all',
    'scholarship',
    'internship',
    'job',
    'training',
    'mentorship',
  ];

  @override
  Widget build(BuildContext context) {
    return PageBody(
      title: 'Explore',
      subtitle: 'Opportunities to grow, and knowledge to stay safe and strong.',
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Tx('Opportunities')),
              ButtonSegment(value: 1, label: Tx('Learn')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
        ),
        const SizedBox(height: 16),
        if (_tab == 0) ..._opportunities() else ..._learn(),
      ],
    );
  }

  List<Widget> _opportunities() => [
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
        FutureBuilder<List<Opportunity>>(
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
                title: 'Could not load opportunities',
                message: 'Check your connection and try again.',
                actionLabel: 'Try again',
                onAction: () => setState(() => _future = Repo.opportunities()),
              );
            }
            final list = (snap.data ?? [])
                .where((o) => _filter == 'all' || o.kind == _filter)
                .toList();
            if (list.isEmpty) {
              return const StateView(
                icon: Icons.search_off,
                title: 'No listings yet',
                message: 'Nothing matches this filter. Check back soon.',
              );
            }
            return Column(children: [
              for (final o in list)
                AppCard(
                  onTap: () => _showDetails(o),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pill(
                            '${o.sample ? 'Sample listing · ' : ''}${kindLabels[o.kind] ?? o.kind}'),
                        const SizedBox(height: 10),
                        Tx(o.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Tx(
                            [o.location, o.deadline]
                                .where((e) => e.isNotEmpty)
                                .join(' · '),
                            style:
                                const TextStyle(color: C.muted, fontSize: 12)),
                        const SizedBox(height: 8),
                        const Tx('View details →',
                            style: TextStyle(
                                color: C.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ]),
                ),
            ]);
          },
        ),
        const InfoBox(
          icon: Icons.verified_outlined,
          title: 'Fair and transparent',
          text:
              'Listings should state who can apply and how. A real opportunity should never ask you to pay to apply.',
        ),
      ];

  void _showDetails(Opportunity o) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Pill(kindLabels[o.kind] ?? o.kind),
            const SizedBox(height: 10),
            Tx(o.title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Tx([o.location, o.deadline].where((e) => e.isNotEmpty).join(' · '),
                style: const TextStyle(color: C.muted)),
            const SizedBox(height: 14),
            if (o.summary.isNotEmpty) Tx(o.summary),
            if (o.eligibility.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Tx('Who can apply',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Tx(o.eligibility),
            ],
            const SizedBox(height: 18),
            if (o.url != null)
              PrimaryButton(
                  label: 'Open application page',
                  icon: Icons.open_in_new,
                  onPressed: () => launchUrl(Uri.parse(o.url!))),
            if (o.sample)
              const Tx('This is a sample listing for demonstration.',
                  style: TextStyle(fontSize: 12, color: C.muted)),
          ]),
        ),
      ),
    );
  }

  List<Widget> _learn() {
    const topics = [
      (
        'Understanding harassment and discrimination',
        'Harassment is unwelcome behavior that offends, intimidates or humiliates you. It can be spoken, written, physical or online. Discrimination is unfair treatment because of who you are, such as your gender. If something feels wrong, your feelings are valid even if you are unsure what to call it.'
      ),
      (
        'Consent and respectful relationships',
        'Consent is a clear, freely given yes, and it can be withdrawn at any time. Silence is not consent. Pressure, threats, or being unable to decide freely mean there is no consent. Respect means listening to a no without punishment.'
      ),
      (
        'Digital privacy and online safety',
        'Use a strong, different password for each account and turn on two-step verification. Review who can see your posts, photos and location. Block and report people who harass you. Keep evidence such as screenshots somewhere only you can reach.'
      ),
      (
        'Writing down what happened, safely',
        'If you can, note the date, time, place and what happened soon after. Store notes somewhere private, not on a shared device. You never have to confront someone if it feels unsafe.'
      ),
      (
        'Supporting someone who is being harassed',
        'Listen without blaming. Believe them. Ask what they need and respect their choices. Share options without pressure, and look after yourself too.'
      ),
      (
        'Your rights and where to get help',
        'Laws and services differ from place to place. A verified legal-aid or support service can explain your rights where you live. SheRise does not give legal advice.'
      ),
    ];

    return [
      for (final t in topics)
        AppCard(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            title: Tx(t.$1,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Tx(t.$2, style: const TextStyle(height: 1.5))],
          ),
        ),
      const InfoBox(
        icon: Icons.menu_book_outlined,
        title: 'Reviewed content is coming',
        text:
            'This guidance is general. It will be reviewed by subject-matter experts and localized before launch.',
      ),
    ];
  }
}
