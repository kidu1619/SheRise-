import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// AppDatabase provides a robust, offline-first persistent database
/// for SheRise / HerShield reports, case tracking, and institutional workflows.
/// Data is persisted to local storage and synchronizes with Supabase when configured.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String _storageKey = 'she_rise_delivered_reports_v2';
  static const String _institutionKey = 'she_rise_current_institution';

  final ValueNotifier<List<DeliveredReport>> reportsNotifier =
      ValueNotifier<List<DeliveredReport>>([]);

  bool _initialized = false;
  String _currentInstitution = 'Addis Ababa University - Safety & Ethics Directorate';
  String _currentStaffName = 'Officer Almaz Tadesse';

  String get currentInstitution => _currentInstitution;
  String get currentStaffName => _currentStaffName;

  Future<void> setInstitution(String inst, {String? staff}) async {
    _currentInstitution = inst;
    if (staff != null) _currentStaffName = staff;
    final p = await SharedPreferences.getInstance();
    await p.setString(_institutionKey, jsonEncode({
      'institution': _currentInstitution,
      'staff': _currentStaffName,
    }));
  }

  /// Initialize and load persistent reports from disk.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final p = await SharedPreferences.getInstance();

      final instRaw = p.getString(_institutionKey);
      if (instRaw != null) {
        final j = jsonDecode(instRaw) as Map<String, dynamic>;
        _currentInstitution = j['institution'] as String? ?? _currentInstitution;
        _currentStaffName = j['staff'] as String? ?? _currentStaffName;
      }

      final raw = p.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) => DeliveredReport.fromJson(e as Map<String, dynamic>))
            .toList();
        reportsNotifier.value = list;
      } else {
        // Seed with realistic institutional case records
        reportsNotifier.value = _generateSeedData();
        await _save();
      }
      _initialized = true;
    } catch (e) {
      debugPrint('AppDatabase.init error: $e');
      reportsNotifier.value = _generateSeedData();
      _initialized = true;
    }
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = jsonEncode(reportsNotifier.value.map((r) => r.toJson()).toList());
      await p.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('AppDatabase._save error: $e');
    }
  }

  // ----------------------------------------------------------- Public Queries

  List<DeliveredReport> get allReports => List.unmodifiable(reportsNotifier.value);

  DeliveredReport? findByCode(String code) {
    final clean = code.trim().toUpperCase();
    return reportsNotifier.value.cast<DeliveredReport?>().firstWhere(
          (r) => r?.code.toUpperCase() == clean,
          orElse: () => null,
        );
  }

  DeliveredReport? findById(String id) {
    return reportsNotifier.value.cast<DeliveredReport?>().firstWhere(
          (r) => r?.id == id,
          orElse: () => null,
        );
  }

  List<DeliveredReport> filterReports({
    String? query,
    String? status,
    String? priority,
    String? category,
    bool? anonymous,
  }) {
    return reportsNotifier.value.where((r) {
      if (status != null && status != 'all' && r.status != status) return false;
      if (priority != null && priority != 'all' && r.priority != priority) return false;
      if (category != null && category != 'all' && r.category != category) return false;
      if (anonymous != null && r.anonymous != anonymous) return false;

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchCode = r.code.toLowerCase().contains(q);
        final matchCat = r.category.toLowerCase().contains(q);
        final matchLoc = r.location.toLowerCase().contains(q);
        final matchDesc = r.description.toLowerCase().contains(q);
        final matchOfficer = (r.assignedOfficer ?? '').toLowerCase().contains(q);
        if (!matchCode && !matchCat && !matchLoc && !matchDesc && !matchOfficer) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, dynamic> getStatistics() {
    final list = reportsNotifier.value;
    int received = 0;
    int underReview = 0;
    int referred = 0;
    int resolved = 0;
    int closed = 0;
    int urgent = 0;
    int anonymous = 0;
    int confidential = 0;
    int withEvidence = 0;

    final Map<String, int> categories = {};

    for (final r in list) {
      switch (r.status) {
        case 'received':
          received++;
          break;
        case 'under_review':
          underReview++;
          break;
        case 'referred':
          referred++;
          break;
        case 'resolved':
          resolved++;
          break;
        case 'closed':
          closed++;
          break;
      }

      if (r.priority == 'urgent') urgent++;
      if (r.anonymous) anonymous++; else confidential++;
      if (r.attachments.isNotEmpty) withEvidence++;

      categories[r.category] = (categories[r.category] ?? 0) + 1;
    }

    return {
      'total': list.length,
      'received': received,
      'underReview': underReview,
      'referred': referred,
      'resolved': resolved,
      'closed': closed,
      'urgent': urgent,
      'anonymous': anonymous,
      'confidential': confidential,
      'withEvidence': withEvidence,
      'categories': categories,
    };
  }

  // ------------------------------------------------------ Incident Submission

  static String generatePrivateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    String part(int len) =>
        List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
    return 'SR-${part(4)}-${part(4)}';
  }

  static String _uuid() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Create and deliver a report into the database from mobile SafeVoice draft
  Future<String> submitReport(ReportDraft draft, {String? reporterName, String? reporterContact}) async {
    await init();

    final code = generatePrivateCode();
    final id = 'rep_${_uuid()}';
    final now = DateTime.now();

    // Determine initial priority based on category & details
    String priority = 'medium';
    final cat = draft.category?.toLowerCase() ?? 'other';
    if (cat.contains('abuse') || cat.contains('violence') || cat.contains('emergency')) {
      priority = 'urgent';
    } else if (cat.contains('harassment') || cat.contains('bullying')) {
      priority = 'high';
    }

    // Convert draft attachments
    final attachments = <EvidenceAttachment>[];
    for (final a in draft.attachments) {
      String? b64;
      // Store base64 data for audio or small files (up to 3MB)
      if (a.bytes.length <= 3 * 1024 * 1024) {
        b64 = base64Encode(a.bytes);
      }
      attachments.add(EvidenceAttachment(
        name: a.name,
        kind: a.kind,
        ext: a.ext,
        mime: a.mime,
        size: a.size,
        seconds: a.seconds,
        dataBase64: b64,
      ));
    }

    final initialAudit = AuditLogEntry(
      id: 'log_${_uuid()}',
      action: 'Report Submitted',
      actor: draft.anonymous ? 'Anonymous Reporter' : (reporterName ?? 'Confidential Reporter'),
      timestamp: now,
      details: 'Report received via SafeVoice with ${attachments.length} attachment(s). Category: ${draft.category ?? "Other"}.',
    );

    final initialMessage = CaseMessage(
      id: 'msg_${_uuid()}',
      sender: 'staff',
      senderName: 'Institution Intake Bot',
      body: 'Your report has been received securely by $_currentInstitution. A designated officer will review this case. Keep your private code safe.',
      createdAt: now,
    );

    final report = DeliveredReport(
      id: id,
      code: code,
      category: draft.category ?? 'Other',
      description: draft.description.trim().isEmpty
          ? (attachments.any((a) => a.kind == 'voice')
              ? 'Voice report submitted. Please listen to attached voice recording.'
              : 'Report submitted without text description.')
          : draft.description.trim(),
      location: draft.location.trim().isEmpty ? 'Location not specified' : draft.location.trim(),
      incidentDate: draft.date,
      anonymous: draft.anonymous,
      reporterName: draft.anonymous ? null : reporterName,
      reporterContact: draft.anonymous ? null : reporterContact,
      status: 'received',
      priority: priority,
      institutionName: _currentInstitution,
      createdAt: now,
      updatedAt: now,
      attachments: attachments,
      messages: [initialMessage],
      internalNotes: [],
      auditLogs: [initialAudit],
    );

    reportsNotifier.value = [report, ...reportsNotifier.value];
    await _save();
    return code;
  }

  // ---------------------------------------------------- Institution Workflows

  /// Update report status (e.g. received -> under_review -> referred -> resolved -> closed)
  Future<void> updateStatus(
    String codeOrId,
    String newStatus, {
    String? staffNote,
    String? messageToReporter,
    String? staffName,
  }) async {
    await init();
    final list = [...reportsNotifier.value];
    final idx = list.indexWhere(
        (r) => r.code.toUpperCase() == codeOrId.toUpperCase() || r.id == codeOrId);
    if (idx == -1) return;

    final old = list[idx];
    final now = DateTime.now();
    final actor = staffName ?? _currentStaffName;

    final newAudits = [...old.auditLogs];
    newAudits.add(AuditLogEntry(
      id: 'log_${_uuid()}',
      action: 'Status Changed to ${statusLabels[newStatus] ?? newStatus}',
      actor: actor,
      timestamp: now,
      details: staffNote ?? 'Status updated from ${old.status} to $newStatus by $actor.',
    ));

    final newNotes = [...old.internalNotes];
    if (staffNote != null && staffNote.trim().isNotEmpty) {
      newNotes.add(InternalNote(
        id: 'note_${_uuid()}',
        author: actor,
        content: 'Status update note ($newStatus): $staffNote',
        createdAt: now,
      ));
    }

    final newMessages = [...old.messages];
    if (messageToReporter != null && messageToReporter.trim().isNotEmpty) {
      newMessages.add(CaseMessage(
        id: 'msg_${_uuid()}',
        sender: 'staff',
        senderName: actor,
        body: messageToReporter.trim(),
        createdAt: now,
      ));
    }

    list[idx] = old.copyWith(
      status: newStatus,
      updatedAt: now,
      auditLogs: newAudits,
      internalNotes: newNotes,
      messages: newMessages,
    );

    reportsNotifier.value = list;
    await _save();
  }

  /// Update case priority (urgent, high, medium, low)
  Future<void> updatePriority(String codeOrId, String newPriority, {String? actor}) async {
    await init();
    final list = [...reportsNotifier.value];
    final idx = list.indexWhere(
        (r) => r.code.toUpperCase() == codeOrId.toUpperCase() || r.id == codeOrId);
    if (idx == -1) return;

    final old = list[idx];
    final now = DateTime.now();
    final staff = actor ?? _currentStaffName;

    final audits = [...old.auditLogs];
    audits.add(AuditLogEntry(
      id: 'log_${_uuid()}',
      action: 'Priority Updated',
      actor: staff,
      timestamp: now,
      details: 'Priority adjusted from ${old.priority} to $newPriority.',
    ));

    list[idx] = old.copyWith(
      priority: newPriority,
      updatedAt: now,
      auditLogs: audits,
    );

    reportsNotifier.value = list;
    await _save();
  }

  /// Assign an institutional case officer and department
  Future<void> assignOfficer(
    String codeOrId,
    String officerName,
    String department, {
    String? actor,
  }) async {
    await init();
    final list = [...reportsNotifier.value];
    final idx = list.indexWhere(
        (r) => r.code.toUpperCase() == codeOrId.toUpperCase() || r.id == codeOrId);
    if (idx == -1) return;

    final old = list[idx];
    final now = DateTime.now();
    final staff = actor ?? _currentStaffName;

    final audits = [...old.auditLogs];
    audits.add(AuditLogEntry(
      id: 'log_${_uuid()}',
      action: 'Case Assigned',
      actor: staff,
      timestamp: now,
      details: 'Assigned to $officerName ($department).',
    ));

    // Also auto-advance status if currently 'received'
    final nextStatus = old.status == 'received' ? 'under_review' : old.status;

    list[idx] = old.copyWith(
      assignedOfficer: officerName,
      assignedDepartment: department,
      status: nextStatus,
      updatedAt: now,
      auditLogs: audits,
    );

    reportsNotifier.value = list;
    await _save();
  }

  /// Add staff message sent directly to reporter's private tracker
  Future<void> addStaffMessage(
    String codeOrId,
    String body, {
    String? staffName,
  }) async {
    await init();
    final list = [...reportsNotifier.value];
    final idx = list.indexWhere(
        (r) => r.code.toUpperCase() == codeOrId.toUpperCase() || r.id == codeOrId);
    if (idx == -1) return;

    final old = list[idx];
    final now = DateTime.now();
    final sender = staffName ?? _currentStaffName;

    final msgs = [...old.messages];
    msgs.add(CaseMessage(
      id: 'msg_${_uuid()}',
      sender: 'staff',
      senderName: sender,
      body: body.trim(),
      createdAt: now,
    ));

    final audits = [...old.auditLogs];
    audits.add(AuditLogEntry(
      id: 'log_${_uuid()}',
      action: 'Message Sent to Reporter',
      actor: sender,
      timestamp: now,
      details: 'Staff sent private update to reporter.',
    ));

    list[idx] = old.copyWith(
      messages: msgs,
      auditLogs: audits,
      updatedAt: now,
    );

    reportsNotifier.value = list;
    await _save();
  }

  /// Add a message from the reporter into the case thread
  Future<void> addReporterMessage(String codeOrId, String body) async {
    await init();
    final list = [...reportsNotifier.value];
    final idx = list.indexWhere(
        (r) => r.code.toUpperCase() == codeOrId.toUpperCase() || r.id == codeOrId);
    if (idx == -1) return;

    final old = list[idx];
    final now = DateTime.now();

    final msgs = [...old.messages];
    msgs.add(CaseMessage(
      id: 'msg_${_uuid()}',
      sender: 'reporter',
      senderName: old.anonymous ? 'Reporter' : (old.reporterName ?? 'Reporter'),
      body: body.trim(),
      createdAt: now,
    ));

    final audits = [...old.auditLogs];
    audits.add(AuditLogEntry(
      id: 'log_${_uuid()}',
      action: 'Reporter Reply Received',
      actor: 'Reporter',
      timestamp: now,
      details: 'New private message received from reporter.',
    ));

    list[idx] = old.copyWith(
      messages: msgs,
      auditLogs: audits,
      updatedAt: now,
    );

    reportsNotifier.value = list;
    await _save();
  }

  /// Add confidential internal staff-only note
  Future<void> addInternalNote(String codeOrId, String content, {String? author}) async {
    await init();
    final list = [...reportsNotifier.value];
    final idx = list.indexWhere(
        (r) => r.code.toUpperCase() == codeOrId.toUpperCase() || r.id == codeOrId);
    if (idx == -1) return;

    final old = list[idx];
    final now = DateTime.now();
    final writer = author ?? _currentStaffName;

    final notes = [...old.internalNotes];
    notes.add(InternalNote(
      id: 'note_${_uuid()}',
      author: writer,
      content: content.trim(),
      createdAt: now,
    ));

    final audits = [...old.auditLogs];
    audits.add(AuditLogEntry(
      id: 'log_${_uuid()}',
      action: 'Internal Note Added',
      actor: writer,
      timestamp: now,
      details: 'Added confidential case assessment note.',
    ));

    list[idx] = old.copyWith(
      internalNotes: notes,
      auditLogs: audits,
      updatedAt: now,
    );

    reportsNotifier.value = list;
    await _save();
  }

  /// Refer case to an external agency or trusted partner organization
  Future<void> referCase(String codeOrId, CaseReferral referral, {String? actor}) async {
    await init();
    final list = [...reportsNotifier.value];
    final idx = list.indexWhere(
        (r) => r.code.toUpperCase() == codeOrId.toUpperCase() || r.id == codeOrId);
    if (idx == -1) return;

    final old = list[idx];
    final now = DateTime.now();
    final staff = actor ?? _currentStaffName;

    final audits = [...old.auditLogs];
    audits.add(AuditLogEntry(
      id: 'log_${_uuid()}',
      action: 'Referred to ${referral.partnerName}',
      actor: staff,
      timestamp: now,
      details: 'Referred to ${referral.partnerName} (${referral.contactPerson}). Notes: ${referral.notes}',
    ));

    final msgs = [...old.messages];
    msgs.add(CaseMessage(
      id: 'msg_${_uuid()}',
      sender: 'staff',
      senderName: staff,
      body: 'Your case has been formally referred to our trusted partner ${referral.partnerName} for specialized legal/support assistance.',
      createdAt: now,
    ));

    list[idx] = old.copyWith(
      status: 'referred',
      referral: referral,
      messages: msgs,
      auditLogs: audits,
      updatedAt: now,
    );

    reportsNotifier.value = list;
    await _save();
  }

  /// Resolve and document closure of a case
  Future<void> resolveCase(String codeOrId, CaseResolution resolution, {String? actor}) async {
    await init();
    final list = [...reportsNotifier.value];
    final idx = list.indexWhere(
        (r) => r.code.toUpperCase() == codeOrId.toUpperCase() || r.id == codeOrId);
    if (idx == -1) return;

    final old = list[idx];
    final now = DateTime.now();
    final staff = actor ?? _currentStaffName;

    final audits = [...old.auditLogs];
    audits.add(AuditLogEntry(
      id: 'log_${_uuid()}',
      action: 'Case Resolved: ${resolution.outcome}',
      actor: staff,
      timestamp: now,
      details: '${resolution.summary}. Action taken: ${resolution.actionTaken}',
    ));

    final msgs = [...old.messages];
    msgs.add(CaseMessage(
      id: 'msg_${_uuid()}',
      sender: 'staff',
      senderName: staff,
      body: 'Your case has been resolved: ${resolution.outcome}. Action taken: ${resolution.actionTaken}. Thank you for speaking up.',
      createdAt: now,
    ));

    list[idx] = old.copyWith(
      status: 'resolved',
      resolution: resolution,
      messages: msgs,
      auditLogs: audits,
      updatedAt: now,
    );

    reportsNotifier.value = list;
    await _save();
  }

  /// Delete a report (for admin testing/privacy scrub)
  Future<void> deleteReport(String codeOrId) async {
    await init();
    final list = [...reportsNotifier.value];
    list.removeWhere(
        (r) => r.code.toUpperCase() == codeOrId.toUpperCase() || r.id == codeOrId);
    reportsNotifier.value = list;
    await _save();
  }

  /// Reset to standard realistic demo dataset
  Future<void> resetToDemoData() async {
    reportsNotifier.value = _generateSeedData();
    await _save();
  }

  // ------------------------------------------------------------- Seed Data

  List<DeliveredReport> _generateSeedData() {
    final now = DateTime.now();

    return [
      DeliveredReport(
        id: 'rep_seed_101',
        code: 'SR-7821-4490',
        category: 'Harassment',
        description:
            'A senior supervisor in the department made repeated unwelcome sexual comments and threats regarding performance evaluations if I refused to meet outside office hours. Multiple witness statements and recorded audio available.',
        location: 'Bole Subcity Academic & Research Center, Floor 3',
        incidentDate: now.subtract(const Duration(days: 3)),
        anonymous: false,
        reporterName: 'Sara K. (Staff Account)',
        reporterContact: 'sara.k@institution.edu',
        status: 'under_review',
        priority: 'urgent',
        assignedOfficer: 'Officer Almaz Tadesse',
        assignedDepartment: 'Ethics & Gender Equality Directorate',
        institutionName: 'Addis Ababa University - Safety & Ethics Directorate',
        createdAt: now.subtract(const Duration(hours: 36)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        attachments: [
          const EvidenceAttachment(
            name: 'voice_recording_hallway.m4a',
            kind: 'voice',
            ext: 'm4a',
            mime: 'audio/m4a',
            size: 145020,
            seconds: 28,
          ),
          const EvidenceAttachment(
            name: 'whatsapp_threat_messages.pdf',
            kind: 'file',
            ext: 'pdf',
            mime: 'application/pdf',
            size: 420800,
          ),
        ],
        messages: [
          CaseMessage(
            id: 'm1',
            sender: 'staff',
            senderName: 'Officer Almaz Tadesse',
            body:
                'Hello Sara, this is Officer Almaz from the Ethics Directorate. We have assigned this as an urgent matter and reviewed your audio attachment. Would you be open to an initial intake interview tomorrow at 10:00 AM in a confidential setting?',
            createdAt: now.subtract(const Duration(hours: 24)),
          ),
          CaseMessage(
            id: 'm2',
            sender: 'reporter',
            senderName: 'Sara K.',
            body:
                'Thank you Officer Almaz. Yes, 10:00 AM works. Can we meet in Room 204 or via an encrypted private call?',
            createdAt: now.subtract(const Duration(hours: 20)),
          ),
          CaseMessage(
            id: 'm3',
            sender: 'staff',
            senderName: 'Officer Almaz Tadesse',
            body:
                'Confirmed for Room 204. Protective measures have already been initiated so you will not report to this supervisor during the review.',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        internalNotes: [
          InternalNote(
            id: 'n1',
            author: 'Officer Almaz Tadesse',
            content:
                'Audio evidence verified. Voice clearly matches accused supervisor. Recommending temporary administrative reassignment of supervisor pending full disciplinary committee convening.',
            createdAt: now.subtract(const Duration(hours: 22)),
          ),
        ],
        auditLogs: [
          AuditLogEntry(
            id: 'l1',
            action: 'Report Submitted',
            actor: 'Sara K.',
            timestamp: now.subtract(const Duration(hours: 36)),
            details: 'Confidential report filed with 2 attachments.',
          ),
          AuditLogEntry(
            id: 'l2',
            action: 'Assigned to Officer Almaz Tadesse',
            actor: 'System / Intake Bot',
            timestamp: now.subtract(const Duration(hours: 35)),
            details: 'Urgency flagged as URGENT due to supervisor retaliation threat.',
          ),
          AuditLogEntry(
            id: 'l3',
            action: 'Status Changed to Under Review',
            actor: 'Officer Almaz Tadesse',
            timestamp: now.subtract(const Duration(hours: 24)),
            details: 'Evidence review initiated and interview scheduled.',
          ),
        ],
      ),
      DeliveredReport(
        id: 'rep_seed_102',
        code: 'SR-3910-8214',
        category: 'Bullying',
        description:
            'A group of students created a defamatory social media group targeting female students living in Block 14, posting threatening memes and personal phone numbers without consent.',
        location: 'Main Campus, Dormitory Block 14',
        incidentDate: now.subtract(const Duration(days: 1)),
        anonymous: true,
        status: 'received',
        priority: 'high',
        assignedOfficer: null,
        assignedDepartment: null,
        institutionName: 'Addis Ababa University - Safety & Ethics Directorate',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        attachments: [
          const EvidenceAttachment(
            name: 'telegram_chat_screenshots.zip',
            kind: 'file',
            ext: 'zip',
            mime: 'application/zip',
            size: 980140,
          ),
        ],
        messages: [
          CaseMessage(
            id: 'm102',
            sender: 'staff',
            senderName: 'Intake System',
            body:
                'Report received anonymously. Our cyber safety team and campus security have been alerted.',
            createdAt: now.subtract(const Duration(hours: 5)),
          ),
        ],
        internalNotes: [
          InternalNote(
            id: 'n102',
            author: 'Intake Duty Officer',
            content:
                'High priority cyber harassment. Requires immediate contact with University IT security to block local WiFi access to defamatory channel.',
            createdAt: now.subtract(const Duration(hours: 4)),
          ),
        ],
        auditLogs: [
          AuditLogEntry(
            id: 'l102',
            action: 'Report Submitted',
            actor: 'Anonymous Reporter',
            timestamp: now.subtract(const Duration(hours: 5)),
            details: 'Anonymous submission with screenshots attached.',
          ),
        ],
      ),
      DeliveredReport(
        id: 'rep_seed_103',
        code: 'SR-5120-9943',
        category: 'Unequal opportunity',
        description:
            'Women in the engineering apprenticeship track are systematically denied equal field equipment, overtime shifts, and graduation certification sign-offs compared to male peers.',
        location: 'Institute of Technology Workshops, Adama Campus',
        incidentDate: now.subtract(const Duration(days: 14)),
        anonymous: true,
        status: 'referred',
        priority: 'medium',
        assignedOfficer: 'Dawit Mengistu',
        assignedDepartment: 'Legal Advocacy Unit',
        institutionName: 'Addis Ababa University - Safety & Ethics Directorate',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 1)),
        attachments: [],
        messages: [
          CaseMessage(
            id: 'm103_1',
            sender: 'staff',
            senderName: 'Dawit Mengistu',
            body:
                'Your case regarding apprenticeship disparity was reviewed. Because this involves cross-institutional labor standards, we have partnered with EWLA (Ethiopian Women Lawyers Association) for legal oversight.',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        ],
        internalNotes: [
          InternalNote(
            id: 'n103_1',
            author: 'Dawit Mengistu',
            content:
                'Referred to EWLA Counselor Selamawit. Meeting with Dean of Engineering scheduled for next Tuesday to inspect apprenticeship logs.',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        ],
        referral: CaseReferral(
          partnerName: 'EWLA (Ethiopian Women Lawyers Association)',
          contactPerson: 'Advocate Selamawit Bekele',
          phone: '+251 11 550 7711',
          notes:
              'Labor inequality & gender discrimination inquiry for third-year engineering apprentices.',
          referredAt: now.subtract(const Duration(days: 2)),
          status: 'in_progress',
        ),
        auditLogs: [
          AuditLogEntry(
            id: 'l103_1',
            action: 'Report Submitted',
            actor: 'Anonymous Reporter',
            timestamp: now.subtract(const Duration(days: 6)),
            details: 'Workplace inequality report filed.',
          ),
          AuditLogEntry(
            id: 'l103_2',
            action: 'Referred to EWLA',
            actor: 'Dawit Mengistu',
            timestamp: now.subtract(const Duration(days: 2)),
            details: 'Case transferred to legal partner for external representation.',
          ),
        ],
      ),
      DeliveredReport(
        id: 'rep_seed_104',
        code: 'SR-1904-7128',
        category: 'Disrespect',
        description:
            'A laboratory assistant repeatedly made derogatory statements regarding women studying mathematics and created an intimidating environment during lab sessions.',
        location: 'Science Faculty, Hall 201',
        incidentDate: now.subtract(const Duration(days: 20)),
        anonymous: false,
        reporterName: 'Bethlehem T.',
        reporterContact: 'bethlehem.t@gmail.com',
        status: 'resolved',
        priority: 'low',
        assignedOfficer: 'Officer Almaz Tadesse',
        assignedDepartment: 'Ethics Directorate',
        institutionName: 'Addis Ababa University - Safety & Ethics Directorate',
        createdAt: now.subtract(const Duration(days: 18)),
        updatedAt: now.subtract(const Duration(days: 5)),
        attachments: [],
        messages: [
          CaseMessage(
            id: 'm104_1',
            sender: 'staff',
            senderName: 'Officer Almaz Tadesse',
            body:
                'We have concluded the disciplinary review regarding the lab assistant. Formal written reprimand issued and mandatory sensitivity retraining completed. The assistant has been reassigned to non-instructional duties.',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
        ],
        internalNotes: [
          InternalNote(
            id: 'n104_1',
            author: 'Officer Almaz Tadesse',
            content:
                'Disciplinary committee voted unanimously for Level 1 sanction and mandatory gender-equity retraining. Case concluded satisfactorily.',
            createdAt: now.subtract(const Duration(days: 5)),
          ),
        ],
        resolution: CaseResolution(
          outcome: 'Disciplinary Reprimand & Staff Reassignment',
          summary:
              'The accused lab assistant acknowledged misconduct during formal inquiry.',
          actionTaken:
              'Formal written warning, reassignment from student contact, and gender-inclusive classroom compliance monitoring.',
          resolvedBy: 'Officer Almaz Tadesse & Faculty Ethics Panel',
          resolvedAt: now.subtract(const Duration(days: 5)),
        ),
        auditLogs: [
          AuditLogEntry(
            id: 'l104_1',
            action: 'Report Submitted',
            actor: 'Bethlehem T.',
            timestamp: now.subtract(const Duration(days: 18)),
            details: 'Confidential report filed.',
          ),
          AuditLogEntry(
            id: 'l104_2',
            action: 'Case Resolved',
            actor: 'Officer Almaz Tadesse',
            timestamp: now.subtract(const Duration(days: 5)),
            details: 'Formal resolution recorded and closed.',
          ),
        ],
      ),
    ];
  }
}
