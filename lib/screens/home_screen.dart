import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final name = Repo.displayName;
    final featured = sampleOpportunities.first;

    return PageBody(
      children: [
        Row(
          children: [
            const BrandMark(size: 32),
            const SizedBox(width: 8),
            const Tx(
              'SheRise',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            IconButton.filledTonal(
              tooltip: tr('Language'),
              onPressed: () => showLanguagePicker(context),
              icon: const Icon(Icons.language),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: StateView(
                    icon: Icons.notifications_none,
                    title: 'No new notifications',
                    message: 'Private notifications never show report details on your lock screen.',
                  ),
                ),
              ),
              icon: const Icon(Icons.notifications_none),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<String>(
          valueListenable: languageNotifier,
          builder: (_, lang, _) => Text(
            formatLocalizedDateWithDay(DateTime.now(), lang),
            style: const TextStyle(
              fontSize: 11,
              color: C.muted,
              letterSpacing: .6,
            ),
          ),
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder<String>(
          valueListenable: languageNotifier,
          builder: (_, lang, _) => Tx(
            name == null
                ? trFor(lang, 'Hello')
                : '${trFor(lang, 'Hello')}, $name',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          color: C.tint,
          border: C.tintBorder,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Pill('Here, you come first', bg: Colors.white),
              const SizedBox(height: 14),
              const Tx(
                'A safer today.\nA stronger tomorrow.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Tx(
                'Your safety. Your voice. Your future.',
                style: TextStyle(color: C.muted),
              ),
            ],
          ),
        ),
        AppCard(
          color: C.dangerBg,
          border: const Color(0xFFF5C6CA),
          onTap: () => context.push('/home/safety'),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: C.danger),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tx(
                      'SOS / Safety Center',
                      style: TextStyle(
                        color: C.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Tx(
                      'Emergency information & trusted contacts',
                      style: TextStyle(fontSize: 12, color: C.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.north_east, color: C.danger, size: 18),
            ],
          ),
        ),
        const SectionTitle('How can we help?'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Tile(
                Icons.chat_bubble_outline,
                'SafeVoice',
                'Speak up, your way',
                () => context.go('/report'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tile(
                Icons.favorite_border,
                'SupportConnect',
                'Find someone to help',
                () => context.go('/support'),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Tile(
                Icons.school_outlined,
                'EqualOpportunity',
                'Build your next chapter',
                () => context.go('/explore'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tile(
                Icons.folder_open,
                'My Cases',
                'View private updates',
                () => context.push('/home/cases'),
              ),
            ),
          ],
        ),
        SectionTitle(
          'A step toward your future',
          actionLabel: 'Explore all',
          onAction: () => context.go('/explore'),
        ),
        AppCard(
          onTap: () => context.go('/explore'),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                color: C.tint,
                child: const Icon(
                  Icons.laptop_chromebook,
                  size: 52,
                  color: C.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Pill('Sample listing · Training'),
                    const SizedBox(height: 10),
                    Tx(
                      featured.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ValueListenableBuilder<String>(
                      valueListenable: languageNotifier,
                      builder: (_, lang, _) => Text(
                        '${trFor(lang, featured.location)} · ${trFor(lang, featured.deadline)}',
                        style: const TextStyle(color: C.muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const InfoBox(
          icon: Icons.lightbulb_outline,
          title: 'A small safety habit',
          text: 'On a shared device, lock SheRise before you step away. Keep private access codes somewhere only you can reach.',
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.sub, this.onTap);
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: C.tint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: C.primary, size: 20),
        ),
        const SizedBox(height: 12),
        Tx(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Tx(sub, style: const TextStyle(color: C.muted, fontSize: 12)),
      ],
    ),
  );
}
