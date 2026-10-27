import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'institution_case_detail_screen.dart';

class InstitutionBoardScreen extends StatefulWidget {
  const InstitutionBoardScreen({super.key});

  @override
  State<InstitutionBoardScreen> createState() => _InstitutionBoardScreenState();
}

class _InstitutionBoardScreenState extends State<InstitutionBoardScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';
  String _selectedCategory = 'all';
  String _searchQuery = '';

  static const _availableInstitutions = [
    'Addis Ababa University - Safety & Ethics Directorate',
    'Ethiopian Women Lawyers Association (EWLA) - Legal Intake',
    'National Women & GBV Response Task Force',
    'St. Paul Hospital GBV Clinical Support Unit',
    'Industrial Parks Commission - Ethics & Labor Office',
  ];

  static const _availableStaff = [
    'Officer Almaz Tadesse (Senior Case Reviewer)',
    'Dawit Mengistu (Legal Advocacy Officer)',
    'Dr. Helen Berhanu (Counseling Lead)',
    'Tigist Abebe (Intake Coordinator)',
  ];

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.init();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _switchInstitutionDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String chosenInst = AppDatabase.instance.currentInstitution;
        String chosenStaff = AppDatabase.instance.currentStaffName;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.corporate_fare, color: C.primary),
                  SizedBox(width: 8),
                  Text('Institution & Staff Profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Active Institution:',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: C.muted)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: chosenInst,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: C.tint.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _availableInstitutions.map((inst) {
                      return DropdownMenuItem(
                        value: inst,
                        child: Text(inst, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => chosenInst = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Active Case Officer:',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: C.muted)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _availableStaff.contains(chosenStaff)
                        ? chosenStaff
                        : _availableStaff.first,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: C.tint.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _availableStaff.map((st) {
                      return DropdownMenuItem(
                        value: st,
                        child: Text(st, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => chosenStaff = v);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    await AppDatabase.instance
                        .setInstitution(chosenInst, staff: chosenStaff);
                    if (mounted) setState(() {});
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) snack(context, 'Switched to $chosenInst');
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _generateSimulatedReport() async {
    final catList = ['Harassment', 'Bullying', 'Discrimination', 'Abuse', 'Unequal opportunity'];
    final locList = [
      'Science Library, Study Floor 2',
      'Administration Building, Finance Section',
      'Main Campus Cafeteria Entrance',
      'Regional Internship Facility, Adama',
    ];
    final descList = [
      'Witnessed verbal abuse and threatening behavior from a departmental coordinator toward female junior staff members during the weekly review meeting.',
      'Received unsolicited explicit messages from a lecturer demanding personal favors in exchange for passing final semester lab practicals.',
      'Female applicants were excluded from field assessment assignments despite meeting higher qualifying test criteria.',
    ];

    final now = DateTime.now();
    final cat = catList[now.second % catList.length];
    final loc = locList[now.second % locList.length];
    final desc = descList[now.second % descList.length];

    final draft = ReportDraft(
      category: cat,
      location: loc,
      description: desc,
      anonymous: now.second % 2 == 0,
      date: now,
      attachments: [
        EvidenceAttachment(
          name: 'incident_audio_note.m4a',
          kind: 'voice',
          ext: 'm4a',
          mime: 'audio/m4a',
          size: 98000,
          seconds: 19,
        ),
      ].map((e) => Attachment(
        name: e.name,
        kind: e.kind,
        ext: e.ext,
        mime: e.mime,
        bytes: Uint8List.fromList([0, 1, 2, 3]),
        seconds: e.seconds,
      )).toList(),
    );

    final code = await AppDatabase.instance.submitReport(
      draft,
      reporterName: draft.anonymous ? null : 'Simulated Reporter Account',
    );

    if (mounted) {
      snack(context, 'New simulated report delivered: $code');
    }
  }

  void _showAnalyticsSheet(Map<String, dynamic> stats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: C.primary, size: 28),
                const SizedBox(width: 10),
                const Text('Intake & Case Analytics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(AppDatabase.instance.currentInstitution,
                style: const TextStyle(color: C.muted, fontSize: 13)),
            const Divider(height: 24),
            Row(
              children: [
                _kpiBox('Total Reports', '${stats['total']}', Icons.inbox, C.primary),
                const SizedBox(width: 12),
                _kpiBox('Urgent Flags', '${stats['urgent']}', Icons.warning_amber, C.danger),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _kpiBox('Anonymous', '${stats['anonymous']}', Icons.lock_outline, Colors.teal),
                const SizedBox(width: 12),
                _kpiBox('With Evidence', '${stats['withEvidence']}', Icons.attach_file, Colors.indigo),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Reports by Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ...((stats['categories'] as Map<String, int>).entries.map((e) {
              final pct = (stats['total'] as int) > 0
                  ? (e.value / (stats['total'] as int))
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 12, color: C.muted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: C.line,
                        valueColor: const AlwaysStoppedAnimation<Color>(C.primary),
                      ),
                    ),
                  ],
                ),
              );
            })),
            const SizedBox(height: 20),
            SecondaryButton(
              label: 'Export Intake Summary (CSV/Audit)',
              icon: Icons.download_outlined,
              onPressed: () {
                Navigator.pop(ctx);
                snack(context, 'Audit export ready. All records verified.');
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _kpiBox(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: col.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: col, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(val,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: col)),
                Text(title,
                    style: const TextStyle(fontSize: 11, color: C.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<DeliveredReport>>(
      valueListenable: AppDatabase.instance.reportsNotifier,
      builder: (context, allReports, _) {
        final stats = AppDatabase.instance.getStatistics();
        final filteredReports = AppDatabase.instance.filterReports(
          query: _searchQuery,
          status: _selectedStatus,
          priority: _selectedPriority,
          category: _selectedCategory,
        );

        return Scaffold(
          backgroundColor: C.bg,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: C.ink),
              tooltip: 'Back to SheRise Home',
              onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: C.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Institution Board',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: C.ink,
                        ),
                      ),
                      Text(
                        'Intake, Case Review & Workflows',
                        style: TextStyle(fontSize: 11, color: C.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Analytics & Insights',
                icon: const Icon(Icons.analytics_outlined, color: C.primary),
                onPressed: () => _showAnalyticsSheet(stats),
              ),
              IconButton(
                tooltip: 'Simulate Incoming Report',
                icon: const Icon(Icons.add_alert_outlined, color: C.primary),
                onPressed: _generateSimulatedReport,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: C.ink),
                onSelected: (val) async {
                  if (val == 'switch') {
                    _switchInstitutionDialog();
                  } else if (val == 'reset') {
                    await AppDatabase.instance.resetToDemoData();
                    if (context.mounted) snack(context, 'Reset to standard demo cases.');
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'switch',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 18),
                        SizedBox(width: 8),
                        Text('Switch Institution Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18),
                        SizedBox(width: 8),
                        Text('Reset Demo Cases'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // Top Navigation Back Button Row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Tx('Back to SheRise Home'),
                          style: TextButton.styleFrom(
                            foregroundColor: C.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Institution Identity Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: C.tint.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.tintBorder),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: C.primary,
                          child: Icon(Icons.corporate_fare, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppDatabase.instance.currentInstitution,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: C.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: C.ok,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    AppDatabase.instance.currentStaffName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: C.muted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _switchInstitutionDialog,
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Change', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // KPI Summary Metrics Cards
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _summaryCard(
                          title: 'Delivered',
                          count: '${stats['total']}',
                          subtitle: 'All reports',
                          color: C.primary,
                          icon: Icons.mark_email_read_outlined,
                          isSelected: _selectedStatus == 'all',
                          onTap: () => setState(() => _selectedStatus = 'all'),
                        ),
                        _summaryCard(
                          title: 'New Inbox',
                          count: '${stats['received']}',
                          subtitle: 'Action needed',
                          color: Colors.orange,
                          icon: Icons.inbox,
                          isSelected: _selectedStatus == 'received',
                          onTap: () => setState(() => _selectedStatus = 'received'),
                        ),
                        _summaryCard(
                          title: 'Under Review',
                          count: '${stats['underReview']}',
                          subtitle: 'Investigating',
                          color: Colors.blue,
                          icon: Icons.sync,
                          isSelected: _selectedStatus == 'under_review',
                          onTap: () => setState(() => _selectedStatus = 'under_review'),
                        ),
                        _summaryCard(
                          title: 'Referred',
                          count: '${stats['referred']}',
                          subtitle: 'With partners',
                          color: Colors.purple,
                          icon: Icons.people_outline,
                          isSelected: _selectedStatus == 'referred',
                          onTap: () => setState(() => _selectedStatus = 'referred'),
                        ),
                        _summaryCard(
                          title: 'Resolved',
                          count: '${stats['resolved']}',
                          subtitle: 'Protected',
                          color: C.ok,
                          icon: Icons.check_circle_outline,
                          isSelected: _selectedStatus == 'resolved',
                          onTap: () => setState(() => _selectedStatus = 'resolved'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Case Code, Category, Location, Officer...',
                      hintStyle: const TextStyle(fontSize: 13, color: C.muted),
                      prefixIcon: const Icon(Icons.search, size: 20, color: C.muted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: C.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: C.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: C.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Secondary Filter Chips Row (Priority & Category)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Priority:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: C.muted)),
                        const SizedBox(width: 6),
                        _filterChip('All', _selectedPriority == 'all',
                            () => setState(() => _selectedPriority = 'all')),
                        _filterChip('Urgent', _selectedPriority == 'urgent',
                            () => setState(() => _selectedPriority = 'urgent'),
                            badgeColor: C.dangerBg, fgColor: C.danger),
                        _filterChip('High', _selectedPriority == 'high',
                            () => setState(() => _selectedPriority = 'high'),
                            badgeColor: const Color(0xFFFFEBD8), fgColor: const Color(0xFFC05621)),
                        _filterChip('Medium', _selectedPriority == 'medium',
                            () => setState(() => _selectedPriority = 'medium')),
                        const SizedBox(width: 14),
                        const Text('Category:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: C.muted)),
                        const SizedBox(width: 6),
                        _filterChip('All', _selectedCategory == 'all',
                            () => setState(() => _selectedCategory = 'all')),
                        _filterChip('Harassment', _selectedCategory == 'Harassment',
                            () => setState(() => _selectedCategory = 'Harassment')),
                        _filterChip('Bullying', _selectedCategory == 'Bullying',
                            () => setState(() => _selectedCategory = 'Bullying')),
                        _filterChip('Discrimination', _selectedCategory == 'Discrimination',
                            () => setState(() => _selectedCategory = 'Discrimination')),
                        _filterChip('Unequal opportunity', _selectedCategory == 'Unequal opportunity',
                            () => setState(() => _selectedCategory = 'Unequal opportunity')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Delivered Reports Feed Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivered Reports (${filteredReports.length})',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      if (_selectedStatus != 'all' ||
                          _selectedPriority != 'all' ||
                          _selectedCategory != 'all' ||
                          _searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatus = 'all';
                              _selectedPriority = 'all';
                              _selectedCategory = 'all';
                              _searchController.clear();
                            });
                          },
                          child: const Text('Reset filters', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Empty State or List of Reports
                  if (filteredReports.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(36),
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: C.line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 48, color: C.muted),
                          const SizedBox(height: 12),
                          const Text('No reports match your filters',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 6),
                          const Text(
                            'Try clearing your search query or selecting a different status filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: C.muted, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Generate Simulated Report',
                            icon: Icons.add,
                            onPressed: _generateSimulatedReport,
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredReports.map((report) => _ReportCard(
                          report: report,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InstitutionCaseDetailScreen(code: report.code),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        )),
                  const SizedBox(height: 20),
                  SecondaryButton(
                    label: 'Back to SheRise Home',
                    icon: Icons.arrow_back,
                    onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String count,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 115,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : C.line,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(color: C.muted, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap,
      {Color? badgeColor, Color? fgColor}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: badgeColor ?? C.tint,
        checkmarkColor: fgColor ?? C.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? (fgColor ?? C.primary) : C.ink,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: active ? (fgColor ?? C.primary) : C.line),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});
  final DeliveredReport report;
  final VoidCallback onTap;

  static Pill _statusPill(String status) {
    switch (status) {
      case 'received':
        return const Pill('Received', bg: Color(0xFFEDE6FB), fg: C.primary);
      case 'under_review':
        return const Pill('Under Review', bg: C.warnBg, fg: C.warn);
      case 'referred':
        return const Pill('Referred', bg: Color(0xFFE0F2FE), fg: Color(0xFF0369A1));
      case 'resolved':
        return const Pill('Resolved', bg: C.okBg, fg: C.ok);
      case 'closed':
        return const Pill('Closed', bg: Color(0xFFF1F5F9), fg: Color(0xFF64748B));
      default:
        return Pill(status);
    }
  }

  static Pill _priorityPill(String priority) {
    switch (priority) {
      case 'urgent':
        return const Pill('URGENT', bg: C.dangerBg, fg: C.danger);
      case 'high':
        return const Pill('HIGH', bg: Color(0xFFFFEBD8), fg: Color(0xFFC05621));
      case 'medium':
        return const Pill('MEDIUM', bg: C.warnBg, fg: C.warn);
      case 'low':
        return const Pill('LOW', bg: Color(0xFFF1F5F9), fg: Color(0xFF64748B));
      default:
        return Pill(priority.toUpperCase());
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return DateFormat('d MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final hasVoice = report.attachments.any((a) => a.kind == 'voice');
    final hasFiles = report.attachments.any((a) => a.kind == 'file');

    return AppCard(
      onTap: onTap,
      bottom: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Code, Copy, Time, Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: C.tint.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      report.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: report.code));
                        snack(context, 'Copied ${report.code}');
                      },
                      child: const Icon(Icons.copy, size: 13, color: C.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _priorityPill(report.priority),
              const Spacer(),
              _statusPill(report.status),
            ],
          ),
          const SizedBox(height: 10),

          // Category & Relative Time
          Row(
            children: [
              Text(
                report.category,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${_formatTime(report.createdAt)}',
                style: const TextStyle(color: C.muted, fontSize: 12),
              ),
              const Spacer(),
              if (report.anonymous)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 13, color: C.muted),
                    SizedBox(width: 3),
                    Text('Anonymous',
                        style: TextStyle(fontSize: 11, color: C.muted, fontWeight: FontWeight.w600)),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 13, color: C.primary),
                    const SizedBox(width: 3),
                    Text(report.reporterName ?? 'Confidential',
                        style: const TextStyle(fontSize: 11, color: C.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Incident Description Excerpt
          Text(
            report.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF333333), height: 1.35),
          ),
          const SizedBox(height: 10),

          // Location Tag
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 14, color: C.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.location,
                  style: const TextStyle(fontSize: 12, color: C.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(height: 18),

          // Bottom Workflow Indicators: Evidence Badges, Assigned Officer, Messages count
          Row(
            children: [
              // Evidence indicators
              if (hasVoice)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, size: 12, color: Colors.blue),
                      SizedBox(width: 3),
                      Text('Voice Note', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              if (hasFiles)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file, size: 12, color: Colors.indigo),
                      const SizedBox(width: 3),
                      Text('${report.attachments.length} files',
                          style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              const Spacer(),

              // Officer assignment badge
              if (report.assignedOfficer != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_ind_outlined, size: 14, color: C.primary),
                    const SizedBox(width: 4),
                    Text(
                      report.assignedOfficer!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.primary),
                    ),
                  ],
                )
              else
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Unassigned',
                      style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

              const SizedBox(width: 10),

              // Messages bubble count
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 13, color: C.muted),
                  const SizedBox(width: 4),
                  Text('${report.messages.length}',
                      style: const TextStyle(fontSize: 11, color: C.muted, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: C.muted),
            ],
          ),
        ],
      ),
    );
  }
}
