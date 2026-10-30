import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';
import 'cases_screen.dart' show statusPill;

String _err(Object e) =>
    e is PostgrestException ? e.message : 'Something went wrong. Try again.';

const _spinner = Padding(
    padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));

// =====================================================================
// Institution portal login screen: dedicated staff access
// =====================================================================
class InstitutionLoginScreen extends StatefulWidget {
  const InstitutionLoginScreen({super.key});

  @override
  State<InstitutionLoginScreen> createState() => _InstitutionLoginScreenState();
}

class _InstitutionLoginScreenState extends State<InstitutionLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fill(String email, String pass) {
    setState(() {
      _email.text = email;
      _password.text = pass;
    });
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text;
    if (email.isEmpty || pass.isEmpty) {
      snack(context, 'Enter your institutional email and password.');
      return;
    }

    setState(() => _busy = true);
    try {
      final ok = await Repo.staffLogin(email, pass);
      if (!mounted) return;
      if (ok) {
        context.go('/board');
      } else {
        setState(() => _busy = false);
        snack(context,
            'Invalid staff credentials. Please check your email and password.');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context,
            'Invalid staff credentials. Please check your email and password.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      showBack: true,
      fallback: '/welcome',
      title: 'Institutional Review Portal',
      subtitle:
          'Secure access for authorized institutional reviewers and administrators.',
      children: [
        if (!Repo.live) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Tx('Demo accounts for testing',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.person, size: 16),
                      label: const Tx('Quick Login (Staff)'),
                      onPressed: () {
                        _fill('staff@institution.org', 'staff123');
                        _submit();
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings, size: 16),
                      label: const Tx('Quick Login (Admin)'),
                      onPressed: () {
                        _fill('admin@institution.org', 'admin123');
                        _submit();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        LabeledField(
          label: 'Staff email',
          hint: 'e.g. staff@institution.org',
          controller: _email,
          keyboard: TextInputType.emailAddress,
        ),
        LabeledField(
          label: 'Password',
          controller: _password,
          obscure: true,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: _busy ? 'Signing in…' : 'Sign in to Portal',
          icon: Icons.lock_open,
          onPressed: _busy ? null : _submit,
        ),
        SecondaryButton(
          label: 'Return to safe app',
          icon: Icons.arrow_back,
          onPressed: () => context.go('/welcome'),
        ),
      ],
    );
  }
}

// =====================================================================
// Institution board: the list of reports sent to an institution
// =====================================================================
class InstitutionBoardScreen extends StatefulWidget {
  const InstitutionBoardScreen({super.key});

  @override
  State<InstitutionBoardScreen> createState() => _InstitutionBoardState();
}

class _InstitutionBoardState extends State<InstitutionBoardScreen> {
  late final Future<StaffAccess> _access = Repo.myAccess();
  String? _selected; // institution id, null = all (admins only)
  bool _initialised = false;
  Future<List<StaffReport>>? _reports;
  String _filter = 'all';

  void _reload() => setState(() => _reports = Repo.staffReports(_selected));

