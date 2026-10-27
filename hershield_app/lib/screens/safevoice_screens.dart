import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../i18n.dart';
import '../services/location_service.dart';
import '../state.dart';
import '../theme.dart';
import 'evidence_section.dart';
import '../widgets.dart';

// ---------------------------------------------------------------- Start
class SafeVoiceStartScreen extends ConsumerWidget {
  const SafeVoiceStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(draftProvider);

    return PageBody(
      showBack: true,
      fallback: '/home',
      quickExit: true,
      title: 'Your voice matters.',
      subtitle:
          'Tell us what happened, in your own words. You are in control of how much you share.',
      children: [
        const InfoBox(
          icon: Icons.warning_amber_rounded,
          tone: Tone.warn,
          title: 'Not an emergency service',
          text:
              'If you may be in danger now, open the Safety Center. Reporting here does not call emergency services.',
        ),
        AppCard(
          color: C.tint,
          border: C.tintBorder,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Tx('Choose how to speak up',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            Tx('Anonymous', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Tx(
                'No name, email, phone or account is needed. Evidence and technical information may still reveal identity; anonymity cannot be guaranteed.',
                style: TextStyle(fontSize: 13, color: C.muted, height: 1.4)),
            SizedBox(height: 12),
            Tx('Confidential', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Tx(
                'Your report is linked to your account so authorized support staff can follow up, within the stated limits.',
                style: TextStyle(fontSize: 13, color: C.muted, height: 1.4)),
          ]),
        ),
        const SectionTitle('How reporting works'),
        AppCard(
          child: Column(children: const [
            _Step(1, 'Choose an incident category', 'Use a broad location, if you wish.'),
            SizedBox(height: 12),
            _Step(2, 'Share details at your own pace', 'Evidence is always optional.'),
            SizedBox(height: 12),
            _Step(3, 'Review privacy, then submit', 'Keep your private case access code.'),
          ]),
        ),
        PrimaryButton(
            label: 'Start a report',
            icon: Icons.arrow_forward,
            onPressed: () => context.push('/report/incident')),
        SecondaryButton(
            label: 'Resume private draft',
            icon: Icons.edit_note,
            onPressed: draft.isEmpty
                ? null
                : () => context.push('/report/incident')),
        SecondaryButton(
            label: 'Back to home',
            icon: Icons.arrow_back,
            onPressed: () => context.go('/home')),
        const Tx(
            'Drafts are kept only while the app stays open, because they can contain sensitive details.',
            style: TextStyle(fontSize: 12, color: C.muted)),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.n, this.title, this.sub);
  final int n;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) => Row(children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: C.tint,
          child: Tx('$n',
              style: const TextStyle(
                  fontSize: 12, color: C.primary, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Tx(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Tx(sub, style: const TextStyle(fontSize: 12, color: C.muted)),
          ]),
        ),
      ]);
}

// ------------------------------------------------------------- Incident
const _categories = <(String, IconData)>[
  ('Harassment', Icons.sentiment_dissatisfied_outlined),
  ('Discrimination', Icons.balance),
  ('Bullying', Icons.groups_outlined),
  ('Abuse', Icons.warning_amber_rounded),
  ('Disrespect', Icons.chat_bubble_outline),
  ('Unequal opportunity', Icons.school_outlined),
];

class IncidentScreen extends ConsumerStatefulWidget {
  const IncidentScreen({super.key});

  @override
  ConsumerState<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends ConsumerState<IncidentScreen> {
  late final TextEditingController _location;

  @override
  void initState() {
    super.initState();
    _location = TextEditingController(text: ref.read(draftProvider).location);
  }

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = ref.read(draftProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: d.date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(draftProvider.notifier).patch((x) => x.copyWith(date: picked));
    }
  }

  bool _fetchingLocation = false;

