// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Update streak on each home visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirestoreService>().updateStreak();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.userModel;
    final firstName = (user?.name ?? '').trim().split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Header ─────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(firstName), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Ready to conquer the day? 🔥', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),

          // ─── Body ────────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Streak Card
                if ((user?.streak ?? 0) > 0) ...[
                  _StreakCard(streak: user!.streak),
                  const SizedBox(height: 20),
                ],

                // XP Bar
                if (user != null) ...[
                  _XpCard(user: user),
                  const SizedBox(height: 24),
                ],

                // Quick Access
                Text('Quick Access ⚡', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _QuickCard(
                      icon: Icons.checklist_rounded,
                      label: 'Tasks',
                      subtitle: 'View & manage',
                      gradient: [AppColors.blue, const Color(0xFF6366F1)],
                      onTap: () => context.go('/tasks'),
                    ),
                    _QuickCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Timetable',
                      subtitle: "Today's schedule",
                      gradient: [AppColors.orange, AppColors.rose],
                      onTap: () => context.go('/timetable'),
                    ),
                    _QuickCard(
                      icon: Icons.self_improvement_rounded,
                      label: 'Study Room',
                      subtitle: 'Pomodoro + lofi',
                      gradient: [AppColors.emerald, AppColors.teal],
                      onTap: () => context.push('/study-room'),
                    ),
                    _QuickCard(
                      icon: Icons.smart_toy_rounded,
                      label: 'AZ AI',
                      subtitle: 'AI study buddy',
                      gradient: [AppColors.violet, const Color(0xFFEC4899)],
                      onTap: () => _openAzAI(context),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return name.isEmpty ? '$greeting! 👋' : '$greeting, $name! 👋';
  }

  void _openAzAI(BuildContext context) {
    // TODO: Open full-screen AZ AI chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AZ AI is coming soon! 🤖')),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$streak Day Streak!', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('Keep it up! Log in tomorrow to grow.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _XpCard extends StatelessWidget {
  final dynamic user;
  const _XpCard({required this.user});

  @override
  Widget build(BuildContext context) {
    const maxXp = 1000;
    final xp = (user.weeklyXp as int).clamp(0, maxXp);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(user.userRank, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text('$xp XP', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: xp / maxXp,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text('Weekly progress', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickCard({required this.icon, required this.label, required this.subtitle, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: gradient.first.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
