// lib/screens/study_room/study_room_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

// ─── Pomodoro mode enum ───────────────────────────────────────────────────────
enum PomoMode { focus, shortBreak, longBreak }

// Lofi stations — unique radio streams
const _stations = [
  _Station('🌙 Groove Salad', 'Ambient & Chill', 'https://ice2.somafm.com/groovesalad-128-mp3'),
  _Station('☕ Lush Lofi', 'Warm & Cozy Vibes',  'https://ice2.somafm.com/lush-128-mp3'),
  _Station('🌿 Drone Zone', 'Deep Focus Ambient', 'https://ice2.somafm.com/dronezone-128-mp3'),
  _Station('🌊 Chillout FM', 'Ocean Focus Flow',  'https://streams.fluxfm.de/Chillout/mp3-128/streams.fluxfm.de/'),
];

class _Station {
  final String name;
  final String subtitle;
  final String url;
  const _Station(this.name, this.subtitle, this.url);
}

class StudyRoomScreen extends StatefulWidget {
  const StudyRoomScreen({super.key});

  @override
  State<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> with SingleTickerProviderStateMixin {
  // ─── Pomodoro state ─────────────────────────────────────────────────────────
  PomoMode _mode = PomoMode.focus;
  int _remaining = 25 * 60;
  int _total = 25 * 60;
  bool _running = false;
  int _sessionsDone = 0;
  int _totalMinsFocused = 0;
  Timer? _timer;
  late AnimationController _pulseCtrl;

  // ─── Lofi state ─────────────────────────────────────────────────────────────
  final AudioPlayer _lofiPlayer = AudioPlayer();
  bool _lofiPlaying = false;
  int _stationIndex = 0;
  double _volume = 0.7;

  // ─── Focus goal ─────────────────────────────────────────────────────────────
  final TextEditingController _goalCtrl = TextEditingController();
  String? _currentGoal;

  static const Map<PomoMode, int> _durations = {
    PomoMode.focus: 25 * 60,
    PomoMode.shortBreak: 5 * 60,
    PomoMode.longBreak: 15 * 60,
  };
  static const Map<PomoMode, Color> _modeColors = {
    PomoMode.focus: AppColors.emerald,
    PomoMode.shortBreak: AppColors.blue,
    PomoMode.longBreak: AppColors.violet,
  };
  static const Map<PomoMode, String> _modeLabels = {
    PomoMode.focus: 'FOCUS',
    PomoMode.shortBreak: 'SHORT BREAK',
    PomoMode.longBreak: 'LONG BREAK',
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _lofiPlayer.setVolume(_volume);
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _currentGoal = prefs.getString('focus_goal'));
    if (_currentGoal != null) _goalCtrl.text = _currentGoal!;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _lofiPlayer.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  // ─── Pomodoro logic ──────────────────────────────────────────────────────────
  void _setMode(PomoMode mode) {
    _timer?.cancel();
    setState(() {
      _running = false;
      _mode = mode;
      _total = _durations[mode]!;
      _remaining = _total;
    });
  }

  void _toggleTimer() {
    HapticFeedback.lightImpact();
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    if (_remaining <= 0) {
      _timer?.cancel();
      _onSessionEnd();
      return;
    }
    setState(() => _remaining--);
  }

  void _onSessionEnd() {
    HapticFeedback.heavyImpact();
    final wasWork = _mode == PomoMode.focus;
    if (wasWork) {
      setState(() {
        _sessionsDone = (_sessionsDone + 1).clamp(0, 4);
        _totalMinsFocused += 25;
      });
      context.read<NotificationService>().notifyPomodoroComplete(isWorkSession: true);
      final next = _sessionsDone % 4 == 0 ? PomoMode.longBreak : PomoMode.shortBreak;
      _setMode(next);
    } else {
      context.read<NotificationService>().notifyPomodoroComplete(isWorkSession: false);
      if (_sessionsDone >= 4) setState(() => _sessionsDone = 0);
      _setMode(PomoMode.focus);
    }
    setState(() => _running = false);
  }

  void _resetTimer() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() { _running = false; _remaining = _total; });
  }

  void _skipTimer() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() => _remaining = 0);
    _onSessionEnd();
  }

  // ─── Lofi logic ──────────────────────────────────────────────────────────────
  Future<void> _toggleLofi() async {
    HapticFeedback.lightImpact();
    if (_lofiPlaying) {
      await _lofiPlayer.pause();
      setState(() => _lofiPlaying = false);
    } else {
      try {
        await _lofiPlayer.setUrl(_stations[_stationIndex].url);
        await _lofiPlayer.play();
        setState(() => _lofiPlaying = true);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load radio stream. Check your connection.')));
        }
      }
    }
  }

  Future<void> _selectStation(int idx) async {
    HapticFeedback.selectionClick();
    setState(() => _stationIndex = idx);
    if (_lofiPlaying) {
      try {
        await _lofiPlayer.setUrl(_stations[idx].url);
        await _lofiPlayer.play();
      } catch (_) {}
    }
  }

  void _setVolume(double v) {
    setState(() => _volume = v);
    _lofiPlayer.setVolume(v);
  }

  // ─── Focus goal ──────────────────────────────────────────────────────────────
  Future<void> _saveGoal() async {
    final goal = _goalCtrl.text.trim();
    if (goal.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('focus_goal', goal);
    setState(() => _currentGoal = goal);
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => _remaining / _total;

  @override
  Widget build(BuildContext context) {
    final color = _modeColors[_mode]!;
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.emerald, AppColors.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.self_improvement_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study Room', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.1)),
                Text('Focus · Flow · Flourish', style: TextStyle(color: AppColors.emerald, fontSize: 10, height: 1)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          children: [
            _PomodoroWidget(
              mode: _mode,
              progress: _progress,
              remaining: _remaining,
              running: _running,
              sessionsDone: _sessionsDone,
              totalMinsFocused: _totalMinsFocused,
              color: color,
              modeLabel: _modeLabels[_mode]!,
              pulseCtrl: _pulseCtrl,
              onSetMode: _setMode,
              onToggle: _toggleTimer,
              onReset: _resetTimer,
              onSkip: _skipTimer,
            ),
            const SizedBox(height: 20),
            _LofiWidget(
              playing: _lofiPlaying,
              stationIndex: _stationIndex,
              volume: _volume,
              onToggle: _toggleLofi,
              onSelectStation: _selectStation,
              onVolumeChanged: _setVolume,
            ),
            const SizedBox(height: 20),
            _FocusGoalWidget(
              ctrl: _goalCtrl,
              currentGoal: _currentGoal,
              onSave: _saveGoal,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pomodoro Widget ─────────────────────────────────────────────────────────
class _PomodoroWidget extends StatelessWidget {
  final PomoMode mode;
  final double progress;
  final int remaining;
  final bool running;
  final int sessionsDone;
  final int totalMinsFocused;
  final Color color;
  final String modeLabel;
  final AnimationController pulseCtrl;
  final ValueChanged<PomoMode> onSetMode;
  final VoidCallback onToggle, onReset, onSkip;

  const _PomodoroWidget({
    required this.mode, required this.progress, required this.remaining,
    required this.running, required this.sessionsDone, required this.totalMinsFocused,
    required this.color, required this.modeLabel, required this.pulseCtrl,
    required this.onSetMode, required this.onToggle, required this.onReset, required this.onSkip,
  });

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2,'0')}:${(s % 60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 40, spreadRadius: -5)],
      ),
      child: Column(
        children: [
          const Text('Pomodoro Timer 🍅', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),

          // Mode selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                _ModeBtn('Focus', PomoMode.focus, mode, color, onSetMode),
                _ModeBtn('Short Break', PomoMode.shortBreak, mode, AppColors.blue, onSetMode),
                _ModeBtn('Long Break', PomoMode.longBreak, mode, AppColors.violet, onSetMode),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Timer ring
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient glow
                if (running)
                  AnimatedBuilder(
                    animation: pulseCtrl,
                    builder: (_, __) => Transform.scale(
                      scale: 0.95 + 0.08 * pulseCtrl.value,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.18 * pulseCtrl.value), blurRadius: 40, spreadRadius: 10)]),
                      ),
                    ),
                  ),

                // Progress ring
                CustomPaint(
                  size: const Size(220, 220),
                  painter: _RingPainter(progress: progress, color: color),
                ),

                // Time display
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_fmt(remaining), style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -2, fontFeatures: const [FontFeature.tabularFigures()])),
                    Text(modeLabel, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Session dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: i < sessionsDone ? 24 : 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i < sessionsDone ? AppColors.emerald : Colors.white12,
                borderRadius: BorderRadius.circular(5),
              ),
            )),
          ),
          const SizedBox(height: 24),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CtrlBtn(icon: Icons.restart_alt_rounded, onTap: onReset, color: Colors.white38),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [color, color.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 24, spreadRadius: 2)],
                  ),
                  child: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(width: 20),
              _CtrlBtn(icon: Icons.skip_next_rounded, onTap: onSkip, color: Colors.white38),
            ],
          ),
          const SizedBox(height: 24),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(value: '$sessionsDone', label: 'Sessions'),
              Container(width: 1, height: 32, color: Colors.white12),
              _Stat(value: '${totalMinsFocused}m', label: 'Focused'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = cx - 12;
    final stroke = 10.0;

    // Background track
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.stroke..strokeWidth = stroke);

    // Progress arc
    final sweep = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2,
      -sweep, // counter-clockwise drain effect
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final PomoMode value, current;
  final Color color;
  final ValueChanged<PomoMode> onChanged;
  const _ModeBtn(this.label, this.value, this.current, this.color, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: selected ? color.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: selected ? Border.all(color: color.withOpacity(0.4)) : null),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? color : Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _CtrlBtn({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07), border: Border.all(color: Colors.white12)),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1)),
    ]);
  }
}

