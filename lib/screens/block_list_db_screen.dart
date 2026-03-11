import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';
import '../providers/language_provider.dart';
import 'app_selector_screen.dart';

class BlockListDbScreen extends StatelessWidget {
  const BlockListDbScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('block_lists'), style: const TextStyle(fontWeight: FontWeight.w300, letterSpacing: 1.0)),
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
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: focusProvider.blockLists.length,
                    itemBuilder: (context, index) {
                      final list = focusProvider.blockLists[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                title: Text(list.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
                                subtitle: Text('${list.apps.length} apps', style: TextStyle(color: const Color(0xFF334155).withOpacity(0.7))),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => AppSelectorScreen(blockListId: list.id)));
                                      },
                                    ),
                                    if (focusProvider.blockLists.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                        onPressed: () {
                                          focusProvider.deleteBlockList(list.id);
                                        },
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => AppSelectorScreen(blockListId: list.id)));
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0, top: 10.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                    ),
                    onPressed: () {
                      final newId = focusProvider.createBlockList();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AppSelectorScreen(blockListId: newId)));
                    },
                    icon: const Icon(Icons.add),
                    label: Text(lang.translate('create_new_list'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
