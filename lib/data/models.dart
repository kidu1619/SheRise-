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
  const CaseMessage(
      {required this.sender, required this.body, required this.createdAt});
  final String sender; // 'reporter' or 'staff'
  final String body;
  final DateTime createdAt;
}

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
