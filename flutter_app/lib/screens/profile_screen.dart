// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Profile'), actions: [
        IconButton(icon: const Icon(Icons.logout_rounded, color: AppColors.rose), onPressed: () async {
          final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(backgroundColor: AppColors.card, title: const Text('Log out?'), actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out', style: TextStyle(color: AppColors.rose))),
          ]));
          if (confirm == true) { await auth.signOut(); if (context.mounted) context.go('/login'); }
        }),
      ]),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.blue, const Color(0xFF6366F1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.blue.withOpacity(0.3), blurRadius: 20)],
                    ),
                    child: user.profilePic != null
                        ? ClipOval(child: Image.network(user.profilePic!, fit: BoxFit.cover))
                        : Center(child: Text((user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A'), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(height: 14),
                  Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text(user.email, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.amber.withOpacity(0.3))),
                    child: Text(user.userRank, style: const TextStyle(color: AppColors.amber, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 28),

                  // Stats row
                  Row(children: [
                    _StatTile(value: '${user.weeklyXp}', label: 'Weekly XP', color: AppColors.blue),
                    const SizedBox(width: 12),
                    _StatTile(value: '${user.streak}', label: 'Day Streak', color: AppColors.orange),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _StatTile(value: user.program, label: 'Programme', color: AppColors.violet),
                    const SizedBox(width: 12),
                    _StatTile(value: user.school, label: 'School', color: AppColors.emerald),
                  ]),
                  const SizedBox(height: 28),

                  // Info tiles
                  _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user.phone),
                  const SizedBox(height: 10),
                  _InfoTile(icon: Icons.school_outlined, label: 'School', value: user.school),
                  const SizedBox(height: 10),
                  _InfoTile(icon: Icons.book_outlined, label: 'Programme', value: user.program),
                ],
              ),
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          Text(value.isNotEmpty ? value : '—', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}
