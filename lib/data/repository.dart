import 'dart:math';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'models.dart';

/// Talks to Supabase when keys are set; otherwise works in demo mode.
class Repo {
  static bool get live => AppConfig.isConfigured;
  static SupabaseClient get _db => Supabase.instance.client;

  // ---------- auth ----------
  static bool get signedIn => live && _db.auth.currentUser != null;

  static String? get email => live ? _db.auth.currentUser?.email : null;

  static String? get displayName {
    if (!live) return null;
    final meta = _db.auth.currentUser?.userMetadata;
    final value = meta == null ? null : meta['display_name'];
    return value is String ? value : null;
  }

  static Future<void> signIn(String email, String password) async {
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signUp(String email, String password, String name) async {
    final Map<String, dynamic>? data =
        name.isEmpty ? null : <String, dynamic>{'display_name': name};
    await _db.auth.signUp(email: email, password: password, data: data);
  }

  static Future<void> recover(String email) async {
    await _db.auth.resetPasswordForEmail(email);
  }

  static Future<void> signOut() async {
    await _db.auth.signOut();
  }

  // ---------- reports ----------
  static String _category(String? label) {
    switch (label) {
      case 'Harassment':
        return 'harassment';
      case 'Bullying':
        return 'bullying';
      case 'Discrimination':
        return 'discrimination';
      case 'Unequal opportunity':
        return 'workplace_inequality';
      default:
        return 'other';
    }
  }

  static String _demoCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    String part() =>
        List.generate(4, (_) => chars[r.nextInt(chars.length)]).join();
    return 'DEMO-${part()}-${part()}';
  }

  /// Returns the private reference code. It is shown once and the server
  /// keeps only a hash of it.
  static Future<String> submitReport(ReportDraft d) async {
    if (!live) return _demoCode();
    final params = <String, dynamic>{
      'p_category': _category(d.category),
      'p_environment': d.institution?.kind ?? 'other',
      'p_description': d.description.trim().isEmpty
          ? 'Voice report. Please see the attached voice note.'
          : d.description.trim(),
      'p_anonymous': d.anonymous,
    };
    if (d.date != null) {
      params['p_incident_date'] = DateFormat('yyyy-MM-dd').format(d.date!);
    }
    if (d.institution != null) params['p_institution_id'] = d.institution!.id;
    final place = d.location.trim();
    if (place.isNotEmpty) params['p_location_text'] = place;
    if (d.latitude != null && d.longitude != null) {
      params['p_latitude'] = d.latitude;
      params['p_longitude'] = d.longitude;
    }
    final res = await _db.rpc('submit_report', params: params);
    return res as String;
  }

  static String _randomId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Uploads attachments to private storage under random names, then links
  /// them to the report using its private code. Returns how many failed.
  static Future<int> uploadEvidence(
      String code, List<Attachment> items) async {
    if (!live || items.isEmpty) return 0;
    var failed = 0;
    final folder = _randomId();
    for (final a in items) {
      try {
        final path = '$folder/${_randomId()}.${a.ext}';
        await _db.storage.from('evidence').uploadBinary(
              path,
              a.bytes,
              fileOptions: FileOptions(contentType: a.mime),
            );
        await _db.rpc('attach_evidence',
            params: {'p_code': code, 'p_path': path, 'p_mime': a.mime});
      } catch (_) {
        failed++;
      }
    }
    return failed;
  }

