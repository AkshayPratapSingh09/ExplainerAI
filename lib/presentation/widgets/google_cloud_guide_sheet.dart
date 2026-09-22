import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class GoogleCloudGuideSheet extends StatelessWidget {
  const GoogleCloudGuideSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const GoogleCloudGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_queue_rounded, color: Colors.blue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Cloud TTS API Key Guide',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                        ),
                      ),
                      const Text(
                        'Free 1M-4M chars/month included',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
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
                _buildStepCard(
                  step: 1,
                  title: 'Go to Google Cloud Console',
                  description: 'Open console.cloud.google.com in your browser and sign in with your Google account. (New users get \$300 free credits).',
                  actionText: 'Copy Console URL',
                  onAction: () {
                    Clipboard.setData(const ClipboardData(text: 'https://console.cloud.google.com/'));
                    _showToast(context, 'Copied https://console.cloud.google.com/');
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                _buildStepCard(
                  step: 2,
                  title: 'Create or Select a Project',
                  description: 'Click the project dropdown at the top navigation bar and click "New Project". Give it a name like "ExplainerAI-TTS".',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                _buildStepCard(
                  step: 3,
                  title: 'Enable Cloud Text-to-Speech API',
                  description: 'In the search bar, search for "Cloud Text-to-Speech API" and click "Enable".',
                  actionText: 'Copy API Page URL',
                  onAction: () {
                    Clipboard.setData(const ClipboardData(
                      text: 'https://console.cloud.google.com/apis/library/texttospeech.googleapis.com',
                    ));
                    _showToast(context, 'Copied Cloud TTS Library URL');
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                _buildStepCard(
                  step: 4,
                  title: 'Create API Key',
                  description: 'Navigate to "APIs & Services" > "Credentials". Click "+ CREATE CREDENTIALS" at the top and select "API key".',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                _buildStepCard(
                  step: 5,
                  title: 'Paste Key into ExplainerAI',
                  description: 'Copy your generated API Key (starts with "AIza...") and paste it into the Google Cloud API Key field in ExplainerAI Settings or Test Lab.',
                  isDark: isDark,
                ),

                const SizedBox(height: 18),

                // Pricing Tip Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withAlpha(80)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline_rounded, color: Colors.green, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '💡 Google Cloud Free Tier provides 4 million characters/month for Standard voices and 1 million characters/month for WaveNet / Neural2 voices for free every single month.',
                          style: TextStyle(fontSize: 12, height: 1.45, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got It, Close Guide', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String description,
    String? actionText,
    VoidCallback? onAction,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary,
                child: Text(
                  '$step',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primaryLight),
                label: Text(actionText, style: const TextStyle(fontSize: 11.5, color: AppColors.primaryLight)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.primary.withAlpha(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