// ─── Lofi Radio Widget ────────────────────────────────────────────────────────
class _LofiWidget extends StatelessWidget {
  final bool playing;
  final int stationIndex;
  final double volume;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelectStation;
  final ValueChanged<double> onVolumeChanged;

  const _LofiWidget({required this.playing, required this.stationIndex, required this.volume, required this.onToggle, required this.onSelectStation, required this.onVolumeChanged});

  @override
  Widget build(BuildContext context) {
    final st = _stations[stationIndex];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Lofi Radio 🎧', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
              const Spacer(),
              if (playing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.rose.withOpacity(0.4))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.rose, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('LIVE', style: TextStyle(color: AppColors.rose, fontSize: 10, fontWeight: FontWeight.w800)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Station chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_stations.length, (i) {
                final sel = i == stationIndex;
                return GestureDetector(
                  onTap: () => onSelectStation(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.emerald.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.emerald.withOpacity(0.5) : Colors.transparent),
                    ),
                    child: Text(_stations[i].name, style: TextStyle(color: sel ? AppColors.emerald : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Now playing card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                // Album art
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.emerald, AppColors.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(playing ? Icons.music_note_rounded : Icons.music_off_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(st.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(st.subtitle, style: TextStyle(color: Colors.white54, fontSize: 12)),
                ])),
                // EQ animation
                if (playing)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(3, (i) => _EqBar(index: i)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Controls
          Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.emerald, AppColors.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [if (playing) BoxShadow(color: AppColors.emerald.withOpacity(0.4), blurRadius: 16)],
                  ),
                  child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Volume', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      Text('${(volume * 100).toInt()}%', style: const TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderThemeData(thumbColor: AppColors.emerald, activeTrackColor: AppColors.emerald, inactiveTrackColor: Colors.white12, overlayColor: AppColors.emerald.withOpacity(0.2), trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
                      child: Slider(value: volume, onChanged: onVolumeChanged),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EqBar extends StatefulWidget {
  final int index;
  const _EqBar({required this.index});

  @override
  State<_EqBar> createState() => _EqBarState();
}

class _EqBarState extends State<_EqBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: 400 + widget.index * 150))..repeat(reverse: true);
    _anim = Tween<double>(begin: 4, end: 18).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 3,
        height: _anim.value,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(color: AppColors.emerald, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

// ─── Focus Goal Widget ────────────────────────────────────────────────────────
class _FocusGoalWidget extends StatelessWidget {
  final TextEditingController ctrl;
  final String? currentGoal;
  final VoidCallback onSave;

  const _FocusGoalWidget({required this.ctrl, this.currentGoal, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Focus Goal 🎯", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onSubmitted: (_) => onSave(),
                  decoration: InputDecoration(
                    hintText: 'e.g. Finish chapter 4 of stats...',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.emerald, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.emerald, AppColors.teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Set', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ],
          ),
          if (currentGoal != null && currentGoal!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.emerald.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.emerald.withOpacity(0.25)),
              ),
              child: Text('🎯 $currentGoal', style: const TextStyle(color: AppColors.emerald, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}
