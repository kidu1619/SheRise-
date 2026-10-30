import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repository.dart';
import '../i18n.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final signedIn = Repo.signedIn;
    final name = Repo.displayName ?? (signedIn ? tr('Your account') : tr('Guest'));

    return PageBody(
      title: 'Profile & help',
      showLanguageButton: false,
      children: [
        AppCard(
          child: Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: C.tint,
              child: Tx(name[0].toUpperCase(),
                  style: const TextStyle(
                      color: C.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Tx(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 17)),
                Tx(
                    signedIn
                        ? (Repo.email ?? 'Signed in')
                        : 'Using SheRise without an account',
                    style: const TextStyle(color: C.muted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        if (!signedIn)
          PrimaryButton(
              label: 'Sign in or create access',
              onPressed: () => context.go('/signin')),
        const SectionTitle('Privacy & safety'),
        _Setting(
          icon: Icons.language,
          title: 'Language',
          sub: language,
          onTap: () => showLanguagePicker(context),
        ),
        _Setting(
          icon: Icons.shield_outlined,
          title: 'Safety Center',
          sub: 'Trusted contact, safety plan, emergency information',
          onTap: () => context.push('/home/safety'),
        ),
        _Setting(
          icon: Icons.folder_open,
          title: 'My Cases',
          sub: 'Private updates for saved reports',
          onTap: () => context.push('/home/cases'),
        ),
        const _Setting(
          icon: Icons.lock_outline,
          title: 'App lock & discreet mode',
          sub: 'PIN or biometric lock arrives with the Android build',
        ),
        const _Setting(
          icon: Icons.exit_to_app,
          title: 'Quick exit',
          sub:
              'Use the Quick exit button on safety screens. Long-press the title on the Notes page to return.',
        ),
        const SectionTitle('Help & information'),
        _Info('How SheRise works',
            'SheRise helps you find support, report concerns privately and discover opportunities. It is a support and referral platform. It is not an emergency service, a law-enforcement system or an official legal complaint authority.'),
        _Info('What anonymous means',
            'An anonymous report has no name, email or account attached. Details you write, evidence, or device information could still reveal who you are, so anonymity cannot be guaranteed.'),
        _Info('What we store',
            'Only what is needed: your report details and a hash of your access code on the server, and optional account details. Your trusted contact, saved case codes and safety plan stay on this device only.'),
        _Info('Emergencies',
            'If you may be in danger now, move to a safer place if possible and use a verified local emergency resource or someone you trust. Reports here are not monitored in real time.'),
        const SectionTitle('Your data'),
        SecondaryButton(
          label: 'Delete data on this device',
          icon: Icons.delete_outline,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Tx('Delete data on this device?'),
              content: const Tx(
                  'This removes saved case codes, your trusted contact, your safety plan and language choice from this device. It does not delete reports already submitted.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Tx('Cancel')),
                FilledButton(
                  onPressed: () async {
                    await clearAllLocalData();
                    ref.invalidate(casesProvider);
                    ref.invalidate(contactProvider);
                    ref.invalidate(planProvider);
                    ref.invalidate(languageProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) snack(context, 'Data removed from this device.');
                  },
                  child: const Tx('Delete'),
                ),
              ],
            ),
          ),
        ),
        if (signedIn)
          SecondaryButton(
            label: 'Sign out',
            icon: Icons.logout,
            onPressed: () async {
              await Repo.signOut();
              if (context.mounted) context.go('/welcome');
            },
          ),
        const SizedBox(height: 8),
        const Center(
          child: Tx('SheRise 0.1 · Safe. Respected. Equal.',
              style: TextStyle(fontSize: 12, color: C.muted)),
        ),
      ],
    );
  }
}

class _Setting extends StatelessWidget {
  const _Setting(
      {required this.icon, required this.title, required this.sub, this.onTap});
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        bottom: 8,
        child: Row(children: [
          Icon(icon, color: C.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Tx(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Tx(sub,
                  style: const TextStyle(fontSize: 12, color: C.muted, height: 1.35)),
            ]),
          ),
          if (onTap != null) const Icon(Icons.chevron_right, color: C.muted),
        ]),
      );
}

class _Info extends StatelessWidget {
  const _Info(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AppCard(
        bottom: 8,
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Tx(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [Tx(body, style: const TextStyle(height: 1.5, fontSize: 13))],
        ),
      );
}
