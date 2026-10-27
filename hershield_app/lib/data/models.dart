import 'dart:typed_data';

/// A photo, PDF or voice note attached to a report (held in memory only).
class Attachment {
  const Attachment({
    required this.name,
    required this.kind, // 'file' or 'voice'
    required this.ext,
    required this.mime,
    required this.bytes,
    this.seconds,
  });

  final String name; // shown to the user only, never uploaded
  final String kind;
  final String ext;
  final String mime;
  final Uint8List bytes;
  final int? seconds;

  int get size => bytes.length;
}

class ReportDraft {
  const ReportDraft({
    this.category,
    this.date,
    this.location = '',
    this.description = '',
    this.anonymous = true,
    this.attachments = const [],
  });

  final String? category;
  final DateTime? date;
  final String location;
  final String description;
  final bool anonymous;
  final List<Attachment> attachments;

  ReportDraft copyWith({
    String? category,
    DateTime? date,
    String? location,
    String? description,
    bool? anonymous,
    List<Attachment>? attachments,
  }) =>
      ReportDraft(
        category: category ?? this.category,
        date: date ?? this.date,
        location: location ?? this.location,
        description: description ?? this.description,
        anonymous: anonymous ?? this.anonymous,
        attachments: attachments ?? this.attachments,
      );

  bool get isEmpty =>
      category == null &&
      description.isEmpty &&
      location.isEmpty &&
      attachments.isEmpty;
}

class CaseRecord {
  const CaseRecord({
    required this.code,
    required this.category,
    required this.createdAt,
    required this.status,
  });

  final String code;
  final String category;
  final DateTime createdAt;
  final String status;

  Map<String, dynamic> toJson() => {
        'code': code,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
      };

  factory CaseRecord.fromJson(Map<String, dynamic> j) => CaseRecord(
        code: j['code'] as String,
        category: j['category'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: j['status'] as String,
      );
}

class CaseStatus {
  const CaseStatus({
    required this.status,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });
  final String status;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CaseMessage {
  const CaseMessage({
    required this.sender,
    required this.body,
    required this.createdAt,
    this.id,
    this.senderName,
  });

  final String? id;
  final String sender; // 'reporter' or 'staff'
  final String? senderName;
  final String body;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id ?? '',
        'sender': sender,
        'senderName': senderName ?? (sender == 'reporter' ? 'Reporter' : 'Support Officer'),
        'body': body,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CaseMessage.fromJson(Map<String, dynamic> j) => CaseMessage(
        id: j['id'] as String?,
        sender: j['sender'] as String? ?? 'reporter',
        senderName: j['senderName'] as String?,
        body: j['body'] as String? ?? '',
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
      );
}

class EvidenceAttachment {
  const EvidenceAttachment({
    required this.name,
    required this.kind, // 'voice' or 'file'
    required this.ext,
    required this.mime,
    required this.size,
    this.seconds,
    this.dataBase64,
  });

  final String name;
  final String kind;
  final String ext;
  final String mime;
  final int size;
  final int? seconds;
  final String? dataBase64;

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind,
        'ext': ext,
        'mime': mime,
        'size': size,
        'seconds': seconds,
        'dataBase64': dataBase64,
      };

