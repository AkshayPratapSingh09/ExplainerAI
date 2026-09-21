import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/sarvam_client.dart';
import '../../core/audio/app_audio_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _customPromptController;
  bool _obscureApiKey = true;
  bool _isTestingVoice = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _customPromptController = TextEditingController(text: settings.customSystemPrompt);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  Future<void> _testVoiceSample() async {
    final settings = context.read<SettingsProvider>();
    final audioController = context.read<AppAudioController>();

    if (!settings.hasApiKey) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter and save your Sarvam API Key first!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isTestingVoice = true);

    try {
      final client = SarvamClient();
      const sampleText = 'नमस्ते! यह Sarvam AI की बुलबुल आवाज़ है। आपका Hinglish explainer तैयार है।';
      final audioPath = await client.convertTextToSpeech(
        apiKey: settings.apiKey,
        text: sampleText,
        targetLanguageCode: settings.defaultLanguageCode,
        speaker: settings.defaultSpeaker,
        model: settings.defaultTtsModel,
        pace: settings.defaultPace,
      );

      await audioController.playOrPause(
        messageId: 'voice_sample_preview',
        audioPath: audioPath,
        title: 'Voice Sample (${settings.defaultSpeaker})',
        subtitle: 'Sarvam AI ${settings.defaultTtsModel}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('▶️ Playing sample for ${settings.defaultSpeaker} (${settings.defaultPace}x)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sample synthesis failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingVoice = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => settings.resetToDefaults(),
            child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. API Key Card
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Sarvam AI API Subscription Key', Icons.vpn_key_rounded, isDark),
                const SizedBox(height: 6),
                Text(
                  'Your API key is stored securely on your device and sent directly to api.sarvam.ai.',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureApiKey,
                  style: const TextStyle(fontSize: 13.5, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'Enter your Sarvam API Key...',
                    filled: true,
                    fillColor: isDark ? AppColors.darkInputBg : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: settings.isValidatingKey
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(
                                settings.isKeyValid == true ? Icons.check_circle_rounded : Icons.sync_rounded,
                                size: 16,
                              ),
                        label: Text(
                          settings.isValidatingKey
                              ? 'Verifying...'
                              : (settings.isKeyValid == true ? 'Verified & Saved' : 'Save & Verify Key'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: settings.isKeyValid == true ? AppColors.success : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: settings.isValidatingKey
                            ? null
                            : () async {
                                final key = _apiKeyController.text.trim();
                                await settings.updateApiKey(key);
                                final valid = await settings.testApiKey(key);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      valid
                                          ? '✅ Sarvam API Key verified successfully!'
                                          : '⚠️ Key verification failed. Please check your key.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: valid ? AppColors.success : AppColors.error,
                                  ),
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Default Models Card
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Default AI Models', Icons.psychology_rounded, isDark),
                const SizedBox(height: 14),

                // Chat Model
                _buildDropdownRow(
                  label: 'Default Chat Model',
                  value: settings.defaultChatModel,
                  items: AppSettings.availableChatModels,
                  onChanged: (val) {
                    if (val != null) settings.updateChatModel(val);
                  },
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                // TTS Model
                _buildDropdownRow(
                  label: 'Default TTS Model',
                  value: settings.defaultTtsModel,
                  items: AppSettings.availableTtsModels,
                  onChanged: (val) {
                    if (val != null) settings.updateTtsModel(val);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Default Voice & Pace Card
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Voice Speaker & Audio Pace', Icons.record_voice_over_rounded, isDark),
                    // Test voice button
                    TextButton.icon(
                      onPressed: _isTestingVoice ? null : _testVoiceSample,
                      icon: _isTestingVoice
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.play_circle_outline_rounded, size: 16, color: AppColors.primaryLight),
                      label: Text(
                        _isTestingVoice ? 'Generating...' : 'Preview Voice',
                        style: const TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Speaker selection
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppSettings.availableSpeakers.map((sp) {
                    final isSelected = settings.defaultSpeaker.toLowerCase() == sp.id.toLowerCase();
                    return ChoiceChip(
                      label: Text('${sp.name} (${sp.gender[0]})'),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withAlpha(50),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primaryLight
                            : (isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary),
                      ),
                      onSelected: (val) {
                        if (val) settings.updateSpeaker(sp.id);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Pace Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Default Pace / Speed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                      ),
                    ),
                    Text(
                      '${settings.defaultPace.toStringAsFixed(2)}x',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                    ),
                  ],
                ),
                Slider(
                  value: settings.defaultPace,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  activeColor: AppColors.primary,
                  inactiveColor: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                  onChanged: (val) => settings.updatePace(val),
                ),

                const SizedBox(height: 8),

                // Language
                _buildDropdownRow(
                  label: 'Default Language Code',
                  value: settings.defaultLanguageCode,
                  items: AppSettings.supportedLanguages.map((l) => l.code).toList(),
                  onChanged: (val) {
                    if (val != null) settings.updateLanguageCode(val);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Playback & Theme Preferences
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('App Preferences', Icons.tune_rounded, isDark),
                const SizedBox(height: 12),

                // Auto-generate audio switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Auto-Generate Audio', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Automatically synthesize Bulbul audio for explanations', style: TextStyle(fontSize: 11.5)),
                  value: settings.isAudioAutoGenerate,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) => settings.updateAudioAutoGenerate(val),
                ),

                const Divider(height: 12),

                // Background audio switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('System Background Audio', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Continue playback when app is minimized or screen is locked', style: TextStyle(fontSize: 11.5)),
                  value: settings.backgroundAudioEnabled,
                  activeTrackColor: AppColors.audioWave,
                  onChanged: (val) => settings.updateBackgroundAudio(val),
                ),

                const Divider(height: 12),

                // Theme Mode selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Theme Mode', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    DropdownButton<ThemeMode>(
                      value: settings.themeMode,
                      underline: const SizedBox(),
                      dropdownColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
                      onChanged: (mode) {
                        if (mode != null) settings.updateThemeMode(mode);
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System Default', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark Theme (Default)', style: TextStyle(fontSize: 13)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light Theme', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. Custom Explainer System Prompt Editor
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Custom Explainer System Prompt', Icons.edit_note_rounded, isDark),
                const SizedBox(height: 6),
                Text(
                  'Leave blank to use the default high-performance Hinglish spoken tutor prompt.',
                  style: TextStyle(fontSize: 11.5, color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customPromptController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Optional custom system instructions...',
                    filled: true,
                    fillColor: isDark ? AppColors.darkInputBg : Colors.grey.shade100,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                      ),
                    ),
                  ),
                  onChanged: (val) => settings.updateCustomSystemPrompt(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
          child: DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            underline: const SizedBox(),
            isDense: true,
            dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
            ),
            items: items
                .map((it) => DropdownMenuItem(
                      value: it,
                      child: Text(it),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
