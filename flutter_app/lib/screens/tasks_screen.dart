// lib/screens/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/assignment.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_ai_sheet.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().currentUser?.uid;
    if (uid == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assignments 📚'),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAddSheet(context, uid)),
        ],
      ),
      body: StreamBuilder<List<Assignment>>(
        stream: context.read<FirestoreService>().streamAssignments(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tasks = snap.data ?? [];
          if (tasks.isEmpty) {
            return _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: tasks.length,
            itemBuilder: (context, i) {
              return _AssignmentCard(task: tasks[i])
                  .animate(delay: (i * 60).ms)
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05, end: 0);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, uid),
        backgroundColor: AppColors.blue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddSheet(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _AddAssignmentSheet(uid: uid),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment task;
  const _AssignmentCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: task.isCompleted ? AppColors.emerald : AppColors.blue, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => fs.toggleAssignment(task.id, task.isCompleted),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted ? AppColors.emerald : Colors.transparent,
                      border: Border.all(color: task.isCompleted ? AppColors.emerald : AppColors.textMuted, width: 2),
                    ),
                    child: task.isCompleted
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & course
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: task.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${task.course} · Due ${task.dueDate}',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: const Text('Delete task?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.rose))),
                        ],
                      ),
                    );
                    if (confirm == true) fs.deleteAssignment(task.id);
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // AI Help button
            if (!task.isCompleted)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                    builder: (_) => TaskAiSheet(task: task),
                  ),
                  icon: const Icon(Icons.smart_toy_rounded, size: 16, color: AppColors.violet),
                  label: const Text('AI Help', style: TextStyle(color: AppColors.violet, fontWeight: FontWeight.w700, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.violet.withOpacity(0.4)),
                    backgroundColor: AppColors.violet.withOpacity(0.06),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📚', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          const Text('No assignments yet!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Tap + to add your first task', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _AddAssignmentSheet extends StatefulWidget {
  final String uid;
  const _AddAssignmentSheet({required this.uid});

  @override
  State<_AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends State<_AddAssignmentSheet> {
  final _titleCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  DateTime? _dueDate;
  int _alertDays = 0;
  bool _loading = false;

  @override
  void dispose() { _titleCtrl.dispose(); _courseCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _courseCtrl.text.trim().isEmpty || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and pick a due date.')));
      return;
    }
    setState(() => _loading = true);
    final a = Assignment(
      id: '',
      userId: widget.uid,
      title: _titleCtrl.text.trim(),
      course: _courseCtrl.text.trim(),
      dueDate: '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2,'0')}-${_dueDate!.day.toString().padLeft(2,'0')}',
      alertOffset: _alertDays,
    );
    await context.read<FirestoreService>().addAssignment(a);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Assignment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 20),
          TextField(controller: _titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Assignment title')),
          const SizedBox(height: 12),
          TextField(controller: _courseCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Course code (e.g. TMG 101)')),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 3)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => _dueDate = d);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Text(_dueDate == null ? 'Select due date' : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}', style: TextStyle(color: _dueDate == null ? AppColors.textMuted : AppColors.textPrimary)),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Add Assignment'))),
        ],
      ),
    );
  }
}
