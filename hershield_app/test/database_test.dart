import 'package:flutter_test/flutter_test.dart';
import 'package:hershield_app/data/app_database.dart';
import 'package:hershield_app/data/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AppDatabase initializes with seed reports and supports intake & workflows', () async {
    final db = AppDatabase.instance;
    await db.init();

    // 1. Initial seed check
    final initialReports = db.allReports;
    expect(initialReports.isNotEmpty, isTrue);
    expect(initialReports.length, greaterThanOrEqualTo(4));

    // 2. Submit a new report via mobile draft
    final draft = ReportDraft(
      category: 'Harassment',
      description: 'Incident occurred during evening tutorial session.',
      location: 'Block C, Room 102',
      anonymous: true,
      date: DateTime.now(),
    );

    final code = await db.submitReport(draft);
    expect(code.startsWith('SR-'), isTrue);

    final report = db.findByCode(code);
    expect(report, isNotNull);
    expect(report!.status, 'received');
    expect(report.category, 'Harassment');
    expect(report.priority, 'high');
    expect(report.anonymous, isTrue);

    // 3. Workflow: Update Status
    await db.updateStatus(
      code,
      'under_review',
      staffNote: 'Investigating tutor schedule.',
      messageToReporter: 'Your case is currently under active review by the committee.',
    );

    final updated = db.findByCode(code);
    expect(updated!.status, 'under_review');
    expect(updated.messages.length, greaterThanOrEqualTo(2));
    expect(updated.internalNotes.length, 1);

    // 4. Workflow: Assign Officer
    await db.assignOfficer(code, 'Officer Almaz Tadesse', 'Ethics Directorate');
    final assigned = db.findByCode(code);
    expect(assigned!.assignedOfficer, 'Officer Almaz Tadesse');

    // 5. Workflow: Reporter Message (Two-way communication)
    await db.addReporterMessage(code, 'Thank you, I can provide additional timestamps.');
    final afterReply = db.findByCode(code);
    expect(afterReply!.messages.last.sender, 'reporter');
    expect(afterReply.messages.last.body, contains('timestamps'));

    // 6. Workflow: Partner Referral
    final referral = CaseReferral(
      partnerName: 'EWLA (Ethiopian Women Lawyers Association)',
      contactPerson: 'Advocate Selamawit',
      phone: '+251 11 550 7711',
      notes: 'Legal representation for student',
      referredAt: DateTime.now(),
      status: 'in_progress',
    );
    await db.referCase(code, referral);
    final referred = db.findByCode(code);
    expect(referred!.status, 'referred');
    expect(referred.referral, isNotNull);
    expect(referred.referral!.partnerName, contains('EWLA'));

    // 7. Workflow: Formal Resolution
    final resolution = CaseResolution(
      outcome: 'Disciplinary Action & Protection Ordered',
      summary: 'Hearing held with departmental board.',
      actionTaken: 'Tutor reassigned; protective measures enacted.',
      resolvedBy: 'Officer Almaz Tadesse',
      resolvedAt: DateTime.now(),
    );
    await db.resolveCase(code, resolution);
    final resolved = db.findByCode(code);
    expect(resolved!.status, 'resolved');
    expect(resolved.resolution, isNotNull);
    expect(resolved.resolution!.outcome, contains('Disciplinary'));

    // 8. Statistics check
    final stats = db.getStatistics();
    expect(stats['total'], greaterThanOrEqualTo(5));
    expect(stats['resolved'], greaterThanOrEqualTo(2));
  });
}
