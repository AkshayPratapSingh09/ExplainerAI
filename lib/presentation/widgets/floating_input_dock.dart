import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import 'model_selector_sheet.dart';

class FloatingInputDock extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const FloatingInputDock({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  State<FloatingInputDock> createState() => _FloatingInputDockState();
}

class _FloatingInputDockState extends State<FloatingInputDock> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  void _onTextChanged() {
    final hasContent = widget.controller.text.trim().isNotEmpty;
    if (_hasText != hasContent) {
      setState(() => _hasText = hasContent);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      widget.controller.text = data.text!;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.controller.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final speakerName = chat.selectedSpeaker.isNotEmpty
        ? '${chat.selectedSpeaker[0].toUpperCase()}${chat.selectedSpeaker.substring(1)}'
        : 'Shubh';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Controls Toolbar (Mode Selector, Voice Selector, Pace, Audio Toggle)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // 1. Mode Selector Pill
                  PopupMenuButton<ProcessingMode>(
                    initialValue: chat.currentMode,
                    tooltip: 'Change Mode',
                    onSelected: (mode) => chat.setMode(mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(isDark ? 35 : 20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            chat.currentMode == ProcessingMode.explain
                                ? Icons.auto_awesome_rounded
                                : (chat.currentMode == ProcessingMode.ttsOnly
                                    ? Icons.volume_up_rounded
                                    : Icons.chat_bubble_outline_rounded),
                            size: 13,
                            color: AppColors.primaryLight,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            chat.currentMode == ProcessingMode.explain
                                ? '✨ Explain in Hinglish'
                                : (chat.currentMode == ProcessingMode.ttsOnly ? '🔊 TTS Only' : '💬 Chat'),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.primaryLight),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: ProcessingMode.explain,
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Explain in Hinglish', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('Converts complex text, tables & numbers into audio explainer', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: ProcessingMode.chat,
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.secondary),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Direct AI Chat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('Standard conversational responses in Hinglish', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: ProcessingMode.ttsOnly,
                        child: Row(
                          children: [
                            Icon(Icons.volume_up_rounded, size: 16, color: AppColors.audioWave),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Direct TTS Speech', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('Synthesizes pasted text directly into audio', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 8),

                  // 2. Voice & Model Catalog Chip
                  InkWell(
                    onTap: () => ModelSelectorSheet.show(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.chipDarkBg : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.chipDarkBorder : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.record_voice_over_rounded, size: 12, color: AppColors.secondary),
                          const SizedBox(width: 5),
                          Text(
                            '$speakerName • ${chat.selectedPace}x',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.unfold_more_rounded,
                            size: 13,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 3. Audio Toggle Pill
                  InkWell(
                    onTap: () => chat.setAudioEnabled(!chat.audioEnabled),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: chat.audioEnabled
                            ? AppColors.audioWave.withAlpha(25)
                            : (isDark ? AppColors.darkCard : Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: chat.audioEnabled
                              ? AppColors.audioWave.withAlpha(120)
                              : (isDark ? AppColors.darkCardBorder : Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            chat.audioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            size: 12,
                            color: chat.audioEnabled ? AppColors.audioWave : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chat.audioEnabled ? 'Audio ON' : 'Audio OFF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: chat.audioEnabled ? AppColors.audioWave : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Text Input Area
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Quick Paste from Clipboard
                IconButton(
                  icon: const Icon(Icons.paste_rounded, size: 20),
                  tooltip: 'Paste from clipboard',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  onPressed: _pasteFromClipboard,
                ),
                const SizedBox(width: 8),

                // Text Field
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: chat.currentMode == ProcessingMode.explain
                          ? 'Paste text, articles, tables to explain in Hinglish...'
                          : (chat.currentMode == ProcessingMode.ttsOnly
                              ? 'Enter text to convert to voice...'
                              : 'Ask anything in Hinglish...'),
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFF5E6578) : Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Clear button if text exists
                if (_hasText)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    onPressed: () => widget.controller.clear(),
                  ),

                if (_hasText) const SizedBox(width: 6),

                // Send / Action Button
                GestureDetector(
                  onTap: () {
                    if (chat.isGenerating) return;
                    if (!settings.hasApiKey) {
                      _showApiKeyPrompt(context);
                      return;
                    }
                    if (_hasText) {
                      widget.onSend();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: (_hasText && !chat.isGenerating)
                            ? [AppColors.primary, AppColors.primaryDark]
                            : [Colors.grey.shade700, Colors.grey.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: (_hasText && !chat.isGenerating)
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(100),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: chat.isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please enter your Sarvam AI API Key in Settings first!'),
        action: SnackBarAction(
          label: 'Settings',
          textColor: AppColors.primaryLight,
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
