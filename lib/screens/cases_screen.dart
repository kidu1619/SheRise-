import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

Pill statusPill(String status) {
  final label = statusLabels[status] ?? status;
  switch (status) {
    case 'resolved':
    case 'closed':
      return Pill(label, bg: C.okBg, fg: C.ok);
    case 'under_review':
    case 'referred':
      return Pill(label, bg: C.warnBg, fg: C.warn);
    default:
      return Pill(label);
  }
}

class CasesScreen extends ConsumerStatefulWidget {
  const CasesScreen({super.key});

  @override
  ConsumerState<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends ConsumerState<CasesScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    if (!Repo.live) {
      snack(context, 'Connect SheRise to the service to track a code.');
      return;
    }
    setState(() => _busy = true);
    try {
      final s = await Repo.trackStatus(code);
      if (!mounted) return;
      if (s == null) {
        snack(context, 'No case found with that code. Check it and try again.');
      } else {
        await ref.read(casesProvider.notifier).add(CaseRecord(
              code: code,
              category: s.category,
              createdAt: s.createdAt,
              status: s.status,
            ));
        _code.clear();
      }
    } catch (_) {
      if (mounted) snack(context, 'Could not check that code. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cases = ref.watch(casesProvider);

    return PageBody(
      showBack: true,
      title: 'My Cases',
      subtitle:
          'Private updates for reports you saved on this device. Reports are never shown publicly.',
      children: [
        if (cases.isEmpty)
          const StateView(
            icon: Icons.folder_open,
            title: 'No cases yet',
            message:
                'After you submit a report, its private access code is saved here. You can also add a code below.',
          )
        else
          for (final c in cases)
            AppCard(
              onTap: () =>
                  context.push('/home/cases/${Uri.encodeComponent(c.code)}'),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tx(c.code,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, letterSpacing: .5)),
                        const SizedBox(height: 4),
                        Tx(
                            '${c.category} · ${DateFormat('d MMM yyyy').format(c.createdAt)}',
                            style: const TextStyle(color: C.muted, fontSize: 12)),
                      ]),
                ),
                statusPill(c.status),
                const Icon(Icons.chevron_right, color: C.muted),
              ]),
            ),
        const SectionTitle('Track a case by code'),
        LabeledField(
          label: 'Private access code',
          controller: _code,
          hint: 'XXXX-XXXX-XXXX-XXXX',
        ),
        SecondaryButton(
            label: _busy ? 'Checking…' : 'Add case',
            icon: Icons.add,
            onPressed: _busy ? null : _track),
        const InfoBox(
          icon: Icons.lock_outline,
          title: 'Keep your codes private',
          text:
              'Anyone with a code can view that case. Codes saved here stay on this device. Remove a case if the device is shared.',
        ),
      ],
    );
  }
}

class CaseDetailScreen extends ConsumerStatefulWidget {
  const CaseDetailScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  final _msg = TextEditingController();
  late Future<(CaseStatus?, List<CaseMessage>)> _future = _load();
  bool _sending = false;

  Future<(CaseStatus?, List<CaseMessage>)> _load() async {
    if (!Repo.live) return (null, <CaseMessage>[]);
    final s = await Repo.trackStatus(widget.code);
    final m = s == null ? <CaseMessage>[] : await Repo.messages(widget.code);
    return (s, m);
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msg.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await Repo.sendMessage(widget.code, text);
      _msg.clear();
      setState(() => _future = _load());
    } catch (_) {
      if (mounted) snack(context, 'Could not send. Try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = ref
        .watch(casesProvider)
        .where((c) => c.code == widget.code)
        .firstOrNull;

    return PageBody(
      showBack: true,
      fallback: '/home/cases',
      title: 'Case update',
      children: [
        FutureBuilder<(CaseStatus?, List<CaseMessage>)>(
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
                title: 'Could not load this case',
                message: 'Check your connection and try again.',
                actionLabel: 'Try again',
                onAction: () => setState(() => _future = _load()),
              );
            }
            final status = snap.data?.$1;
            final messages = snap.data?.$2 ?? <CaseMessage>[];
            final shown = status?.status ?? local?.status ?? 'received';

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Tx(widget.code,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  statusPill(shown),
                  const SizedBox(height: 10),
                  Tx('Category: ${status?.category ?? local?.category ?? '—'}'),
                  if (status != null)
                    Tx(
                        'Last update: ${DateFormat('d MMM yyyy, HH:mm').format(status.updatedAt.toLocal())}'),
                ]),
              ),
              if (!Repo.live)
                const InfoBox(
                  title: 'Demo mode',
                  text:
                      'Live status and messages appear once SheRise is connected to the service.',
                ),
              const SectionTitle('Messages'),
              if (messages.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Tx('No messages yet.',
                      style: TextStyle(color: C.muted)),
                ),
              for (final m in messages)
                Align(
                  alignment: m.sender == 'reporter'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.sender == 'reporter' ? C.tint : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.line),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Tx(m.sender == 'reporter' ? 'You' : 'Support team',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: C.muted)),
                      const SizedBox(height: 2),
                      Tx(m.body),
                    ]),
                  ),
                ),
              if (Repo.live) ...[
                const SizedBox(height: 8),
                LabeledField(
                    label: 'Send a private message',
                    controller: _msg,
                    maxLines: 3),
                PrimaryButton(
                    label: _sending ? 'Sending…' : 'Send message',
                    icon: Icons.send,
                    onPressed: _sending ? null : _send),
              ],
            ]);
          },
        ),
        SecondaryButton(
          label: 'Remove from this device',
          icon: Icons.delete_outline,
          onPressed: () async {
            await ref.read(casesProvider.notifier).remove(widget.code);
            if (context.mounted) context.go('/home/cases');
          },
        ),
        const Tx(
            'Removing a case only deletes the saved code on this device. It does not delete the report.',
            style: TextStyle(fontSize: 12, color: C.muted)),
      ],
    );
  }
}