  @override
  Widget build(BuildContext context) {
    if (Repo.live && !Repo.signedIn) {
      return PageBody(
        showBack: true,
        fallback: '/welcome',
        title: 'Access Restricted',
        children: [
          StateView(
            icon: Icons.lock_outline,
            title: 'Staff sign in required',
            message:
                'This area is restricted to authorized institution staff and reviewers.',
            actionLabel: 'Sign in to Portal',
            onAction: () => context.go('/board/login'),
          ),
        ],
      );
    }

    return PageBody(
      showBack: true,
      fallback: '/welcome',
      title: 'Institution board',
      subtitle:
          "Reports sent to your institution. The reporter's identity is never shown here.",
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Log out',
          onPressed: () async {
            await Repo.staffLogout();
            if (context.mounted) {
              snack(context, 'Logged out of institution board');
              context.go('/board/login');
            }
          },
        ),
      ],
      children: [
        if (!Repo.live)
          const InfoBox(
            title: 'Demo mode',
            text:
                'Connect SheRise to Supabase and run supabase/schema.sql to use the institution board with real reports. Showing demo reports for testing.',
          ),
        FutureBuilder<StaffAccess>(
          future: _access,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return _spinner;
            final access = snap.data ?? const StaffAccess();
            if (!access.isStaff) {
              return StateView(
                icon: Icons.lock_outline,
                title: 'Staff sign in required',
                message:
                    'This area is restricted to authorized institution staff and reviewers.',
                actionLabel: 'Sign in to Portal',
                onAction: () => context.go('/board/login'),
              );
            }
            if (!_initialised) {
              _initialised = true;
              _selected =
                  access.institutions.isNotEmpty ? access.institutions.first.id : null;
              _reports = Repo.staffReports(_selected);
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const InfoBox(
                icon: Icons.shield_outlined,
                title: 'Handle with care',
                text:
                    'These reports are sensitive. Only use them for your institution\'s response process. Opening a report is recorded.',
              ),
              if (access.isAdmin)
                SecondaryButton(
                  label: 'Manage institutions',
                  icon: Icons.add_business_outlined,
                  onPressed: () => context.push('/board/admin'),
                ),
              if (access.isAdmin || access.institutions.length > 1) ...[
                const Tx('Institution',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (access.isAdmin)
                    ChoiceChip(
                      label: const Tx('All reports'),
                      selected: _selected == null,
                      onSelected: (_) {
                        _selected = null;
                        _reload();
                      },
                    ),
                  for (final i in access.institutions)
                    ChoiceChip(
                      label: Tx(i.name),
                      selected: _selected == i.id,
                      onSelected: (_) {
                        _selected = i.id;
                        _reload();
                      },
                    ),
                ]),
                const SizedBox(height: 16),
              ],
              _buildReports(),
            ]);
          },
        ),
      ],
    );
  }

  Widget _buildReports() {
    return FutureBuilder<List<StaffReport>>(
      future: _reports,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return _spinner;
        if (snap.hasError) {
          return StateView(
            icon: Icons.wifi_off,
            title: 'Could not load reports',
            message: 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        final all = snap.data ?? const <StaffReport>[];
        final shown =
            _filter == 'all' ? all : all.where((r) => r.status == _filter).toList();
        int count(Set<String> s) => all.where((r) => s.contains(r.status)).length;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Stat('Total', all.length),
            _Stat('New', count({'received'})),
            _Stat('In progress', count({'under_review', 'referred'})),
            _Stat('Closed', count({'resolved', 'closed'})),
          ]),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in ['all', ...statusLabels.keys])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Tx(f == 'all' ? 'All' : statusLabels[f]!),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            const StateView(
              icon: Icons.inbox_outlined,
              title: 'No reports here',
              message: 'New reports sent to this institution will appear here.',
            )
          else
            for (final r in shown)
              _ReportCard(
                r,
                onTap: () async {
                  await context.push('/board/report/${r.id}');
                  if (mounted) _reload();
                },
              ),
          Center(
            child: TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Tx('Refresh'),
            ),
          ),
        ]);
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.line),
          ),
          child: Column(children: [
            Text('$value',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Tx(label, style: const TextStyle(fontSize: 11, color: C.muted)),
          ]),
        ),
      );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard(this.r, {required this.onTap});
  final StaffReport r;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(r.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, letterSpacing: .5)),
            const Spacer(),
            statusPill(r.status),
          ]),
          const SizedBox(height: 6),
          ValueListenableBuilder<String>(
            valueListenable: languageNotifier,
            builder: (_, lang, _) => Text(
              '${trFor(lang, r.categoryLabel)} · ${formatLocalizedDate(r.createdAt.toLocal(), lang)}',
              style: const TextStyle(color: C.muted, fontSize: 12),
            ),
          ),
          if (r.snippet.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Tx(r.snippet,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            Pill(r.anonymous ? 'Anonymous' : 'Confidential'),
            if (r.locationText.isNotEmpty) Pill(r.locationText),
            if (r.hasGps) const Pill('GPS'),
            if (r.evidenceCount > 0) Pill('${r.evidenceCount} attached'),
          ]),
        ]),
      );
}