  factory EvidenceAttachment.fromJson(Map<String, dynamic> j) =>
      EvidenceAttachment(
        name: j['name'] as String? ?? 'attachment',
        kind: j['kind'] as String? ?? 'file',
        ext: j['ext'] as String? ?? '',
        mime: j['mime'] as String? ?? 'application/octet-stream',
        size: (j['size'] as num?)?.toInt() ?? 0,
        seconds: (j['seconds'] as num?)?.toInt(),
        dataBase64: j['dataBase64'] as String?,
      );
}

class InternalNote {
  const InternalNote({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String author;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InternalNote.fromJson(Map<String, dynamic> j) => InternalNote(
        id: j['id'] as String? ?? '',
        author: j['author'] as String? ?? 'Officer',
        content: j['content'] as String? ?? '',
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
      );
}

class CaseReferral {
  const CaseReferral({
    required this.partnerName,
    required this.contactPerson,
    required this.phone,
    required this.notes,
    required this.referredAt,
    this.status = 'pending',
  });

  final String partnerName;
  final String contactPerson;
  final String phone;
  final String notes;
  final DateTime referredAt;
  final String status; // 'pending', 'in_progress', 'completed'

  Map<String, dynamic> toJson() => {
        'partnerName': partnerName,
        'contactPerson': contactPerson,
        'phone': phone,
        'notes': notes,
        'referredAt': referredAt.toIso8601String(),
        'status': status,
      };

  factory CaseReferral.fromJson(Map<String, dynamic> j) => CaseReferral(
        partnerName: j['partnerName'] as String? ?? '',
        contactPerson: j['contactPerson'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        referredAt: j['referredAt'] != null
            ? DateTime.parse(j['referredAt'] as String)
            : DateTime.now(),
        status: j['status'] as String? ?? 'pending',
      );
}

class CaseResolution {
  const CaseResolution({
    required this.outcome,
    required this.summary,
    required this.actionTaken,
    required this.resolvedBy,
    required this.resolvedAt,
  });

  final String outcome;
  final String summary;
  final String actionTaken;
  final String resolvedBy;
  final DateTime resolvedAt;

  Map<String, dynamic> toJson() => {
        'outcome': outcome,
        'summary': summary,
        'actionTaken': actionTaken,
        'resolvedBy': resolvedBy,
        'resolvedAt': resolvedAt.toIso8601String(),
      };

  factory CaseResolution.fromJson(Map<String, dynamic> j) => CaseResolution(
        outcome: j['outcome'] as String? ?? '',
        summary: j['summary'] as String? ?? '',
        actionTaken: j['actionTaken'] as String? ?? '',
        resolvedBy: j['resolvedBy'] as String? ?? '',
        resolvedAt: j['resolvedAt'] != null
            ? DateTime.parse(j['resolvedAt'] as String)
            : DateTime.now(),
      );
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.actor,
    required this.timestamp,
    required this.details,
  });

  final String id;
  final String action;
  final String actor;
  final DateTime timestamp;
  final String details;

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'actor': actor,
        'timestamp': timestamp.toIso8601String(),
        'details': details,
      };

  factory AuditLogEntry.fromJson(Map<String, dynamic> j) => AuditLogEntry(
        id: j['id'] as String? ?? '',
        action: j['action'] as String? ?? '',
        actor: j['actor'] as String? ?? '',
        timestamp: j['timestamp'] != null
            ? DateTime.parse(j['timestamp'] as String)
            : DateTime.now(),
        details: j['details'] as String? ?? '',
      );
}

class DeliveredReport {
  const DeliveredReport({
    required this.id,
    required this.code,
    required this.category,
    required this.description,
    required this.location,
    this.incidentDate,
    required this.anonymous,
    this.reporterName,
    this.reporterContact,
    required this.status,
    required this.priority,
    this.assignedOfficer,
    this.assignedDepartment,
    required this.institutionName,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.messages = const [],
    this.internalNotes = const [],
    this.referral,
    this.resolution,
    this.auditLogs = const [],
  });

  final String id;
  final String code;
  final String category;
  final String description;
  final String location;
  final DateTime? incidentDate;
  final bool anonymous;
  final String? reporterName;
  final String? reporterContact;
  final String status; // 'received', 'under_review', 'referred', 'resolved', 'closed'
  final String priority; // 'urgent', 'high', 'medium', 'low'
  final String? assignedOfficer;
  final String? assignedDepartment;
  final String institutionName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<EvidenceAttachment> attachments;
  final List<CaseMessage> messages;
  final List<InternalNote> internalNotes;
  final CaseReferral? referral;
  final CaseResolution? resolution;
  final List<AuditLogEntry> auditLogs;