  static Future<CaseStatus?> trackStatus(String code) async {
    if (!live) {
      return CaseStatus(
        status: 'received',
        category: 'Harassment',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        institutionName: 'Sample University (demo)',
      );
    }
    final res = await _db.rpc('get_report_status', params: {'p_code': code});
    final list = res as List;
    if (list.isEmpty) return null;
    final r = list.first as Map<String, dynamic>;
    return CaseStatus(
      status: r['status'] as String,
      category: r['category'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
      institutionName: r['institution_name'] as String?,
    );
  }

  static Future<List<CaseMessage>> messages(String code) async {
    if (!live) return const [];
    final res = await _db.rpc('get_report_messages', params: {'p_code': code});
    return (res as List).map((e) {
      final r = e as Map<String, dynamic>;
      return CaseMessage(
        sender: r['sender'] as String,
        body: r['body'] as String,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  static Future<void> sendMessage(String code, String body) async {
    if (!live) return;
    await _db.rpc('add_reporter_message',
        params: {'p_code': code, 'p_body': body});
  }

  // ---------- institutions ----------
  /// Active institutions a reporter can choose from.
  static Future<List<Institution>> institutions() async {
    if (!live) return sampleInstitutions;
    final rows =
        await _db.from('institutions').select().eq('active', true).order('name');
    return (rows as List)
        .map((r) => Institution.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  // ---------- staff auth (portal) ----------
  static String? _demoStaffEmail;
  static bool get isDemoStaffLoggedIn => _demoStaffEmail != null;
  static String? get currentStaffEmail => live ? email : _demoStaffEmail;

  /// Check whether an email is a recognized institutional staff account in demo mode
  static bool isStaffEmail(String email) {
    final lower = email.trim().toLowerCase();
    return lower == 'staff@institution.org' ||
        lower == 'admin@institution.org' ||
        lower == 'police@institution.org';
  }

  /// Staff login supporting both demo credentials and live Supabase auth.
  static Future<bool> staffLogin(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (!live) {
      if (cleanEmail == 'staff@institution.org' && cleanPass == 'staff123') {
        _demoStaffEmail = 'staff@institution.org';
        return true;
      }
      if (cleanEmail == 'admin@institution.org' && cleanPass == 'admin123') {
        _demoStaffEmail = 'admin@institution.org';
        return true;
      }
      if (cleanEmail == 'police@institution.org' && cleanPass == 'police123') {
        _demoStaffEmail = 'police@institution.org';
        return true;
      }
      return false;
    }

    // Live Supabase authentication
    await signIn(cleanEmail, cleanPass);
    final access = await myAccess();
    if (!access.isStaff) {
      // Not an authorized staff member in Supabase
      await signOut();
      return false;
    }
    return true;
  }

  /// Staff sign out
  static Future<void> staffLogout() async {
    _demoStaffEmail = null;
    if (live) {
      await signOut();
    }
  }

  /// Which institutions (if any) the signed-in person works for.
  static Future<StaffAccess> myAccess() async {
    if (!live) {
      if (_demoStaffEmail == 'admin@institution.org') {
        return StaffAccess(isAdmin: true, institutions: sampleInstitutions);
      }
      if (_demoStaffEmail == 'staff@institution.org') {
        return StaffAccess(
          isAdmin: false,
          institutions: [sampleInstitutions.first],
        );
      }
      if (_demoStaffEmail == 'police@institution.org') {
        return StaffAccess(
          isAdmin: false,
          institutions:
              sampleInstitutions.where((i) => i.kind == 'police').toList(),
        );
      }
      return const StaffAccess();
    }
    if (!signedIn) return const StaffAccess();
    try {
      final m = await _db.rpc('my_access') as Map<String, dynamic>;
      final list = (m['institutions'] as List?) ?? const [];
      return StaffAccess(
        isAdmin: (m['is_admin'] ?? false) as bool,
        institutions: list
            .map((e) => Institution.fromRow(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return const StaffAccess();
    }
  }

  // ---------- institution board (staff) ----------
  static final List<StaffReport> _demoReports = List.from(sampleStaffReports);

  /// [institutionId] null = every report (admins only).
  static Future<List<StaffReport>> staffReports(String? institutionId) async {
    if (!live) {
      if (institutionId == null) return _demoReports;
      return _demoReports.where((r) => r.institutionName?.contains('Sample') == true).toList();
    }
    final res = await _db
        .rpc('staff_list_reports', params: {'p_institution_id': institutionId});
    return (res as List)
        .map((r) => StaffReport.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  static Future<StaffReport?> staffReport(String id) async {
    if (!live) {
      try {
        return _demoReports.firstWhere((r) => r.id == id);
      } catch (_) {
        return _demoReports.isNotEmpty ? _demoReports.first : null;
      }
    }
    final res = await _db.rpc('staff_get_report', params: {'p_report_id': id});
    final list = res as List;
    if (list.isEmpty) return null;
    return StaffReport.fromRow(list.first as Map<String, dynamic>);
  }

  static Future<void> staffSetStatus(String id, String status) async {
    if (!live) {
      final idx = _demoReports.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final old = _demoReports[idx];
        _demoReports[idx] = StaffReport(
          id: old.id,
          caseNo: old.caseNo,
          category: old.category,
          status: status,
          anonymous: old.anonymous,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
          incidentDate: old.incidentDate,
          locationText: old.locationText,
          latitude: old.latitude,
          longitude: old.longitude,
          hasGps: old.hasGps,
          snippet: old.snippet,
          description: old.description,
          institutionName: old.institutionName,
          evidenceCount: old.evidenceCount,
        );
      }
      return;
    }
    await _db.rpc('staff_set_status',
        params: {'p_report_id': id, 'p_status': status});
  }

  static Future<List<CaseMessage>> staffMessages(String id) async {
    if (!live) return const [];
    final res = await _db.rpc('staff_get_messages', params: {'p_report_id': id});
    return (res as List).map((e) {
      final r = e as Map<String, dynamic>;
      return CaseMessage(
        sender: r['sender'] as String,
        body: r['body'] as String,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  static Future<void> staffSendMessage(String id, String body) async {
    if (!live) return;
    await _db.rpc('staff_send_message',
        params: {'p_report_id': id, 'p_body': body});
  }

  /// Evidence links expire after 10 minutes.
  static Future<List<EvidenceItem>> staffEvidence(String id) async {
    if (!live) return const [];
    final res = await _db.rpc('staff_list_evidence', params: {'p_report_id': id});
    final items = <EvidenceItem>[];
    for (final e in res as List) {
      final r = e as Map<String, dynamic>;
      try {
        final url = await _db.storage
            .from('evidence')
            .createSignedUrl(r['storage_path'] as String, 600);
        items.add(EvidenceItem(url: url, mime: (r['mime'] ?? '') as String));
      } catch (_) {}
    }
    return items;
  }

  // ---------- admin ----------
  static Future<void> adminCreateInstitution({
    required String name,
    required String kind,
    String city = '',
    String region = '',
    String email = '',
  }) async {
    if (!live) return;
    await _db.rpc('admin_create_institution', params: {
      'p_name': name,
      'p_kind': kind,
      'p_city': city,
      'p_region': region,
      'p_contact_email': email,
    });
  }

  static Future<void> adminAddMember({
    required String institutionId,
    required String email,
    required String role,
  }) async {
    if (!live) return;
    await _db.rpc('admin_add_member', params: {
      'p_institution_id': institutionId,
      'p_email': email,
      'p_role': role,
    });
  }

  // ---------- directories ----------
  static Future<List<ServiceListing>> services() async {
    if (!live) return sampleServices;
    final rows =
        await _db.from('support_providers').select().eq('verified', true);
    return (rows as List)
        .map((r) => ServiceListing.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Opportunity>> opportunities() async {
    if (!live) return sampleOpportunities;
    final rows = await _db.from('opportunities').select().eq('active', true);
    return (rows as List)
        .map((r) => Opportunity.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
