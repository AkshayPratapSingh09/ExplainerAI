import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/audio/app_audio_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';

class AudioPlayerBubble extends StatelessWidget {
  final ChatMessage message;

  const AudioPlayerBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final audioController = context.watch<AppAudioController>();
    final isCurrentAudio = audioController.currentMessageId == message.id;
    final isPlaying = isCurrentAudio && audioController.isPlaying;
    final isBuffering = isCurrentAudio && audioController.state.isBuffering;
    final position = isCurrentAudio ? audioController.position : Duration.zero;
    final duration = isCurrentAudio && audioController.duration > Duration.zero
        ? audioController.duration
        : (message.audioDuration ?? Duration.zero);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isAudioLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Synthesizing Hinglish audio with Sarvam Bulbul...',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (message.audioPath == null || message.audioPath!.isEmpty) {
      return const SizedBox.shrink();
    }

    final speakerName = message.speakerUsed != null
        ? '${message.speakerUsed![0].toUpperCase()}${message.speakerUsed!.substring(1)}'
        : 'Shubh';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13151A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying
              ? AppColors.primary.withAlpha(150)
              : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
          width: isPlaying ? 1.5 : 1.0,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Speaker info, Pace badge, Speed switcher
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  size: 14,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Bulbul v3 • $speakerName',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.chipDarkBg : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${message.paceUsed}x pace',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // Speed cycle button
              InkWell(
                onTap: isCurrentAudio ? () => audioController.cycleSpeed() : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Text(
                    '${isCurrentAudio ? audioController.speed : 1.0}x',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Options menu for regenerating voice
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 16,
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (val) {
                  if (val == 'regenerate') {
                    _showRegenerateVoiceDialog(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'regenerate',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Change Voice / Pace', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Player Controls and Progress Bar
          Row(
            children: [
              // Play/Pause circular button
              GestureDetector(
                onTap: () {
                  audioController.playOrPause(
                    messageId: message.id,
                    audioPath: message.audioPath!,
                    title: message.text.length > 30
                        ? '${message.text.substring(0, 30)}...'
                        : message.text,
                    subtitle: 'Sarvam AI Explainer ($speakerName)',
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: isBuffering
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Progress Bar
              Expanded(
                child: ProgressBar(
                  progress: position,
                  total: duration > Duration.zero ? duration : const Duration(seconds: 1),
                  buffered: duration,
                  onSeek: isCurrentAudio ? (pos) => audioController.seek(pos) : null,
                  progressBarColor: AppColors.primary,
                  baseBarColor: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                  bufferedBarColor: AppColors.primary.withAlpha(50),
                  thumbColor: AppColors.primaryLight,
                  thumbRadius: 5.5,
                  timeLabelTextStyle: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  timeLabelPadding: 4,
                ),
              ),

              const SizedBox(width: 8),

              // 10s Rewind / Fast Forward
              if (isCurrentAudio) ...[
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  onPressed: () => audioController.seekBackward10(),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                  onPressed: () => audioController.seekForward10(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showRegenerateVoiceDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final chat = context.read<ChatProvider>();
    String selectedSpeaker = message.speakerUsed ?? settings.defaultSpeaker;
    double selectedPace = message.paceUsed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change Audio Voice & Pace',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Select Speaker:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['shubh', 'rohan', 'priya', 'pooja', 'arvind', 'amartya', 'shruti', 'kavya'].map((sp) {
                      final isSelected = selectedSpeaker.toLowerCase() == sp.toLowerCase();
                      return ChoiceChip(
                        label: Text('${sp[0].toUpperCase()}${sp.substring(1)}'),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedSpeaker = sp);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Voice Pace / Speed:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('${selectedPace.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: selectedPace,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: '${selectedPace.toStringAsFixed(1)}x',
                    onChanged: (val) => setModalState(() => selectedPace = val),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        chat.regenerateAudioForMessage(
                          messageId: message.id,
                          apiKey: settings.apiKey,
                          speaker: selectedSpeaker,
                          pace: selectedPace,
                        );
                      },
                      child: const Text('Re-synthesize Audio', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
