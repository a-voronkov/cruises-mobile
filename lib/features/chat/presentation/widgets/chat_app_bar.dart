import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../main.dart';

/// Custom app bar for chat page
class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return AppBar(
      title: const Text('Cruises Assistant'),
      actions: [
        // Theme toggle
        IconButton(
          icon: Icon(
            themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () {
            ref.read(themeModeProvider.notifier).state =
                themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
          },
          tooltip: 'Toggle theme',
        ),

        // More options
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'new_chat':
                // TODO: Create new chat
                break;
              case 'conversations':
                // TODO: Show conversations list
                break;
              case 'settings':
                // TODO: Show settings
                break;
              case 'about':
                // TODO: Show about dialog
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'new_chat',
              child: Row(
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 12),
                  Text('New Chat'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'conversations',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 12),
                  Text('Conversations'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'about',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Text('About'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

