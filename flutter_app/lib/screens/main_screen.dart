// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class MainScreen extends StatelessWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  static const _tabs = ['/home', '/timetable', '/tasks', '/notes', '/chat'];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _tabs.indexOf(location);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Home', selected: idx == 0, onTap: () => context.go('/home')),
                _NavItem(icon: Icons.calendar_today_rounded, label: 'Timetable', selected: idx == 1, onTap: () => context.go('/timetable')),
                _NavItem(icon: Icons.checklist_rounded, label: 'Tasks', selected: idx == 2, onTap: () => context.go('/tasks')),
                _NavItem(icon: Icons.edit_note_rounded, label: 'Notes', selected: idx == 3, onTap: () => context.go('/notes')),
                _NavItem(icon: Icons.forum_rounded, label: 'Chat', selected: idx == 4, onTap: () => context.go('/chat')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.blue.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: selected ? AppColors.blue : AppColors.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.blue : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
