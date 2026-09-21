import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_session.dart';
import '../../providers/chat_provider.dart';

class HistoryDrawer extends StatelessWidget {
  const HistoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accentPurple],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explainer AI',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        ),
                      ),
                      const Text(
                        'Sarvam Audio History',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
            ),

            // "+ New Explanation" Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  chat.createNewSession();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_rounded, color: AppColors.primaryLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'New Explanation',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 16),

            // Sessions List
            Expanded(
              child: chat.sessions.isEmpty
                  ? Center(
                      child: Text(
                        'No saved explanations yet',
                        style: TextStyle(
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: chat.sessions.length,
                      itemBuilder: (context, index) {
                        final session = chat.sessions[index];
                        final isActive = chat.activeSession?.id == session.id;

                        return _buildSessionItem(context, session, isActive, isDark);
                      },
                    ),
            ),

            const Divider(height: 1),

            // Footer options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    '${chat.sessions.length} chats saved',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (chat.sessions.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearAll(context, chat),
                      child: const Text('Clear All', style: TextStyle(color: AppColors.error, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(
    BuildContext context,
    ChatSession session,
    bool isActive,
    bool isDark,
  ) {
    final chat = context.read<ChatProvider>();
    final formattedDate = DateFormat('MMM d, h:mm a').format(session.updatedAt);
    final audioCount = session.messages.where((m) => m.hasAudio).length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AppColors.darkCard : AppColors.lightCard)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: AppColors.primary.withAlpha(100), width: 1.2)
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          chat.selectSession(session.id);
          Navigator.pop(context);
        },
        leading: Icon(
          audioCount > 0 ? Icons.graphic_eq_rounded : Icons.chat_bubble_outline_rounded,
          size: 18,
          color: isActive ? AppColors.primaryLight : AppColors.textMuted,
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : AppColors.primaryDark)
                : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              formattedDate,
              style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
            ),
            if (audioCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.audioWave.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$audioCount audio',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.audioWave, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_horiz_rounded,
            size: 16,
            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onSelected: (val) {
            if (val == 'rename') {
              _showRenameDialog(context, chat, session);
            } else if (val == 'delete') {
              chat.deleteSession(session.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Rename', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ChatProvider chat, ChatSession session) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Explanation', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new title...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                chat.renameSession(session.id, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, ChatProvider chat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Explanations?'),
        content: const Text('This will delete all past conversations and cached audio files.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              chat.clearActiveSessionMessages();
              Navigator.pop(ctx);
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
