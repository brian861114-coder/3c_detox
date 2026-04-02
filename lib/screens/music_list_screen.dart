import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';
import '../providers/language_provider.dart';

class MusicListScreen extends StatelessWidget {
  const MusicListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusProvider = context.watch<FocusProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(lang.translate('music_list'), style: const TextStyle(color: Color(0xFF334155))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF334155)),
      ),
      body: focusProvider.musicPaths.isEmpty
          ? Center(
              child: Text(
                lang.translate('none_selected'),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: focusProvider.musicPaths.length,
              itemBuilder: (context, index) {
                final path = focusProvider.musicPaths[index];
                final fileName = path.split('/').last;

                return ListTile(
                  leading: const Icon(Icons.music_note, color: Color(0xFF10B981)),
                  title: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      focusProvider.removeMusicPath(path);
                    },
                  ),
                );
              },
            ),
    );
  }
}
