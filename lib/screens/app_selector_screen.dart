import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';
import '../providers/language_provider.dart';
import '../utils/native_integration.dart';

class AppSelectorScreen extends StatefulWidget {
  const AppSelectorScreen({super.key});

  @override
  State<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends State<AppSelectorScreen> {
  List<Map<String, String>> _installedApps = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchApps();
  }

  Future<void> _fetchApps() async {
    final apps = await NativeIntegration.getInstalledApps();
    apps.sort((a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()));
    
    // Only show apps on Android natively, but gracefully handle other platforms
    if (!mounted) return;
    setState(() {
      _installedApps = apps;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();
    final lang = context.watch<LanguageProvider>();

    final filteredApps = _searchQuery.isEmpty
        ? _installedApps
        : _installedApps.where((app) {
            final appName = app['name']?.toLowerCase() ?? '';
            final packageName = app['packageName']?.toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return appName.contains(query) || packageName.contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('choose_apps_to_block'), style: const TextStyle(fontWeight: FontWeight.w300, letterSpacing: 1.0)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Trigger permission requests as a shortcut for now
              NativeIntegration.requestUsageStatsPermission();
              NativeIntegration.requestOverlayPermission();
            },
            tooltip: 'Grant Native Permissions',
          )
        ],
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search apps...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF334155)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = filteredApps[index];
                            final packageName = app['packageName']!;
                            final appName = app['name']!;
                      final isBlocked = focusProvider.blacklistedApps.contains(packageName);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isBlocked ? const Color(0xFFEF4444).withOpacity(0.5) : Colors.white.withOpacity(0.6),
                                  width: 1,
                                ),
                              ),
                        child: ListTile(
                          title: Text(appName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                          subtitle: Text(packageName, style: TextStyle(fontSize: 12, color: const Color(0xFF334155).withOpacity(0.6))),
                          trailing: Switch(
                            value: isBlocked,
                            activeColor: const Color(0xFFEF4444),
                            onChanged: (_) => focusProvider.toggleAppBlacklist(packageName),
                          ),
                          onTap: () => focusProvider.toggleAppBlacklist(packageName),
                        ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