// =====================================================================
// One report: details, evidence, status and private messages
// =====================================================================
typedef _Loaded = (StaffReport?, List<CaseMessage>, List<EvidenceItem>);

class StaffReportScreen extends StatefulWidget {
  const StaffReportScreen({super.key, required this.id});
  final String id;

  @override
  State<StaffReportScreen> createState() => _StaffReportState();
}

class _StaffReportState extends State<StaffReportScreen> {
  final _msg = TextEditingController();
  late Future<_Loaded> _future = _load();
  bool _busy = false;

  Future<_Loaded> _load() async {
    final r = await Repo.staffReport(widget.id);
    if (r == null) return (null, <CaseMessage>[], <EvidenceItem>[]);
    final m = await Repo.staffMessages(widget.id);
    final e = await Repo.staffEvidence(widget.id);
    return (r, m, e);
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _setStatus(String s) async {
    setState(() => _busy = true);
    try {
      await Repo.staffSetStatus(widget.id, s);
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) snack(context, _err(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final text = _msg.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await Repo.staffSendMessage(widget.id, text);
      _msg.clear();
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) snack(context, _err(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      showBack: true,
      fallback: '/board',
      title: 'Report',
      children: [
        FutureBuilder<_Loaded>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return _spinner;
            if (snap.hasError || snap.data?.$1 == null) {
              return StateView(
                icon: Icons.lock_outline,
                title: 'Could not open this report',
                message:
                    'It may not exist, or your account may not have access to it.',
                actionLabel: 'Try again',
                onAction: () => setState(() => _future = _load()),
              );
            }
            final r = snap.data!.$1!;
            final messages = snap.data!.$2;
            final evidence = snap.data!.$3;
            final hasPlace = r.locationText.isNotEmpty || r.latitude != null;

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(r.label,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    statusPill(r.status),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    Pill(r.anonymous ? 'Anonymous' : 'Confidential'),
                    Pill(r.categoryLabel),
                  ]),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<String>(
                    valueListenable: languageNotifier,
                    builder: (_, lang, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trFor(lang, 'Received: ')}${formatLocalizedDateTime(r.createdAt.toLocal(), lang)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (r.incidentDate != null)
                          Text(
                            '${trFor(lang, 'Incident (approx.): ')}${formatLocalizedMonthYear(r.incidentDate!, lang)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        if (r.institutionName != null)
                          Text(
                            '${trFor(lang, 'Institution: ')}${trFor(lang, r.institutionName!)}',
                            style: const TextStyle(fontSize: 13),
                          )
                        else
                          Tx('Institution: none chosen (SheRise team)'),
                      ],
                    ),
                  ),
                ]),
              ),
              if (hasPlace)
                AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: const [
                      Icon(Icons.location_on_outlined, color: C.primary, size: 20),
                      SizedBox(width: 8),
                      Tx('Location',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    if (r.locationText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Tx(r.locationText),
                    ],
                    if (r.latitude != null && r.longitude != null) ...[
                      const SizedBox(height: 6),
                      Tx(
                          'Approx. coordinates: ${r.latitude!.toStringAsFixed(2)}, ${r.longitude!.toStringAsFixed(2)}',
                          style: const TextStyle(color: C.muted, fontSize: 13)),
                      const Tx('Rounded to about 1 km. This is the area, not an exact spot.',
                          style: TextStyle(color: C.muted, fontSize: 12)),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(
                              text:
                                  '${r.latitude!.toStringAsFixed(2)}, ${r.longitude!.toStringAsFixed(2)}'));
                          if (context.mounted) snack(context, 'Coordinates copied.');
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Tx('Copy coordinates'),
                      ),
                    ],
                  ]),
                ),
              const SectionTitle('What was reported'),
              AppCard(child: SelectableText(r.description, style: const TextStyle(height: 1.5))),
              const SectionTitle('Evidence'),
              if (evidence.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Tx('No attachments.', style: TextStyle(color: C.muted)),
                )
              else
                for (final e in evidence) _EvidenceTile(e),
              const SectionTitle('Update status'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in statusLabels.keys)
                  ChoiceChip(
                    label: Tx(statusLabels[s]!),
                    selected: r.status == s,
                    onSelected: (_busy || r.status == s) ? null : (_) => _setStatus(s),
                  ),
              ]),
              const SectionTitle('Private messages'),
              if (messages.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Tx('No messages yet.', style: TextStyle(color: C.muted)),
                ),
              for (final m in messages)
                Align(
                  alignment: m.sender == 'staff'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.sender == 'staff' ? C.tint : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.line),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Tx(m.sender == 'staff' ? 'Support team' : 'Reporter',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: C.muted)),
                      const SizedBox(height: 2),
                      Text(m.body),
                      const SizedBox(height: 4),
                      ValueListenableBuilder<String>(
                        valueListenable: languageNotifier,
                        builder: (_, lang, _) => Text(
                          formatLocalizedDateTime(m.createdAt.toLocal(), lang),
                          style: const TextStyle(fontSize: 11, color: C.muted),
                        ),
                      ),
                    ]),
                  ),
                ),
              const SizedBox(height: 8),
              LabeledField(
                  label: 'Reply to the reporter',
                  controller: _msg,
                  maxLines: 3,
                  maxLength: 2000),
              PrimaryButton(
                  label: _busy ? 'Working…' : 'Send message',
                  icon: Icons.send,
                  onPressed: _busy ? null : _send),
              const Tx(
                  'The reporter sees your reply under My Cases with their private code.',
                  style: TextStyle(fontSize: 12, color: C.muted)),
            ]);
          },
        ),
      ],
    );
  }
}

