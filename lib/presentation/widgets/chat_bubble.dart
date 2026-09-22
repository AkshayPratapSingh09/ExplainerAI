import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api/google_cloud_tts_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts/native_tts_service.dart';
import '../../core/utils/tts_normalizer.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import 'audio_player_bubble.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onDelete;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onRetry,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isThoughtExpanded = false;
  bool _copied = false;
  bool _isGcloudLoading = false;

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _synthesizeGoogleCloud(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final chat = context.read<ChatProvider>();

    if (!settings.hasGcloudApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Google Cloud API Key not set. Add it in Settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isGcloudLoading = true);
    try {
      final client = GoogleCloudTtsClient();
      final textToSpeak = TtsNormalizer.normalizeForNativeTts(
        widget.message.spokenScript?.isNotEmpty == true ? widget.message.spokenScript! : widget.message.text,
      );

      final audioPath = await client.synthesizeSpeech(
        apiKey: settings.googleCloudApiKey,
        text: textToSpeak,
        voiceName: settings.googleCloudVoiceName,
        speakingRate: settings.googleCloudRate,
        pitch: settings.googleCloudPitch,
      );

      await chat.updateMessageAudio(
        widget.message.id,
        audioPath,
        speaker: settings.googleCloudVoiceName,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Cloud TTS Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isGcloudLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isUser) {
      return _buildUserBubble(context, isDark);
    } else {
      return _buildAssistantBubble(context, isDark);
    }
  }

  Widget _buildUserBubble(BuildContext context, bool isDark) {
    final timeStr = DateFormat('hh:mm a').format(widget.message.createdAt);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // User mode badge
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.message.mode == ProcessingMode.explain
                            ? Icons.auto_awesome_rounded
                            : (widget.message.mode == ProcessingMode.ttsOnly
                                ? Icons.volume_up_rounded
                                : Icons.chat_bubble_outline_rounded),
                        size: 11,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.message.mode == ProcessingMode.explain
                            ? 'Hinglish Explainer'
                            : (widget.message.mode == ProcessingMode.ttsOnly ? 'TTS Audio' : 'Chat'),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // User bubble container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232634) : AppColors.primaryDark,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: SelectableText(
                widget.message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context, bool isDark) {
    final timeStr = DateFormat('hh:mm a').format(widget.message.createdAt);
    final nativeTts = context.watch<NativeTtsService>();
    final isNativeSpeakingThis = nativeTts.isPlaying && nativeTts.currentSpeakingMessageId == widget.message.id;
    final chat = context.read<ChatProvider>();
    final settings = context.watch<SettingsProvider>();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Model Pill & Timestamp
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primaryLight),
                      const SizedBox(width: 5),
                      Text(
                        widget.message.modelUsed ?? 'sarvam-105b',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Assistant Main Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading Indicator if generating text
                  if (widget.message.isTextLoading) ...[
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Generating clear Hinglish explanation...',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ] else if (widget.message.errorMessage != null && widget.message.text.isEmpty) ...[
                    // Error view
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withAlpha(80)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Generation Error',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.message.errorMessage!,
                            style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Render Markdown Content
                    MarkdownBody(
                      data: widget.message.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          height: 1.55,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        ),
                        h1: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        ),
                        h2: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        ),
                        h3: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                        listBullet: TextStyle(
                          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                        code: TextStyle(
                          fontSize: 12.5,
                          fontFamily: 'monospace',
                          backgroundColor: isDark ? const Color(0xFF13151A) : Colors.grey.shade200,
                          color: AppColors.secondary,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: isDark ? const Color(0xFF13151A) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                          ),
                        ),
                        tableBorder: TableBorder.all(
                          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                          width: 1,
                        ),
                        tableHead: const TextStyle(fontWeight: FontWeight.bold),
                        blockquoteDecoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                          border: const Border(
                            left: BorderSide(color: AppColors.primary, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // 1. Embedded MP3 Audio Player Bubble (if generated via Sarvam/GCloud)
                  if (!widget.message.isTextLoading && (widget.message.hasAudio || widget.message.isAudioLoading))
                    AudioPlayerBubble(message: widget.message),

                  // 2. Active Native On-Device Playing Bar
                  if (isNativeSpeakingThis)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.graphic_eq_rounded, color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Speaking with On-Device Voice (₹0 Free)...',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop_circle_rounded, color: AppColors.error, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => nativeTts.stop(),
                          ),
                        ],
                      ),
                    ),

                  // 3. Multi-Tier Listening Action Chips (shown if not currently playing)
                  if (!widget.message.isTextLoading && widget.message.text.isNotEmpty && !widget.message.hasAudio && !isNativeSpeakingThis) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Chip 1: Native Free On-Device TTS
                        InkWell(
                          onTap: () {
                            final textToSpeak = TtsNormalizer.normalizeForNativeTts(
                              widget.message.spokenScript?.isNotEmpty == true
                                  ? widget.message.spokenScript!
                                  : widget.message.text,
                            );
                            nativeTts.speak(text: textToSpeak, messageId: widget.message.id);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.success.withAlpha(80)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.volume_up_rounded, size: 14, color: AppColors.success),
                                SizedBox(width: 5),
                                Text(
                                  'Listen (Free • ₹0)',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.success),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Chip 2: Sarvam Bulbul HD
                        InkWell(
                          onTap: () {
                            if (!settings.hasApiKey) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please add Sarvam API Key in Settings first.')),
                              );
                              return;
                            }
                            chat.regenerateAudioForMessage(
                              messageId: widget.message.id,
                              apiKey: settings.apiKey,
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withAlpha(80)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.primaryLight),
                                SizedBox(width: 5),
                                Text(
                                  'Sarvam HD Voice',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Chip 3: Google Cloud TTS
                        if (settings.hasGcloudApiKey)
                          InkWell(
                            onTap: _isGcloudLoading ? null : () => _synthesizeGoogleCloud(context),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.withAlpha(80)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isGcloudLoading)
                                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                                  else
                                    const Icon(Icons.cloud_queue_rounded, size: 13, color: Colors.blue),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Google Cloud',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Collapsible Spoken Script View
                  if (widget.message.spokenScript != null && widget.message.spokenScript!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setState(() => _isThoughtExpanded = !_isThoughtExpanded),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isThoughtExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                              size: 16,
                              color: AppColors.primaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isThoughtExpanded ? 'Hide Audio Spoken Script' : 'View Spoken Script for Audio',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isThoughtExpanded)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF101217) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                          ),
                        ),
                        child: SelectableText(
                          widget.message.spokenScript!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ),
                      ),
                  ],

                  // Action Buttons Footer
                  if (!widget.message.isTextLoading && widget.message.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Copy Button
                        IconButton(
                          icon: Icon(
                            _copied ? Icons.check_rounded : Icons.copy_rounded,
                            size: 16,
                            color: _copied ? AppColors.success : (isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                          ),
                          tooltip: 'Copy explanation',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _copyToClipboard(widget.message.text, context),
                        ),
                        const SizedBox(width: 14),
                        // Delete Button
                        if (widget.onDelete != null)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                            ),
                            tooltip: 'Delete message',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: widget.onDelete,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
