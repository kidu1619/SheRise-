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
    this.latitude,
    this.longitude,
    this.institution,
    this.description = '',
    this.anonymous = true,
    this.attachments = const [],
  });

  final String? category;
  final DateTime? date;
  final String location;
  final double? latitude;
  final double? longitude;
  final Institution? institution; // where the report is sent
  final String description;
  final bool anonymous;
  final List<Attachment> attachments;

  ReportDraft copyWith({
    String? category,
    DateTime? date,
    String? location,
    double? latitude,
    double? longitude,
    Institution? institution,
    bool clearInstitution = false,
    String? description,
    bool? anonymous,
    List<Attachment>? attachments,
  }) =>
      ReportDraft(
        category: category ?? this.category,
        date: date ?? this.date,
        location: location ?? this.location,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        institution: clearInstitution ? null : (institution ?? this.institution),
        description: description ?? this.description,
        anonymous: anonymous ?? this.anonymous,
        attachments: attachments ?? this.attachments,
      );

  bool get isEmpty =>
      category == null &&
      description.isEmpty &&
      location.isEmpty &&
      latitude == null &&
      institution == null &&
      attachments.isEmpty;
}

class CaseRecord {
  const CaseRecord({
    required this.code,
    required this.category,
    required this.createdAt,
    required this.status,
    this.institutionName,
  });

  final String code;
  final String category;
  final DateTime createdAt;
  final String status;
  final String? institutionName;

  Map<String, dynamic> toJson() => {
        'code': code,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        if (institutionName != null) 'institutionName': institutionName,
      };