class _EvidenceTile extends StatefulWidget {
  const _EvidenceTile(this.item);
  final EvidenceItem item;

  @override
  State<_EvidenceTile> createState() => _EvidenceTileState();
}

class _EvidenceTileState extends State<_EvidenceTile> {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _sub;
  bool _playing = false;

  @override
  void dispose() {
    _sub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_player == null) {
        _player = AudioPlayer();
        _sub = _player!.onPlayerStateChanged.listen((s) {
          if (mounted) setState(() => _playing = s == PlayerState.playing);
        });
        await _player!.play(UrlSource(widget.item.url));
      } else if (_playing) {
        await _player!.pause();
      } else {
        await _player!.resume();
      }
    } catch (_) {
      if (mounted) snack(context, 'Could not play this voice note.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.item;
    if (e.isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            e.url,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const AppCard(
                child: Tx('Could not preview this image.',
                    style: TextStyle(color: C.muted))),
          ),
        ),
      );
    }
    return AppCard(
      child: Row(children: [
        Icon(e.isAudio ? Icons.mic_none : Icons.insert_drive_file_outlined,
            color: C.primary),
        const SizedBox(width: 12),
        Expanded(
            child: Tx(e.isAudio ? 'Voice note' : 'File',
                style: const TextStyle(fontWeight: FontWeight.w600))),
        if (e.isAudio)
          IconButton.filledTonal(
            onPressed: _togglePlay,
            tooltip: _playing ? 'Pause' : 'Play',
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
          )
        else
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: e.url));
              if (context.mounted) {
                snack(context, 'Link copied. It expires in 10 minutes.');
              }
            },
            icon: const Icon(Icons.link, size: 16),
            label: const Tx('Copy link'),
          ),
      ]),
    );
  }
}

// =====================================================================
// Admin: create institutions and add their staff
// =====================================================================
class InstitutionAdminScreen extends StatefulWidget {
  const InstitutionAdminScreen({super.key});

  @override
  State<InstitutionAdminScreen> createState() => _InstitutionAdminState();
}

class _InstitutionAdminState extends State<InstitutionAdminScreen> {
  late Future<StaffAccess> _access = Repo.myAccess();

  final _name = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _contact = TextEditingController();
  String _kind = 'university';
  bool _creating = false;

  final _staffEmail = TextEditingController();
  String? _institutionId;
  String _role = 'reviewer';
  bool _adding = false;

