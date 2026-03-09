// lib/screens/timetable_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/course.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _dayShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int _selectedDay = DateTime.now().weekday - 1; // 0 = Monday

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().currentUser?.uid;
    if (uid == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Timetable 📅'), actions: [
        IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAddSheet(context, uid)),
      ]),
      body: Column(
        children: [
          // Day selector
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: List.generate(7, (i) {
                final sel = i == _selectedDay;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_dayShort[i], textAlign: TextAlign.center, style: TextStyle(color: sel ? Colors.white : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Courses for selected day
          Expanded(
            child: StreamBuilder<List<Course>>(
              stream: context.read<FirestoreService>().streamCourses(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final all = snap.data ?? [];
                final filtered = all.where((c) => c.day == _days[_selectedDay]).toList()
                  ..sort((a, b) => a.time.compareTo(b.time));
                if (filtered.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🎉', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('No classes on ${_days[_selectedDay]}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('Enjoy your free time!', style: TextStyle(color: AppColors.textSecondary)),
                  ]));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _CourseCard(course: filtered[i])
                      .animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, uid),
        backgroundColor: AppColors.blue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddSheet(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _AddCourseSheet(uid: uid),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: const Border(left: BorderSide(color: AppColors.blue, width: 4)),
      ),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.school_rounded, color: AppColors.blue, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(course.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(course.venue, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(width: 12),
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(course.time, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ]),
          ])),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
            onPressed: () => context.read<FirestoreService>().deleteCourse(course.id),
          ),
        ],
      ),
    );
  }
}

class _AddCourseSheet extends StatefulWidget {
  final String uid;
  const _AddCourseSheet({required this.uid});
  @override
  State<_AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends State<_AddCourseSheet> {
  final _nameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  String _day = 'Monday';
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _loading = false;

  @override
  void dispose() { _nameCtrl.dispose(); _venueCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _venueCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    await context.read<FirestoreService>().addCourse(Course(
      id: '', userId: widget.uid, name: _nameCtrl.text.trim(), venue: _venueCtrl.text.trim(),
      day: _day, time: '${_time.hour.toString().padLeft(2,'0')}:${_time.minute.toString().padLeft(2,'0')}',
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Add Class', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 20),
        TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Course code (e.g. TMG 101)')),
        const SizedBox(height: 12),
        TextField(controller: _venueCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Venue (e.g. CALC 1)')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: _day,
            dropdownColor: AppColors.card,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(labelText: 'Day'),
            items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _day = v!),
          )),
          const SizedBox(width: 12),
          Expanded(child: InkWell(
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _time);
              if (t != null) setState(() => _time = t);
            },
            child: InputDecorator(decoration: const InputDecoration(labelText: 'Time'), child: Text('${_time.hour.toString().padLeft(2,'0')}:${_time.minute.toString().padLeft(2,'0')}', style: const TextStyle(color: Colors.white, fontSize: 14))),
          )),
        ]),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Add Class'))),
      ]),
    );
  }
}