  factory CaseRecord.fromJson(Map<String, dynamic> j) => CaseRecord(
        code: j['code'] as String,
        category: j['category'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: j['status'] as String,
        institutionName: j['institutionName'] as String?,
      );
}

class CaseStatus {
  const CaseStatus({
    required this.status,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.institutionName,
  });
  final String status;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? institutionName;
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
    this.url,
    this.verified = false,
  });

  final String name;
  final String kind;
  final String city;
  final String languages;
  final String eligibility;
  final String? phone;
  final String? email;
  /// Website URL for this service (optional).
  final String? url;
  final bool verified;

  factory ServiceListing.fromRow(Map<String, dynamic> r) => ServiceListing(
        name: r['name'] as String,
        kind: r['kind'] as String,
        city: (r['city'] ?? '') as String,
        languages: ((r['languages'] as List?) ?? []).join(', '),
        eligibility: (r['eligibility_notes'] ?? '') as String,
        phone: r['phone'] as String?,
        email: r['email'] as String?,
        url: r['url'] as String?,
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
    this.postedAt,
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
  /// When the opportunity was posted (optional).
  final DateTime? postedAt;

  factory Opportunity.fromRow(Map<String, dynamic> r) => Opportunity(
        title: r['title'] as String,
        kind: r['kind'] as String,
        summary: (r['description'] ?? '') as String,
        eligibility: (r['eligibility'] ?? '') as String,
        deadline: (r['deadline'] ?? '').toString(),
        url: r['apply_url'] as String?,
        postedAt: r['posted_at'] != null
            ? DateTime.tryParse(r['posted_at'].toString())
            : null,
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
  // ── Real Ethiopian organizations ──────────────────────────────────────────
  ServiceListing(
    name: 'Ethiopian Women Lawyers Association (EWLA)',
    kind: 'legal_aid',
    city: 'Addis Ababa',
    languages: 'Amharic, English',
    eligibility: 'Free legal aid for women and girls in Ethiopia.',
    phone: '011-551-7804',
    url: 'https://www.ewla-eth.org',
    verified: true,
  ),
  ServiceListing(
    name: 'Addis Ababa Rape Crisis Center',
    kind: 'gbv_support',
    city: 'Addis Ababa',
    languages: 'Amharic, English',
    eligibility: 'Support and counseling for GBV survivors.',
    phone: '011-553-5657',
    verified: true,
  ),
  ServiceListing(
    name: 'ActionAid Ethiopia (ACSO)',
    kind: 'gbv_support',
    city: 'Addis Ababa',
    languages: 'Amharic, English',
    eligibility: 'Programs for women and girls affected by poverty and violence.',
    email: 'aae@actionaid.org',
    verified: true,
  ),
  ServiceListing(
    name: "Black Lion Hospital – Women's Clinic",
    kind: 'health',
    city: 'Addis Ababa',
    languages: 'Amharic, English',
    eligibility: 'Medical care and referral services for women.',
    phone: '011-123-4567',
    verified: true,
  ),
  ServiceListing(
    name: 'Rehabilitation Center for Women',
    kind: 'shelter',
    city: 'Addis Ababa',
    languages: 'Amharic, English',
    eligibility: 'Shelter, counseling and reintegration support for women.',
    phone: '011-126-5678',
    verified: true,
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
  // ── Real / AI-curated opportunities ─────────────────────────────────────
  Opportunity(
    title: 'African Women in Technology Scholarship',
    kind: 'scholarship',
    org: 'AWIT Africa',
    location: 'Africa · Remote',
    deadline: 'Check website for current cycle',
    summary:
        'AWIT supports African women pursuing technology education and careers through scholarships, mentorship and a pan-African network.',
    eligibility: 'African women in technology-related degree or diploma programs.',
    url: 'https://www.awit.africa',
  ),
  Opportunity(
    title: 'Generation Ethiopia Skills Program',
    kind: 'training',
    org: 'Generation',
    location: 'Addis Ababa · Hybrid',
    deadline: 'Rolling admissions',
    summary:
        'Generation Ethiopia offers intensive, employer-linked training programs in customer service, coding and other in-demand sectors — at no cost to participants.',
    eligibility: 'Young women and men aged 18-35 who are unemployed or underemployed.',
    url: 'https://www.generation.org',
  ),
  Opportunity(
    title: 'Tony Elumelu Foundation Entrepreneurship Programme',
    kind: 'mentorship',
    org: 'Tony Elumelu Foundation',
    location: 'Africa · Remote',
    deadline: 'Apply by 31 Jan each year',
    summary:
        'TEEP provides \$5,000 seed capital, 12 weeks of business training and lifelong mentorship to African entrepreneurs.',
    eligibility: 'African entrepreneurs with a business idea or early-stage business.',
    url: 'https://www.tonyelumelufoundation.org/teep',
  ),
  Opportunity(
    title: 'Mastercard Foundation Scholars Program',
    kind: 'scholarship',
    org: 'Mastercard Foundation',
    location: 'Africa · University placements',
    deadline: 'Varies by partner university',
    summary:
        'Full scholarships for academically talented but financially disadvantaged young Africans to study at leading universities.',
    eligibility: 'Academically strong students with demonstrated financial need.',
    url: 'https://mastercardfdn.org/all/scholars',
  ),
  Opportunity(
    title: 'She Leads Africa Accelerator',
    kind: 'mentorship',
    org: 'She Leads Africa',
    location: 'Africa · Remote / Hybrid',
    deadline: 'Check website for open cohorts',
    summary:
        'She Leads Africa connects ambitious African women entrepreneurs with world-class mentors, investors and a curated business accelerator curriculum.',
    eligibility: 'African women entrepreneurs with an existing business.',
    url: 'https://sheleadsafrica.org',
  ),
  Opportunity(
    title: 'UN Women – Opportunities for Women',
    kind: 'job',
    org: 'UN Women',
    location: 'Ethiopia & Global · Various',
    deadline: 'Rolling – see website',
    summary:
        'UN Women regularly posts jobs, consultancies, fellowships and calls-for-proposals focusing on gender equality and women\'s empowerment across Ethiopia and beyond.',
    eligibility: 'Varies by position — check individual postings.',
    url: 'https://www.unwomen.org',
  ),
  Opportunity(
    title: 'Amref Health Africa Training & Fellowships',
    kind: 'training',
    org: 'Amref Health Africa',
    location: 'Ethiopia · Addis Ababa / Remote',
    deadline: 'Varies by program',
    summary:
        'Amref offers health-focused training programs, fellowships and community health worker courses to build capacity for African women in healthcare.',
    eligibility: 'Health workers, students and community volunteers.',
    url: 'https://amref.org',
  ),
  Opportunity(
    title: 'USAID Women in Science Fellowship',
    kind: 'internship',
    org: 'USAID',
    location: 'Ethiopia & Global · Various',
    deadline: 'Check USAID website for open cycles',
    summary:
        'USAID funds fellowships and internships that support women in science, technology, engineering and mathematics across developing countries.',
    eligibility: 'Women pursuing STEM degrees or early-career professionals.',
    url: 'https://www.usaid.gov',
  ),
];

// ------------------------------------------------------------ institutions
/// A school, university, workplace, clinic, NGO ... that can receive reports.
class Institution {
  const Institution({
    required this.id,
    required this.name,
    required this.kind,
    this.city = '',
    this.region = '',
  });

  final String id;
  final String name;
  final String kind;
  final String city;
  final String region;

  String get subtitle {
    final place = [city, region].where((x) => x.isNotEmpty).join(', ');
    final k = institutionKinds[kind] ?? kind;
    return place.isEmpty ? k : '$k · $place';
  }

  factory Institution.fromRow(Map<String, dynamic> r) => Institution(
        id: r['id'].toString(),
        name: r['name'] as String,
        kind: (r['kind'] ?? 'other') as String,
        city: (r['city'] ?? '') as String,
        region: (r['region'] ?? '') as String,
      );
}

const institutionKinds = {
  'university': 'University',
  'school': 'School',
  'workplace': 'Workplace',
  'health': 'Health facility',
  'ngo': 'NGO',
  'government': 'Government office',
  'community': 'Community',
  'other': 'Other',
};

const categoryLabels = {
  'harassment': 'Harassment',
  'bullying': 'Bullying',
  'discrimination': 'Discrimination',
  'abuse': 'Abuse',
  'disrespect': 'Disrespect',
  'workplace_inequality': 'Unequal opportunity',
  'other': 'Other',
};

/// What the signed-in person may do on the institution board.
class StaffAccess {
  const StaffAccess({this.isAdmin = false, this.institutions = const []});
  final bool isAdmin;
  final List<Institution> institutions;
  bool get isStaff => isAdmin || institutions.isNotEmpty;
}

/// A report as an institution reviewer sees it. Never contains who sent it.
class StaffReport {
  const StaffReport({
    required this.id,
    required this.caseNo,
    required this.category,
    required this.status,
    required this.anonymous,
    required this.createdAt,
    required this.updatedAt,
    this.incidentDate,
    this.locationText = '',
    this.latitude,
    this.longitude,
    this.hasGps = false,
    this.snippet = '',
    this.description = '',
    this.institutionName,
    this.evidenceCount = 0,
  });

  final String id;
  final int caseNo;
  final String category;
  final String status;
  final bool anonymous;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? incidentDate;
  final String locationText;
  final double? latitude;
  final double? longitude;
  final bool hasGps;
  final String snippet;
  final String description;
  final String? institutionName;
  final int evidenceCount;

  String get label => 'SR-${caseNo.toString().padLeft(5, '0')}';
  String get categoryLabel => categoryLabels[category] ?? category;

  factory StaffReport.fromRow(Map<String, dynamic> r) {
    final lat = (r['latitude'] as num?)?.toDouble();
    final lng = (r['longitude'] as num?)?.toDouble();
    final d = r['incident_date'];
    return StaffReport(
      id: r['id'].toString(),
      caseNo: (r['case_no'] as num).toInt(),
      category: r['category'] as String,
      status: r['status'] as String,
      anonymous: (r['anonymous'] ?? true) as bool,
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
      incidentDate: d == null ? null : DateTime.parse(d as String),
      locationText: (r['location_text'] ?? '') as String,
      latitude: lat,
      longitude: lng,
      hasGps: (r['has_gps'] as bool?) ?? (lat != null),
      snippet: (r['snippet'] ?? '') as String,
      description: (r['description'] ?? '') as String,
      institutionName: r['institution_name'] as String?,
      evidenceCount: ((r['evidence_count'] ?? 0) as num).toInt(),
    );
  }
}

class EvidenceItem {
  const EvidenceItem({required this.url, required this.mime});
  final String url; // short-lived signed link
  final String mime;
  bool get isImage => mime.startsWith('image/');
  bool get isAudio => mime.startsWith('audio/');
}

const sampleInstitutions = [
  Institution(
      id: 'demo-university',
      name: 'Sample University (demo)',
      kind: 'university',
      city: 'Addis Ababa'),
  Institution(
      id: 'demo-school',
      name: 'Sample Secondary School (demo)',
      kind: 'school',
      city: 'Adama'),
  Institution(
      id: 'demo-workplace',
      name: 'Sample Employer (demo)',
      kind: 'workplace',
      city: 'Addis Ababa'),
];

final sampleStaffReports = [
  StaffReport(
    id: 'demo-report-1',
    caseNo: 1042,
    category: 'harassment',
    status: 'received',
    anonymous: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    incidentDate: DateTime.now().subtract(const Duration(days: 4)),
    locationText: 'Main Campus Library, Addis Ababa',
    snippet: 'Unwelcome behavior and repeated comments occurred near the study hall.',
    description: 'Unwelcome behavior and repeated comments occurred near the study hall. Requesting guidance on campus safety protocol.',
    institutionName: 'Sample University (demo)',
    evidenceCount: 1,
  ),
  StaffReport(
    id: 'demo-report-2',
    caseNo: 1039,
    category: 'workplace_inequality',
    status: 'under_review',
    anonymous: false,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 18)),
    incidentDate: DateTime.now().subtract(const Duration(days: 10)),
    locationText: 'Headquarters, Addis Ababa',
    snippet: 'Denied promotion opportunity despite meeting all criteria; treated differently than male peers.',
    description: 'Denied promotion opportunity despite meeting all criteria; treated differently than male peers. Seeking support from HR and management review.',
    institutionName: 'Sample Employer (demo)',
    evidenceCount: 0,
  ),
];

