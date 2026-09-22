import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/google_cloud_tts_client.dart';
import '../../core/api/sarvam_client.dart';
import '../../core/audio/app_audio_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tts/native_tts_service.dart';
import '../../core/utils/text_sanitizer.dart';
import '../../core/utils/tts_normalizer.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../widgets/google_cloud_guide_sheet.dart';

class TtsTestPaneScreen extends StatefulWidget {
  const TtsTestPaneScreen({super.key});

  @override
  State<TtsTestPaneScreen> createState() => _TtsTestPaneScreenState();
}

class _TtsTestPaneScreenState extends State<TtsTestPaneScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController(
    text: 'Agar aap ₹1,00,000 invest karte ho at a YTM of 11.25%, then maturity tak CAGR 12% milega. Iska NAV aur expense ratio compare karein.',
  );

  // Google Cloud state
  final GoogleCloudTtsClient _gcloudClient = GoogleCloudTtsClient();
  String _selectedGcloudFamily = 'All';
  String _selectedGcloudVoice = 'hi-IN-Chirp3-HD-Algenib';
  double _gcloudSpeakingRate = 1.0;
  final double _gcloudPitch = 0.0;
  bool _isGcloudSynthesizing = false;

  // Sarvam state
  final SarvamClient _sarvamClient = SarvamClient();
  String _selectedSarvamSpeaker = 'shubh';
  final String _selectedSarvamModel = 'bulbul:v3';
  double _sarvamPace = 1.0;
  bool _isSarvamSynthesizing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _applyPreset(String text) {
    setState(() {
      _textController.text = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final nativeTts = context.watch<NativeTtsService>();
    final audioController = context.watch<AppAudioController>();

    final inputText = _textController.text;
    final normalizedText = TtsNormalizer.normalizeForNativeTts(inputText);
    final sarvamCleanText = TextSanitizer.sanitizeForAudioSpeech(inputText);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS Voice Lab & Test Pane', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Google Cloud API Key Guide',
            onPressed: () => GoogleCloudGuideSheet.show(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.phone_android_rounded, size: 18), text: 'On-Device (₹0)'),
            Tab(icon: Icon(Icons.cloud_queue_rounded, size: 18), text: 'Google Cloud'),
            Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: 'Sarvam HD'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Text Input Card & Quick Presets
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Test Text Input',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${inputText.length} chars',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quick presets chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip('📈 Finance & YTM', 'Agar aap ₹1,00,000 invest karte ho at a YTM of 11.25%, then maturity tak CAGR 12% milega. Iska NAV aur expense ratio compare karein.'),
                      const SizedBox(width: 8),
                      _buildPresetChip('📑 Tax & Section 80C', 'Under Section 80C, deduction up to ₹1,50,000 is allowed. Surcharge of 10% applies if total income exceeds ₹50,00,000 w/o exemptions.'),
                      const SizedBox(width: 8),
                      _buildPresetChip('📊 Pricing Table', 'Plan Comparison: Pro plan costs ₹499 per month with 100 GB storage. Enterprise plan is ₹1,999 per month for unlimited users.'),
                      const SizedBox(width: 8),
                      _buildPresetChip('🇮🇳 Pure Hindi', 'नमस्ते! यह भारत की सबसे उन्नत और प्राकृतिक AI वॉयस टेक्नोलॉजी है।'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _textController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Enter or paste Hinglish/English text to test...',
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
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),

                // Normalized Pronunciation Script Preview
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF101217) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.spellcheck_rounded, size: 14, color: AppColors.primaryLight),
                          SizedBox(width: 6),
                          Text(
                            'Normalized Spoken Script (for on-device TTS):',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        normalizedText,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. Tab Content View
          SizedBox(
            height: 450,
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: On-Device Native TTS
                _buildNativeTtsTab(context, nativeTts, normalizedText, isDark),

                // TAB 2: Google Cloud TTS
                _buildGoogleCloudTab(context, settings, audioController, normalizedText, isDark),

                // TAB 3: Sarvam Bulbul HD
                _buildSarvamTab(context, settings, audioController, sarvamCleanText, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: Native On-Device ---
  Widget _buildNativeTtsTab(
    BuildContext context,
    NativeTtsService nativeTts,
    String normalizedText,
    bool isDark,
  ) {
    return _buildCard(
      isDark: isDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('₹0 / FREE • UNLIMITED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
              ),
              const Spacer(),
              Text('${nativeTts.indianVoices.length} Indian voices detected', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 12),

          // Engine info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active TTS Engine:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              Text(
                nativeTts.selectedEngine?.replaceAll('com.', '') ?? 'Default Engine',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Voice Picker
          const Text('Select Installed Indian Voice:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          if (nativeTts.indianVoices.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'No specific en-IN/hi-IN voices detected on this device. Using system default voice.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
              ),
              child: DropdownButton<NativeVoiceInfo>(
                value: nativeTts.selectedVoice ?? nativeTts.indianVoices.firstOrNull,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                items: nativeTts.indianVoices.map((v) {
                  final tag = v.isIndianEnglish ? '⭐ en-IN' : 'hi-IN';
                  return DropdownMenuItem(
                    value: v,
                    child: Text('$tag • ${v.name}', style: const TextStyle(fontSize: 12.5)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) nativeTts.setVoice(v);
                },
              ),
            ),

          const SizedBox(height: 12),

          // Speed Rate Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Speech Rate', style: TextStyle(fontSize: 12)),
              Text(nativeTts.speechRate.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Slider(
            value: nativeTts.speechRate,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            activeColor: AppColors.primary,
            onChanged: (val) => nativeTts.setSpeechRate(val),
          ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(nativeTts.isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded),
                  label: Text(nativeTts.isPlaying ? 'Stop Native Speech' : 'Speak with On-Device TTS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nativeTts.isPlaying ? AppColors.error : AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (nativeTts.isPlaying) {
                      nativeTts.stop();
                    } else {
                      nativeTts.speak(text: normalizedText, messageId: 'test_native');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Google Cloud TTS ---
  Widget _buildGoogleCloudTab(
    BuildContext context,
    SettingsProvider settings,
    AppAudioController audioController,
    String textToSpeak,
    bool isDark,
  ) {
    final filteredVoices = _selectedGcloudFamily == 'All'
        ? GoogleCloudTtsClient.availableVoices
        : GoogleCloudTtsClient.availableVoices.where((v) => v.family == _selectedGcloudFamily).toList();

    return _buildCard(
      isDark: isDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('GOOGLE CLOUD • 1M-4M FREE/MO', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => GoogleCloudGuideSheet.show(context),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('Get API Key', style: TextStyle(fontSize: 11.5, color: AppColors.primaryLight)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // API Key Status
          if (!settings.hasGcloudApiKey)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Google Cloud API Key not set. Enter key in Settings.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.warning),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Settings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Voice Family filter
          Wrap(
            spacing: 6,
            children: ['All', 'Chirp3-HD', 'Neural2', 'Wavenet', 'Standard'].map((fam) {
              final isSel = _selectedGcloudFamily == fam;
              return ChoiceChip(
                label: Text(fam, style: const TextStyle(fontSize: 11)),
                selected: isSel,
                selectedColor: AppColors.primary.withAlpha(40),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedGcloudFamily = fam;
                      final list = fam == 'All'
                          ? GoogleCloudTtsClient.availableVoices
                          : GoogleCloudTtsClient.availableVoices.where((v) => v.family == fam).toList();
                      if (list.isNotEmpty) {
                        _selectedGcloudVoice = list.first.name;
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Voice Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInputBg : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            ),
            child: DropdownButton<String>(
              value: filteredVoices.any((v) => v.name == _selectedGcloudVoice)
                  ? _selectedGcloudVoice
                  : filteredVoices.firstOrNull?.name,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              items: filteredVoices.map((v) {
                return DropdownMenuItem(
                  value: v.name,
                  child: Text('${v.name} (${v.ssmlGender})', style: const TextStyle(fontSize: 12.5)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGcloudVoice = val);
              },
            ),
          ),

          const SizedBox(height: 10),

          // Speaking Rate Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Speaking Rate', style: TextStyle(fontSize: 12)),
              Text('${_gcloudSpeakingRate.toStringAsFixed(2)}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Slider(
            value: _gcloudSpeakingRate,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            activeColor: Colors.blue,
            onChanged: (val) => setState(() => _gcloudSpeakingRate = val),
          ),

          // Action Synthesize & Play
          ElevatedButton.icon(
            icon: _isGcloudSynthesizing
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cloud_download_rounded),
            label: Text(_isGcloudSynthesizing ? 'Synthesizing Audio...' : 'Synthesize with Google Cloud'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: (_isGcloudSynthesizing || !settings.hasGcloudApiKey)
                ? null
                : () async {
                    setState(() => _isGcloudSynthesizing = true);
                    try {
                      final selectedVoiceObj = GoogleCloudTtsClient.availableVoices.firstWhere(
                        (v) => v.name == _selectedGcloudVoice,
                        orElse: () => GoogleCloudTtsClient.availableVoices.first,
                      );

                      final path = await _gcloudClient.synthesizeSpeech(
                        apiKey: settings.googleCloudApiKey,
                        text: textToSpeak,
                        voiceName: _selectedGcloudVoice,
                        languageCode: selectedVoiceObj.languageCode,
                        ssmlGender: selectedVoiceObj.ssmlGender,
                        speakingRate: _gcloudSpeakingRate,
                        pitch: _gcloudPitch,
                      );

                      await audioController.playOrPause(
                        messageId: 'gcloud_test_preview',
                        audioPath: path,
                        title: 'Google Cloud ($_selectedGcloudVoice)',
                        subtitle: 'ExplainerAI Test Lab',
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Google Cloud TTS Error: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isGcloudSynthesizing = false);
                    }
                  },
          ),
        ],
      ),
    );
  }

  // --- TAB 3: Sarvam Bulbul HD ---
  Widget _buildSarvamTab(
    BuildContext context,
    SettingsProvider settings,
    AppAudioController audioController,
    String textToSpeak,
    bool isDark,
  ) {
    return _buildCard(
      isDark: isDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('SARVAM BULBUL • PREMIUM HD (~₹3/1K)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
              ),
              const Spacer(),
              Text(
                'Est. Cost: ₹${((textToSpeak.length / 1000) * 3).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Speaker Selection
          const Text('Select Bulbul Voice Speaker:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AppSettings.availableSpeakers.map((sp) {
              final isSel = _selectedSarvamSpeaker.toLowerCase() == sp.id.toLowerCase();
              return ChoiceChip(
                label: Text('${sp.name} (${sp.gender[0]})', style: const TextStyle(fontSize: 11.5)),
                selected: isSel,
                selectedColor: AppColors.primary.withAlpha(50),
                onSelected: (val) {
                  if (val) setState(() => _selectedSarvamSpeaker = sp.id);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // Pace Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Voice Pace / Speed', style: TextStyle(fontSize: 12)),
              Text('${_sarvamPace.toStringAsFixed(2)}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Slider(
            value: _sarvamPace,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _sarvamPace = val),
          ),

          // Action Synthesize & Play
          ElevatedButton.icon(
            icon: _isSarvamSynthesizing
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(_isSarvamSynthesizing ? 'Synthesizing Bulbul Audio...' : 'Synthesize with Sarvam HD'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: (_isSarvamSynthesizing || !settings.hasApiKey)
                ? null
                : () async {
                    setState(() => _isSarvamSynthesizing = true);
                    try {
                      final path = await _sarvamClient.convertTextToSpeech(
                        apiKey: settings.apiKey,
                        text: textToSpeak,
                        speaker: _selectedSarvamSpeaker,
                        model: _selectedSarvamModel,
                        pace: _sarvamPace,
                      );

                      await audioController.playOrPause(
                        messageId: 'sarvam_test_preview',
                        audioPath: path,
                        title: 'Sarvam Bulbul ($_selectedSarvamSpeaker)',
                        subtitle: 'ExplainerAI Test Lab',
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sarvam TTS Error: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSarvamSynthesizing = false);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String presetText) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: AppColors.primary.withAlpha(20),
      side: BorderSide(color: AppColors.primary.withAlpha(60)),
      onPressed: () => _applyPreset(presetText),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: child,
    );
  }
}