  DeliveredReport copyWith({
    String? id,
    String? code,
    String? category,
    String? description,
    String? location,
    DateTime? incidentDate,
    bool? anonymous,
    String? reporterName,
    String? reporterContact,
    String? status,
    String? priority,
    String? assignedOfficer,
    String? assignedDepartment,
    String? institutionName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<EvidenceAttachment>? attachments,
    List<CaseMessage>? messages,
    List<InternalNote>? internalNotes,
    CaseReferral? referral,
    CaseResolution? resolution,
    List<AuditLogEntry>? auditLogs,
  }) =>
      DeliveredReport(
        id: id ?? this.id,
        code: code ?? this.code,
        category: category ?? this.category,
        description: description ?? this.description,
        location: location ?? this.location,
        incidentDate: incidentDate ?? this.incidentDate,
        anonymous: anonymous ?? this.anonymous,
        reporterName: reporterName ?? this.reporterName,
        reporterContact: reporterContact ?? this.reporterContact,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        assignedOfficer: assignedOfficer ?? this.assignedOfficer,
        assignedDepartment: assignedDepartment ?? this.assignedDepartment,
        institutionName: institutionName ?? this.institutionName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        attachments: attachments ?? this.attachments,
        messages: messages ?? this.messages,
        internalNotes: internalNotes ?? this.internalNotes,
        referral: referral ?? this.referral,
        resolution: resolution ?? this.resolution,
        auditLogs: auditLogs ?? this.auditLogs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'category': category,
        'description': description,
        'location': location,
        'incidentDate': incidentDate?.toIso8601String(),
        'anonymous': anonymous,
        'reporterName': reporterName,
        'reporterContact': reporterContact,
        'status': status,
        'priority': priority,
        'assignedOfficer': assignedOfficer,
        'assignedDepartment': assignedDepartment,
        'institutionName': institutionName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'internalNotes': internalNotes.map((n) => n.toJson()).toList(),
        'referral': referral?.toJson(),
        'resolution': resolution?.toJson(),
        'auditLogs': auditLogs.map((l) => l.toJson()).toList(),
      };

