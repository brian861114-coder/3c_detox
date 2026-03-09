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
                colors: [Color(0xFF1E3A8A), Color(0xFF0F172A), Color(0xFF0F172A)],
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _installedApps.length,
                    itemBuilder: (context, index) {
                      final app = _installedApps[index];
                      final packageName = app['packageName']!;
                      final appName = app['name']!;
                      final isBlocked = focusProvider.blacklistedApps.contains(packageName);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isBlocked ? const Color(0xFFEF4444).withOpacity(0.5) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(appName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          subtitle: Text(packageName, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
                          trailing: Switch(
                            value: isBlocked,
                            activeColor: const Color(0xFFEF4444),
                            onChanged: (_) => focusProvider.toggleAppBlacklist(packageName),
                          ),
                          onTap: () => focusProvider.toggleAppBlacklist(packageName),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