  Future<void> _fetchGPSLocation() async {
    setState(() => _fetchingLocation = true);
    final res = await LocationService.instance.getCurrentLocation();
    if (!mounted) return;
    setState(() => _fetchingLocation = false);
    if (res.success && res.locationString != null) {
      _location.text = res.locationString!;
      ref.read(draftProvider.notifier).patch((x) => x.copyWith(location: res.locationString!));
      snack(context, tr('Location added'));
    } else {
      snack(context, res.errorMessage ?? tr('Location permission denied'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(draftProvider);
    final notifier = ref.read(draftProvider.notifier);

    return PageBody(
      showBack: true,
      stepLabel: '10 / SAFEVOICE',
      quickExit: true,
      fallback: '/report',
      title: 'What would you like to report?',
      children: [
        const StepBar(1),
        const Tx(
            'Choose the closest category. You do not need to have every detail or be sure how to describe it.',
            style: TextStyle(color: C.muted, height: 1.4)),
        const SizedBox(height: 14),
        const Tx('Incident category · Required',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final c in _categories)
          OptionTile(
            title: c.$1,
            icon: c.$2,
            selected: d.category == c.$1,
            onTap: () => notifier.patch((x) => x.copyWith(category: c.$1)),
          ),
        const SizedBox(height: 8),
        const Tx('Approximate date (optional)',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        AppCard(
          onTap: _pickDate,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          bottom: 4,
          child: Row(children: [
            Expanded(
                child: Tx(
                    d.date == null
                        ? 'Choose a month'
                        : DateFormat('MMMM yyyy').format(d.date!),
                    style: TextStyle(
                        color: d.date == null ? C.muted : C.ink))),
            const Icon(Icons.calendar_today_outlined, size: 18, color: C.muted),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Tx('An approximate month is enough. You can leave this blank.',
              style: TextStyle(fontSize: 12, color: C.muted)),
        ),
        LabeledField(
          label: 'Broad location (optional)',
          controller: _location,
          hint: 'e.g. Addis Ababa or tap Use GPS Location',
          helper: 'A city, campus or GPS location. You can also leave this blank.',
          onChanged: (v) => notifier.patch((x) => x.copyWith(location: v)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: _fetchingLocation ? 'Getting GPS location...' : 'Use GPS location',
                icon: Icons.my_location,
                onPressed: _fetchingLocation ? null : _fetchGPSLocation,
              ),
            ),
            if (_location.text.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Clear location',
                onPressed: () {
                  _location.clear();
                  notifier.patch((x) => x.copyWith(location: ''));
                  setState(() {});
                },
                icon: const Icon(Icons.clear, size: 18),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const InfoBox(
          icon: Icons.location_on_outlined,
          title: 'Location stays your choice',
          text: 'You decide whether to attach GPS or leave the location blank.',
        ),
        PrimaryButton(
            label: 'Continue to details',
            onPressed: d.category == null
                ? null
                : () => context.push('/report/details')),
        SecondaryButton(
            label: 'Save private draft',
            onPressed: () =>
                snack(context, 'Draft kept while the app stays open.')),
        SecondaryButton(
            label: 'Back to start',
            icon: Icons.arrow_back,
            onPressed: () => context.canPop() ? context.pop() : context.go('/report')),
      ],
    );
  }
}

// -------------------------------------------------------------- Details
class DetailsScreen extends ConsumerStatefulWidget {
  const DetailsScreen({super.key});

  @override
  ConsumerState<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends ConsumerState<DetailsScreen> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: ref.read(draftProvider).description);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(draftProvider);
    final len = d.description.trim().length;
    final hasVoice = d.attachments.any((a) => a.kind == 'voice');

    return PageBody(
      showBack: true,
      stepLabel: '11 / SAFEVOICE',
      quickExit: true,
      fallback: '/report/incident',
      title: 'Share at your own pace',
      children: [
        const StepBar(2),
        const Tx(
            'Only include what feels safe to share. Names, precise addresses and identifying details are not required.',
            style: TextStyle(color: C.muted, height: 1.4)),
        const SizedBox(height: 14),
        LabeledField(
          label: 'What happened? · Required',
          controller: _text,
          hint: 'Describe the concern in your own words…',
          maxLines: 7,
          maxLength: 3000,
          onChanged: (v) =>
              ref.read(draftProvider.notifier).patch((x) => x.copyWith(description: v)),
        ),
        Tx(
            len < 20
                ? 'Use at least 20 characters so a reviewer can understand your concern. ($len / 3,000)'
                : '$len / 3,000 characters',
            style: const TextStyle(fontSize: 12, color: C.muted)),
        const SizedBox(height: 16),
        const EvidenceSection(),
        PrimaryButton(
            label: 'Continue to privacy & review',
            icon: Icons.arrow_forward,
            onPressed: (len >= 20 || hasVoice)
                ? () => context.push('/report/privacy')
                : null),
        SecondaryButton(
            label: 'Save private draft',
            onPressed: () =>
                snack(context, 'Draft kept while the app stays open.')),
        SecondaryButton(
            label: 'Back to incident category',
            icon: Icons.arrow_back,
            onPressed: () => context.canPop() ? context.pop() : context.go('/report/incident')),
      ],
    );
  }
}

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _consent = false;
  bool _busy = false;
  bool _showDescription = false;
  bool _fetchingLocation = false;

  Future<void> _toggleGPSLocation() async {
    final d = ref.read(draftProvider);
    if (d.location.isNotEmpty) {
      ref.read(draftProvider.notifier).patch((x) => x.copyWith(location: ''));
      snack(context, tr('Location removed'));
      return;
    }

    setState(() => _fetchingLocation = true);
    final res = await LocationService.instance.getCurrentLocation();
    if (!mounted) return;
    setState(() => _fetchingLocation = false);
    if (res.success && res.locationString != null) {
      ref.read(draftProvider.notifier).patch((x) => x.copyWith(location: res.locationString!));
      snack(context, tr('Location added'));
    } else {
      snack(context, res.errorMessage ?? tr('Location permission denied'));
    }
  }

  Future<void> _submit() async {
    final d = ref.read(draftProvider);

    if (!d.anonymous && Repo.live && !Repo.signedIn) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Tx('Sign in for a confidential report'),
          content: const Tx(
              'Confidential reports are linked to your account so support staff can follow up. Sign in, or choose Anonymous instead.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Tx('Not now')),
            FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/signin');
                },
                child: const Tx('Sign in')),
          ],
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final code = await Repo.submitReport(d);
      final failed = await Repo.uploadEvidence(code, d.attachments);
      await ref.read(casesProvider.notifier).add(CaseRecord(
            code: code,
            category: d.category ?? 'Other',
            createdAt: DateTime.now(),
            status: 'received',
          ));
      ref.read(draftProvider.notifier).reset();
      if (mounted) {
        context.go('/report/receipt', extra: {'code': code, 'failed': failed});
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, 'Could not submit. Check your connection and try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(draftProvider);
    final notifier = ref.read(draftProvider.notifier);
    final currentLang = ref.watch(languageProvider);

    return PageBody(
      showBack: true,
      stepLabel: '12 / SAFEVOICE',
      quickExit: true,
      fallback: '/report/details',
      title: 'Your privacy, your choice',
      children: [
        const StepBar(3),

        // 3-Language Responsive Switcher Bar
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.language, size: 16, color: C.primary),
                  SizedBox(width: 6),
                  Tx('Choose language',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: supportedLanguages.map((lang) {
                  final isSelected = currentLang == lang;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => ref.read(languageProvider.notifier).set(lang),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? C.primary : C.tint.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? C.primary : C.tintBorder,
                            ),
                          ),
                          child: Text(
                            lang,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : C.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        OptionTile(
          title: 'Anonymous report',
          subtitle:
              'No name, email, phone or account is required. Keep the reference code shown after you submit. Do not include contact details if you want to avoid identifying yourself. Anonymity is not absolute.',
          selected: d.anonymous,
          onTap: () => notifier.patch((x) => x.copyWith(anonymous: true)),
        ),
        OptionTile(
          title: 'Confidential report',
          subtitle:
              'Linked to your account so authorized support staff can follow up. It is not published or shown in notification previews.',
          selected: !d.anonymous,
          onTap: () => notifier.patch((x) => x.copyWith(anonymous: false)),
        ),
        const InfoBox(
          icon: Icons.info_outline,
          title: 'Understand the limits',
          text:
              'Details, metadata or your account may identify you. Confidentiality can be limited by legal duties or immediate safety concerns.',
        ),

        // Review Header with Eye Button Visibility Toggle
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(
            children: [
              const Expanded(
                child: Tx(
                  'Review your report',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _showDescription = !_showDescription),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showDescription ? Icons.visibility : Icons.visibility_off,
                        color: C.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Tx(
                        _showDescription ? 'Hide details' : 'Show details',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: C.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Pill('Non-sensitive summary'),
                InkWell(
                  onTap: () => setState(() => _showDescription = !_showDescription),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showDescription ? Icons.visibility : Icons.visibility_off,
                        size: 15,
                        color: C.primary,
                      ),
                      const SizedBox(width: 4),
                      Tx(
                        _showDescription ? 'Hide details' : 'Show details',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: C.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Tx('Category: ${d.category ?? '—'}'),
            Tx(
                'Approximate date: ${d.date == null ? 'Not given' : DateFormat('MMMM yyyy').format(d.date!)}'),
            Tx(
                'Broad location: ${d.location.isEmpty ? 'Not given' : d.location}'),
            Tx(d.attachments.isEmpty
                ? 'Evidence: None attached'
                : 'Evidence: ${d.attachments.length} attached'),
            const Divider(height: 18),
            Row(
              children: [
                Icon(
                  _showDescription ? Icons.visibility : Icons.visibility_off,
                  size: 15,
                  color: _showDescription ? C.primary : C.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Tx(
                    _showDescription
                        ? 'Description:'
                        : 'Your description is hidden here for privacy.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _showDescription ? C.primary : C.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_showDescription)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.tint.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.tintBorder),
                ),
                child: Text(
                  d.description.trim().isEmpty ? 'No description entered.' : d.description,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '••••••••••••••••••••••••••••••••••••••••••••••',
                        style: TextStyle(letterSpacing: 2, color: C.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 18, color: C.primary),
                      tooltip: 'Show details',
                      onPressed: () => setState(() => _showDescription = true),
                    ),
                  ],
                ),
              ),
          ]),
        ),

        // Mobile GPS Location Card with 1-Tap Control
        AppCard(
          child: Row(
            children: [
              Icon(
                d.location.isNotEmpty ? Icons.location_on : Icons.location_off_outlined,
                color: d.location.isNotEmpty ? C.primary : C.muted,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tx(
                      d.location.isNotEmpty ? 'Location included' : 'No location attached',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.location.isNotEmpty ? d.location : 'GPS is off. Location is optional on mobile.',
                      style: const TextStyle(fontSize: 12, color: C.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _fetchingLocation ? null : _toggleGPSLocation,
                icon: Icon(
                  _fetchingLocation
                      ? Icons.hourglass_top
                      : (d.location.isNotEmpty ? Icons.clear : Icons.my_location),
                  size: 15,
                  color: d.location.isNotEmpty ? C.danger : C.primary,
                ),
                label: Tx(
                  _fetchingLocation
                      ? 'Getting GPS location...'
                      : (d.location.isNotEmpty ? 'Clear location' : 'Use GPS location'),
                  style: TextStyle(
                    fontSize: 12,
                    color: d.location.isNotEmpty ? C.danger : C.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        CheckboxListTile(
          value: _consent,
          onChanged: (v) => setState(() => _consent = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Tx(
              'I understand who may review this report and the limits above. I consent to submit the information I chose to share.',
              style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: _busy
              ? 'Submitting…'
              : (Repo.live ? 'Submit report' : 'Submit report · demo only'),
          onPressed: (_consent && !_busy) ? _submit : null,
        ),
        SecondaryButton(
            label: 'Back to details',
            icon: Icons.arrow_back,
            onPressed: () => context.pop()),
      ],
    );
  }
}

// -------------------------------------------------------------- Receipt
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.code, this.failedUploads = 0});
  final String? code;
  final int failedUploads;

  @override
  Widget build(BuildContext context) {
    if (code == null) {
      return PageBody(children: [
        StateView(
          icon: Icons.help_outline,
          title: 'No receipt to show',
          message: 'Open My Cases to see reports saved on this device.',
          actionLabel: 'Go to My Cases',
          onAction: () => context.go('/home/cases'),
        ),
      ]);
    }
    return PageBody(
      showBack: true,
      fallback: '/home',
      stepLabel: '13 / SAFEVOICE',
      title: 'Your voice has a place.',
      children: [
        if (!Repo.live)
          const Align(
              alignment: Alignment.centerLeft,
              child: Pill('Demo confirmation', bg: C.okBg, fg: C.ok)),
        const SizedBox(height: 14),
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
                color: C.okBg, borderRadius: BorderRadius.circular(32)),
            child: const Icon(Icons.verified_user_outlined,
                size: 52, color: C.ok),
          ),
        ),
        const SizedBox(height: 16),
        Tx(
            Repo.live
                ? 'Your report was received.'
                : 'This illustrates a submission receipt. No live report was delivered.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: C.muted)),
        const SizedBox(height: 16),
        AppCard(
          color: C.tint,
          border: C.tintBorder,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Tx('Your private access code',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SelectableText(code!,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            const Tx(
                'Save this code somewhere only you can reach. It cannot be recovered. It is the only way to follow this report if you chose Anonymous.',
                style: TextStyle(fontSize: 13, color: C.muted, height: 1.4)),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Copy access code',
              icon: Icons.copy,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code!));
                if (context.mounted) snack(context, 'Code copied.');
              },
            ),
          ]),
        ),
        const InfoBox(
          icon: Icons.info_outline,
          title: 'A receipt is not a response guarantee',
          text:
              'Receiving a report does not guarantee review time, a response or emergency dispatch. SheRise does not automatically contact emergency services.',
        ),
        if (failedUploads > 0)
          InfoBox(
            tone: Tone.warn,
            icon: Icons.cloud_off_outlined,
            title: 'Some attachments were not uploaded',
            text:
                '$failedUploads item(s) could not be uploaded. Your report was still received. You can describe the details in a message from My Cases.',
          ),
        PrimaryButton(
            label: 'Track this case',
            icon: Icons.track_changes,
            onPressed: () => context.go('/home/cases')),
        SecondaryButton(
            label: 'Back to SafeVoice',
            icon: Icons.arrow_back,
            onPressed: () => context.go('/report')),
        SecondaryButton(
            label: 'Back to home',
            icon: Icons.home,
            onPressed: () => context.go('/home')),
      ],
    );
  }
}
