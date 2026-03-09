// lib/screens/notes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().currentUser?.uid;
    if (uid == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Notes 📝')),
      body: StreamBuilder<List<Note>>(
        stream: context.read<FirestoreService>().streamNotes(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final notes = snap.data ?? [];
          if (notes.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('📓', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('No notes yet!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Text('Tap + to create your first note', style: TextStyle(color: AppColors.textSecondary)),
            ]));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9),
            itemCount: notes.length,
            itemBuilder: (_, i) => _NoteCard(note: notes[i])
                .animate(delay: (i * 50).ms).fadeIn(duration: 250.ms).scale(begin: const Offset(0.95, 0.95)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, uid, null),
        backgroundColor: AppColors.blue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _openEditor(BuildContext context, String uid, Note? note) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(uid: uid, note: note)));
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({required this.note});

  static const _colors = [Color(0xFF1E2A4A), Color(0xFF1A2E1A), Color(0xFF2E1A2E), Color(0xFF2E2A1A)];

  @override
  Widget build(BuildContext context) {
    final color = _colors[note.title.length % _colors.length];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(uid: note.userId, note: note))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(note.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (note.subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note.subtitle, style: TextStyle(color: Colors.white60, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Expanded(child: Text(note.body, style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4), overflow: TextOverflow.fade)),
        ]),
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  final String uid;
  final Note? note;
  const NoteEditorScreen({super.key, required this.uid, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleCtrl, _subCtrl, _bodyCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _subCtrl = TextEditingController(text: widget.note?.subtitle ?? '');
    _bodyCtrl = TextEditingController(text: widget.note?.body ?? '');
  }

  @override
  void dispose() { _titleCtrl.dispose(); _subCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required'))); return; }
    setState(() => _loading = true);
    final fs = context.read<FirestoreService>();
    if (widget.note == null) {
      await fs.addNote(Note(id: '', userId: widget.uid, title: _titleCtrl.text.trim(), subtitle: _subCtrl.text.trim(), body: _bodyCtrl.text.trim(), updatedAt: DateTime.now().millisecondsSinceEpoch));
    } else {
      await fs.updateNote(widget.note!.id, widget.note!.copyWith(title: _titleCtrl.text.trim(), subtitle: _subCtrl.text.trim(), body: _bodyCtrl.text.trim()));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (widget.note == null) return;
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(backgroundColor: AppColors.card, title: const Text('Delete note?'), actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.rose))),
    ]));
    if (confirm == true) { await context.read<FirestoreService>().deleteNote(widget.note!.id); if (mounted) Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          if (widget.note != null) IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rose), onPressed: _delete),
          _loading
              ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 16))),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _titleCtrl, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700), decoration: InputDecoration(border: InputBorder.none, hintText: 'Note title', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 22, fontWeight: FontWeight.w700))),
          TextField(controller: _subCtrl, style: TextStyle(color: AppColors.textSecondary, fontSize: 15), decoration: InputDecoration(border: InputBorder.none, hintText: 'Subtitle (optional)', hintStyle: TextStyle(color: AppColors.textMuted))),
          const Divider(height: 24),
          Expanded(child: TextField(controller: _bodyCtrl, maxLines: null, expands: true, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6), decoration: InputDecoration(border: InputBorder.none, hintText: 'Start writing...', hintStyle: TextStyle(color: AppColors.textMuted)))),
        ]),
      ),
    );
  }
}