  @override
  void dispose() {
    for (final c in [_name, _city, _region, _contact, _staffEmail]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().length < 2) {
      snack(context, 'Enter the institution name.');
      return;
    }
    setState(() => _creating = true);
    try {
      await Repo.adminCreateInstitution(
        name: _name.text.trim(),
        kind: _kind,
        city: _city.text.trim(),
        region: _region.text.trim(),
        email: _contact.text.trim(),
      );
      for (final c in [_name, _city, _region, _contact]) {
        c.clear();
      }
      if (mounted) {
        snack(context, 'Institution created.');
        setState(() => _access = Repo.myAccess());
      }
    } catch (e) {
      if (mounted) snack(context, _err(e));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _addStaff() async {
    if (_institutionId == null || _staffEmail.text.trim().isEmpty) {
      snack(context, 'Choose an institution and enter an email address.');
      return;
    }
    setState(() => _adding = true);
    try {
      await Repo.adminAddMember(
        institutionId: _institutionId!,
        email: _staffEmail.text.trim(),
        role: _role,
      );
      _staffEmail.clear();
      if (mounted) snack(context, 'Staff member added.');
    } catch (e) {
      if (mounted) snack(context, _err(e));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      showBack: true,
      fallback: '/board',
      title: 'Manage institutions',
      subtitle:
          'Create the schools, workplaces and organizations that receive reports, and choose who can review them.',
      children: [
        FutureBuilder<StaffAccess>(
          future: _access,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return _spinner;
            final access = snap.data ?? const StaffAccess();
            if (!access.isAdmin) {
              return const StateView(
                icon: Icons.lock_outline,
                title: 'Administrators only',
                message: 'Your account does not have permission to manage institutions.',
              );
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle('Create an institution'),
              LabeledField(
                  label: 'Institution name',
                  controller: _name,
                  hint: 'e.g. Example University'),
              const Tx('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final k in institutionKinds.entries)
                  ChoiceChip(
                    label: Tx(k.value),
                    selected: _kind == k.key,
                    onSelected: (_) => setState(() => _kind = k.key),
                  ),
              ]),
              const SizedBox(height: 14),
              LabeledField(label: 'City', controller: _city, hint: 'e.g. Addis Ababa'),
              LabeledField(label: 'Region', controller: _region, hint: 'e.g. Oromia'),
              LabeledField(
                  label: 'Contact email (optional)',
                  controller: _contact,
                  keyboard: TextInputType.emailAddress),
              PrimaryButton(
                  label: _creating ? 'Creating…' : 'Create institution',
                  icon: Icons.add_business_outlined,
                  onPressed: _creating ? null : _create),
              const SectionTitle('Add a staff member'),
              const Tx(
                  'They must already have a SheRise account. Enter the email they signed up with.',
                  style: TextStyle(color: C.muted, fontSize: 13)),
              const SizedBox(height: 10),
              if (access.institutions.isEmpty)
                const Tx('Create an institution first.', style: TextStyle(color: C.muted))
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final i in access.institutions)
                    ChoiceChip(
                      label: Tx(i.name),
                      selected: _institutionId == i.id,
                      onSelected: (_) => setState(() => _institutionId = i.id),
                    ),
                ]),
              const SizedBox(height: 14),
              LabeledField(
                  label: 'Staff email address',
                  controller: _staffEmail,
                  keyboard: TextInputType.emailAddress),
              Wrap(spacing: 8, children: [
                ChoiceChip(
                    label: const Tx('Reviewer'),
                    selected: _role == 'reviewer',
                    onSelected: (_) => setState(() => _role = 'reviewer')),
                ChoiceChip(
                    label: const Tx('Manager'),
                    selected: _role == 'manager',
                    onSelected: (_) => setState(() => _role = 'manager')),
              ]),
              const SizedBox(height: 14),
              PrimaryButton(
                  label: _adding ? 'Adding…' : 'Add staff member',
                  icon: Icons.person_add_alt,
                  onPressed: _adding ? null : _addStaff),
              const SectionTitle('Institutions'),
              for (final i in access.institutions)
                AppCard(
                  bottom: 8,
                  child: Row(children: [
                    const Icon(Icons.apartment_outlined, color: C.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Tx(i.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Tx(i.subtitle,
                            style: const TextStyle(color: C.muted, fontSize: 12)),
                      ]),
                    ),
                  ]),
                ),
            ]);
          },
        ),
      ],
    );
  }
}
