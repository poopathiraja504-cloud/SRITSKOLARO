import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/student_avatar.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, String> _attendance = {};
  String _identity = '';
  String? _error;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final identity = '${auth.currentApp?.name}:${auth.currentUser?.uid}';
    if (identity != _identity) {
      _identity = identity;
      _loadAttendance();
    }
  }

  Future<void> _loadAttendance() async {
    final auth = context.read<AuthProvider>();
    final app = auth.currentApp;
    final user = auth.currentUser;
    if (app == null || user == null) return;
    final identity = '${app.name}:${user.uid}';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instanceFor(app: app)
          .collection('users')
          .doc(user.uid)
          .collection('attendance')
          .get();
      final records = <String, String>{};
      for (final item in snapshot.docs) {
        final data = item.data();
        final dateValue = data['date'];
        final date = dateValue is Timestamp
            ? dateValue.toDate()
            : DateTime.tryParse('$dateValue');
        final status = data['status'];
        if (date != null && status is String) {
          records[_key(date)] = status.toLowerCase();
        }
      }
      if (mounted && identity == _identity) {
        setState(() {
          _attendance = records;
          _loading = false;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Could not load attendance: $error\n$stackTrace');
      if (mounted && identity == _identity) {
        setState(() {
          _error = 'Attendance records could not be loaded.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final user = auth.currentUser!;
    final name = profile?.name ?? user.displayName ?? user.email?.split('@').first ?? 'Student';
    final photo = profile?.profilePhoto ?? user.photoURL;
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final startOffset = (DateTime(_month.year, _month.month, 1).weekday + 6) % 7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        leading: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Card(
                  child: ListTile(
                    leading: StudentAvatar(name: name, photoUrl: photo, size: 68),
                    title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(profile?.studentId.isNotEmpty == true ? profile!.studentId : user.email ?? ''),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              tooltip: 'Previous month',
                              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                              MaterialLocalizations.of(context).formatMonthYear(_month),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            IconButton(
                              tooltip: 'Next month',
                              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                              .map((day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: const TextStyle(
                                          color: AppTheme.secondaryText,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: startOffset + daysInMonth,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          itemBuilder: (context, index) {
                            if (index < startOffset) return const SizedBox.shrink();
                            final day = index - startOffset + 1;
                            final date = DateTime(_month.year, _month.month, day);
                            final status = _attendance[_key(date)];
                            final today = DateUtils.isSameDay(date, DateTime.now());
                            final color = _statusColor(status);
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: color?.withValues(alpha: .22),
                                shape: BoxShape.circle,
                                border: today ? Border.all(color: AppTheme.navy, width: 2) : null,
                              ),
                              child: Center(
                                child: Text('$day', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _AttendanceLegend('Present', Color(0xFF12A96A)),
                    _AttendanceLegend('Absent', Color(0xFFE61D3D)),
                    _AttendanceLegend('Leave', Color(0xFFF4AD00)),
                    _AttendanceLegend('Excused', Color(0xFF9D45B2)),
                    _AttendanceLegend('Suspended', Color(0xFF20A8CF)),
                    _AttendanceLegend('Office Duty', Color(0xFFDA1789)),
                    _AttendanceLegend('Holiday', Color(0xFF0781C6)),
                  ],
                ),
              ],
            ),
    );
  }

  static String _key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Color? _statusColor(String? status) {
    if (status == null) return null;
    if (status.contains('present')) return const Color(0xFF12A96A);
    if (status.contains('absent')) return const Color(0xFFE61D3D);
    if (status.contains('leave')) return const Color(0xFFF4AD00);
    if (status.contains('excused')) return const Color(0xFF9D45B2);
    if (status.contains('holiday')) return const Color(0xFF0781C6);
    if (status.contains('suspended')) return const Color(0xFF20A8CF);
    if (status.contains('office')) return const Color(0xFFDA1789);
    return AppTheme.secondaryText;
  }
}

class _AttendanceLegend extends StatelessWidget {
  const _AttendanceLegend(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(radius: 5, backgroundColor: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: .14),
      side: BorderSide.none,
    );
  }
}
