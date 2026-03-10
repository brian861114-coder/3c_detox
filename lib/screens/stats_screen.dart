import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';
import '../providers/language_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('focus_stats'), style: const TextStyle(fontWeight: FontWeight.w300)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8E6F8), // pastel lavender
                  Color(0xFFE0F4E8), // mint green
                  Color(0xFFD6E8EE), // baby blue
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatCard(lang.translate('pomodoro_sessions'), '${focusProvider.focusCyclesCompleted} ${lang.translate('completed')}', Icons.check_circle_outline),
                  const SizedBox(height: 20),
                  _buildStatCard(lang.translate('total_focused_time'), '${focusProvider.totalFocusedMinutes} ${lang.translate('minutes')}', Icons.timer),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFF10B981)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        ],
      ),
        ),
      ),
    );
  }
}