  factory DeliveredReport.fromJson(Map<String, dynamic> j) => DeliveredReport(
        id: j['id'] as String? ?? '',
        code: j['code'] as String? ?? '',
        category: j['category'] as String? ?? 'Other',
        description: j['description'] as String? ?? '',
        location: j['location'] as String? ?? '',
        incidentDate: j['incidentDate'] != null
            ? DateTime.tryParse(j['incidentDate'] as String)
            : null,
        anonymous: (j['anonymous'] as bool?) ?? true,
        reporterName: j['reporterName'] as String?,
        reporterContact: j['reporterContact'] as String?,
        status: j['status'] as String? ?? 'received',
        priority: j['priority'] as String? ?? 'medium',
        assignedOfficer: j['assignedOfficer'] as String?,
        assignedDepartment: j['assignedDepartment'] as String?,
        institutionName: j['institutionName'] as String? ?? 'Ethics Directorate',
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'] as String)
            : DateTime.now(),
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String)
            : DateTime.now(),
        attachments: ((j['attachments'] as List?) ?? [])
            .map((e) => EvidenceAttachment.fromJson(e as Map<String, dynamic>))
            .toList(),
        messages: ((j['messages'] as List?) ?? [])
            .map((e) => CaseMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        internalNotes: ((j['internalNotes'] as List?) ?? [])
            .map((e) => InternalNote.fromJson(e as Map<String, dynamic>))
            .toList(),
        referral: j['referral'] != null
            ? CaseReferral.fromJson(j['referral'] as Map<String, dynamic>)
            : null,
        resolution: j['resolution'] != null
            ? CaseResolution.fromJson(j['resolution'] as Map<String, dynamic>)
            : null,
        auditLogs: ((j['auditLogs'] as List?) ?? [])
            .map((e) => AuditLogEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

const priorityLabels = {
  'urgent': 'Urgent',
  'high': 'High',
  'medium': 'Medium',
  'low': 'Low',
};

class TrustedContact {
  const TrustedContact(
      {required this.name, required this.relation, required this.phone});
  final String name;
  final String relation;
  final String phone;

  String get masked => phone.length < 2
      ? '••••'
      : '•••• ${phone.substring(phone.length - 2)}';

  Map<String, dynamic> toJson() =>
      {'name': name, 'relation': relation, 'phone': phone};

  factory TrustedContact.fromJson(Map<String, dynamic> j) => TrustedContact(
        name: j['name'] as String,
        relation: (j['relation'] ?? '') as String,
        phone: j['phone'] as String,
      );
}

class ServiceListing {
  const ServiceListing({
    required this.name,
    required this.kind,
    required this.city,
    required this.languages,
    required this.eligibility,
    this.phone,
    this.email,
    this.verified = false,
  });

  final String name;
  final String kind;
  final String city;
  final String languages;
  final String eligibility;
  final String? phone;
  final String? email;
  final bool verified;

  factory ServiceListing.fromRow(Map<String, dynamic> r) => ServiceListing(
        name: r['name'] as String,
        kind: r['kind'] as String,
        city: (r['city'] ?? '') as String,
        languages: ((r['languages'] as List?) ?? []).join(', '),
        eligibility: (r['eligibility_notes'] ?? '') as String,
        phone: r['phone'] as String?,
        email: r['email'] as String?,
        verified: (r['verified'] ?? false) as bool,
      );
}

class Opportunity {
  const Opportunity({
    required this.title,
    required this.kind,
    required this.summary,
    required this.eligibility,
    this.org = '',
    this.location = '',
    this.deadline = '',
    this.url,
    this.sample = false,
  });

  final String title;
  final String kind;
  final String summary;
  final String eligibility;
  final String org;
  final String location;
  final String deadline;
  final String? url;
  final bool sample;

  factory Opportunity.fromRow(Map<String, dynamic> r) => Opportunity(
        title: r['title'] as String,
        kind: r['kind'] as String,
        summary: (r['description'] ?? '') as String,
        eligibility: (r['eligibility'] ?? '') as String,
        deadline: (r['deadline'] ?? '').toString(),
        url: r['apply_url'] as String?,
      );
}

const kindLabels = {
  'counseling': 'Counseling',
  'legal_aid': 'Legal aid',
  'gbv_support': 'GBV support',
  'shelter': 'Shelter',
  'health': 'Health',
  'other': 'Other',
  'scholarship': 'Scholarship',
  'internship': 'Internship',
  'job': 'Job',
  'training': 'Training',
  'mentorship': 'Mentorship',
};

const statusLabels = {
  'received': 'Received',
  'under_review': 'Under review',
  'referred': 'Referred',
  'resolved': 'Resolved',
  'closed': 'Closed',
};

const sampleServices = [
  ServiceListing(
    name: 'Sample counseling service',
    kind: 'counseling',
    city: 'Addis Ababa',
    languages: 'Amharic, English',
    eligibility: 'Real listings appear here after they are verified.',
  ),
  ServiceListing(
    name: 'Sample legal-aid clinic',
    kind: 'legal_aid',
    city: 'Addis Ababa',
    languages: 'Amharic, English',
    eligibility: 'Real listings appear here after they are verified.',
  ),
  ServiceListing(
    name: 'Sample GBV support service',
    kind: 'gbv_support',
    city: 'Addis Ababa',
    languages: 'Amharic, Afaan Oromo, English',
    eligibility: 'Real listings appear here after they are verified.',
  ),
  ServiceListing(
    name: "Sample women's health service",
    kind: 'health',
    city: 'Adama',
    languages: 'Afaan Oromo, Amharic',
    eligibility: 'Real listings appear here after they are verified.',
  ),
];

const sampleOpportunities = [
  Opportunity(
    title: 'Digital Skills Fellowship',
    kind: 'training',
    org: 'Sample listing',
    location: 'Addis Ababa · Hybrid',
    deadline: 'Apply by 30 Nov 2026',
    summary:
        'A sample training listing showing how programs will appear, with clear eligibility and no application fee.',
    eligibility: 'Open to women and girls aged 18 and over.',
    sample: true,
  ),
  Opportunity(
    title: 'Women in STEM Scholarship',
    kind: 'scholarship',
    org: 'Sample listing',
    location: 'Ethiopia · Remote',
    deadline: 'Apply by 15 Dec 2026',
    summary: 'A sample scholarship listing for university students.',
    eligibility: 'Enrolled in a STEM degree program.',
    sample: true,
  ),
  Opportunity(
    title: 'Junior Analyst Internship',
    kind: 'internship',
    org: 'Sample listing',
    location: 'Addis Ababa · On site',
    deadline: 'Apply by 10 Jan 2027',
    summary: 'A sample internship listing with a fair, transparent process.',
    eligibility: 'Final-year students and recent graduates.',
    sample: true,
  ),
  Opportunity(
    title: 'Mentorship Circle',
    kind: 'mentorship',
    org: 'Sample listing',
    location: 'Online',
    deadline: 'Rolling applications',
    summary: 'A sample mentorship listing connecting women with mentors.',
    eligibility: 'Open to young women starting their careers.',
    sample: true,
  ),
];
