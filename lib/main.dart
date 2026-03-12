import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'providers/focus_provider.dart';
import 'providers/language_provider.dart';
import 'providers/schedule_provider.dart';
import 'dart:async';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FocusProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
      ],
      child: const FocusFlowApp(),
    ),
  );
}

class FocusFlowApp extends StatefulWidget {
  const FocusFlowApp({super.key});

  @override
  State<FocusFlowApp> createState() => _FocusFlowAppState();
}

class _FocusFlowAppState extends State<FocusFlowApp> {
  Timer? _scheduleChecker;

  @override
  void initState() {
    super.initState();
    _scheduleChecker = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      final scheduleProv = context.read<ScheduleProvider>();
      final focusProv = context.read<FocusProvider>();

      final activeSchedule = scheduleProv.getCurrentActiveSchedule();
      if (activeSchedule != null) {
        if (!focusProv.isFocusing && !focusProv.isResting) {
            // Force strict mode for scheduled focus
            if (!focusProv.isStrictMode) {
              focusProv.toggleStrictMode(); 
            }
            
            // Calculate remaining seconds for this schedule
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day, activeSchedule.startHour, activeSchedule.startMinute);
            DateTime scheduleStart = todayStart;
            // If schedule started yesterday (crosses midnight)
            if (now.isBefore(todayStart)) {
              scheduleStart = todayStart.subtract(const Duration(days: 1));
            }
            final scheduleEnd = scheduleStart.add(Duration(minutes: activeSchedule.durationMinutes));
            final remainingSeconds = scheduleEnd.difference(now).inSeconds;

            if (remainingSeconds > 0) {
              focusProv.startScheduledFocus(
                durationSeconds: remainingSeconds,
                blockListId: activeSchedule.blockListId,
              );
            }
        }
      }
    });
  }

  @override
  void dispose() {
    _scheduleChecker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'focus_on',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Color(0xFF334155)),
          titleTextStyle: TextStyle(color: Color(0xFF334155), fontSize: 20, fontWeight: FontWeight.normal),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme.apply(bodyColor: const Color(0xFF334155), displayColor: const Color(0xFF334155))),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFA1C6EA),
          secondary: Color(0xFF10B981),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
