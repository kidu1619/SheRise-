import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/models.dart';
import 'i18n.dart';

/// Report draft lives in memory only. It is cleared when the app closes,
/// because it can contain sensitive details.
class DraftNotifier extends Notifier<ReportDraft> {
  @override
  ReportDraft build() => const ReportDraft();

  void patch(ReportDraft Function(ReportDraft d) change) =>
      state = change(state);

  void reset() => state = const ReportDraft();
}

final draftProvider =
    NotifierProvider<DraftNotifier, ReportDraft>(DraftNotifier.new);

/// Saved case codes on this device.
class CasesNotifier extends Notifier<List<CaseRecord>> {
  @override
  List<CaseRecord> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('cases') ?? [];
    state = raw
        .map((s) => CaseRecord.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
        'cases', state.map((c) => jsonEncode(c.toJson())).toList());
  }

  Future<void> add(CaseRecord c) async {
    state = [c, ...state.where((x) => x.code != c.code)];
    await _save();
  }

  Future<void> remove(String code) async {
    state = state.where((x) => x.code != code).toList();
    await _save();
  }
}

final casesProvider =
    NotifierProvider<CasesNotifier, List<CaseRecord>>(CasesNotifier.new);

class ContactNotifier extends Notifier<TrustedContact?> {
  @override
  TrustedContact? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('contact');
    if (raw != null) {
      state = TrustedContact.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
  }

  Future<void> set(TrustedContact? c) async {
    state = c;
    final p = await SharedPreferences.getInstance();
    if (c == null) {
      await p.remove('contact');
    } else {
      await p.setString('contact', jsonEncode(c.toJson()));
    }
  }
}

final contactProvider =
    NotifierProvider<ContactNotifier, TrustedContact?>(ContactNotifier.new);

class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'English';
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('language') ?? 'English';
    final l = supportedLanguages.contains(saved) ? saved : 'English';
    state = l;
    languageNotifier.value = l;
  }

  Future<void> set(String l) async {
    state = l;
    languageNotifier.value = l;
    final p = await SharedPreferences.getInstance();
    await p.setString('language', l);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

/// Checked items of the personal safety plan (generic checklist only).
class PlanNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = (p.getStringList('plan') ?? []).toSet();
  }

  Future<void> toggle(String item) async {
    final next = {...state};
    next.contains(item) ? next.remove(item) : next.add(item);
    state = next;
    final p = await SharedPreferences.getInstance();
    await p.setStringList('plan', next.toList());
  }
}

final planProvider =
    NotifierProvider<PlanNotifier, Set<String>>(PlanNotifier.new);

Future<void> clearAllLocalData() async {
  final p = await SharedPreferences.getInstance();
  await p.clear();
}
