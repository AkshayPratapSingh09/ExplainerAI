import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_settings.dart';
import '../../providers/chat_provider.dart';

class ModelSelectorSheet extends StatefulWidget {
  const ModelSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ModelSelectorSheet(),
    );
  }

  @override
  State<ModelSelectorSheet> createState() => _ModelSelectorSheetState();
}

class _ModelSelectorSheetState extends State<ModelSelectorSheet> {
  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Model & Voice Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Powered by Sarvam AI Models',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. Sarvam LLM Model
                _buildSectionHeader('Chat & Reasoning Model', Icons.psychology_rounded, isDark),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppSettings.availableChatModels.map((model) {
                    final isSelected = chat.selectedChatModel == model;
                    return InkWell(
                      onTap: () => chat.setChatModel(model),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withAlpha(30)
                              : (isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                              size: 16,
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              model,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 2. TTS Voice Catalog
                _buildSectionHeader('Sarvam Bulbul Voice Speakers', Icons.record_voice_over_rounded, isDark),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.1,
                  ),
                  itemCount: AppSettings.availableSpeakers.length,
                  itemBuilder: (context, index) {
                    final speaker = AppSettings.availableSpeakers[index];
                    final isSelected = chat.selectedSpeaker.toLowerCase() == speaker.id.toLowerCase();

                    return InkWell(
                      onTap: () => chat.setSpeaker(speaker.id),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withAlpha(35)
                              : (isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.chipDarkBg : Colors.grey.shade300),
                              child: Text(
                                speaker.name[0],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        speaker.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${speaker.gender[0]})',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    speaker.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 3. Audio Pace & Speed Slider
                _buildSectionHeader('Speech Pace (${chat.selectedPace.toStringAsFixed(2)}x)', Icons.speed_rounded, isDark),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('0.5x', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Expanded(
                      child: Slider(
                        value: chat.selectedPace,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        activeColor: AppColors.primary,
                        inactiveColor: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                        label: '${chat.selectedPace.toStringAsFixed(1)}x',
                        onChanged: (val) => chat.setPace(val),
                      ),
                    ),
                    const Text('2.0x', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. Target Language Code
                _buildSectionHeader('Target Language', Icons.translate_rounded, isDark),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppSettings.supportedLanguages.map((lang) {
                    final isSelected = chat.selectedLanguageCode == lang.code;
                    return ChoiceChip(
                      label: Text('${lang.name} (${lang.code})'),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withAlpha(50),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? AppColors.primaryLight
                            : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) chat.setLanguageCode(lang.code);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Close / Done button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
        ),
      ],
    );
  }
}
