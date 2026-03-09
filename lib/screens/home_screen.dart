import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';
import '../providers/language_provider.dart';

import 'app_selector_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          DropdownButton<String>(
            value: lang.currentLanguage,
            dropdownColor: const Color(0xFF0F172A),
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white70, size: 20),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('EN', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'zh', child: Text('中文', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'ja', child: Text('日本語', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (String? newValue) {
              if (newValue != null) {
                context.read<LanguageProvider>().changeLanguage(newValue);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSelectorScreen()));
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E3A8A), // dark blue
                  Color(0xFF064E3B), // dark emerald
                  Color(0xFF0F172A), // practically black
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!focusProvider.isFocusing && !focusProvider.isResting)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(lang.translate('pomodoro_mode'), style: const TextStyle(color: Colors.white70)),
                              Switch(
                                value: focusProvider.isPomodoroMode,
                                activeColor: const Color(0xFF10B981),
                                onChanged: (_) => focusProvider.togglePomodoroMode(),
                              ),
                            ],
                          ),
                        Text(
                          focusProvider.isResting ? lang.translate('resting') : (focusProvider.isFocusing ? lang.translate('focus_active') : lang.translate('ready_to_focus')),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        Text(
                          focusProvider.formattedTime,
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 2.0,
                          ),
                        ),
                        
                        const SizedBox(height: 60),
                        
                        GestureDetector(
                          onTap: () {
                            if (focusProvider.isFocusing || focusProvider.isResting) {
                              focusProvider.stopFocus();
                            } else {
                              focusProvider.startFocus(focusProvider.isPomodoroMode ? 25 : 30);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                            decoration: BoxDecoration(
                              gradient: (focusProvider.isFocusing || focusProvider.isResting)
                                  ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFF991B1B)])
                                  : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: ((focusProvider.isFocusing || focusProvider.isResting) ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              (focusProvider.isFocusing || focusProvider.isResting) ? lang.translate('give_up') : lang.translate('start_focus'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
