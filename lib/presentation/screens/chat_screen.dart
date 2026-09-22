import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/floating_input_dock.dart';
import 'history_drawer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final settings = context.read<SettingsProvider>();
    final chat = context.read<ChatProvider>();

    _inputController.clear();
    chat.sendMessage(
      text: text,
      apiKey: settings.apiKey,
      customSystemPrompt: settings.customSystemPrompt,
    );

    _scrollToBottom();
  }

  void _applySamplePrompt(String sample) {
    _inputController.text = sample;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sessionTitle = chat.activeSession?.title ?? 'New Explanation';

    return Scaffold(
      key: _scaffoldKey,
      drawer: const HistoryDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'History & Explanations',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                sessionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.chipDarkBg : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.chipDarkBorder : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lock_outline_rounded, size: 10, color: AppColors.textMuted),
                  SizedBox(width: 3),
                  Text(
                    'Private',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'TTS Voice Lab',
            onPressed: () => Navigator.pushNamed(context, '/test_pane'),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'New Explanation',
            onPressed: () => chat.createNewSession(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // API Key warning banner if not configured
            if (!settings.hasApiKey)
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.warning.withAlpha(30),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sarvam API Key not set. Tap here to configure in Settings.',
                          style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.warning),
                    ],
                  ),
                ),
              ),

            // Main Message View / Empty Welcome View
            Expanded(
              child: chat.messages.isEmpty
                  ? _buildEmptyState(context, isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chat.messages[index];
                        return ChatBubble(
                          message: msg,
                          onDelete: () => chat.deleteMessage(msg.id),
                        );
                      },
                    ),
            ),

            // Floating Input Dock pinned at the bottom
            FloatingInputDock(
              controller: _inputController,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accentPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What would you like explained?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Paste articles, markdown tables, documents or financial stats.\nGet structured Hinglish breakdowns + natural spoken audio.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Quick Example Cards
            _buildSamplePromptCard(
              title: 'Pricing Comparison Table',
              description: 'Paste table data to convert into spoken audio narrative',
              icon: Icons.table_chart_rounded,
              sampleText: '''Here is the pricing data to explain:
| Plan | Price | Storage | Users |
| Free | ₹0 | 5 GB | 1 |
| Pro | ₹499/mo | 100 GB | 5 |
| Enterprise | ₹1,999/mo | 1 TB | Unlimited |

Compare these plans and recommend the best one.''',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _buildSamplePromptCard(
              title: 'Complex Technical / Tax Clause',
              description: 'Convert dense numbers and percentages to conversational speech',
              icon: Icons.article_rounded,
              sampleText: '''Please explain this tax clause simply:
"Under Section 80C, deduction up to ₹1,50,000 is allowed. Surcharge of 10% applies if total income exceeds ₹50,00,000 but is under ₹1,00,00,000 [1]. A health & education cess of 4% is levied on income tax plus surcharge."''',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _buildSamplePromptCard(
              title: 'Sarvam Voice Audio Introduction',
              description: 'Experience natural Indian speech synthesis with Bulbul v3',
              icon: Icons.record_voice_over_rounded,
              sampleText: 'Explain how Sarvam AI Bulbul models create natural human-like Indian voice technology in Hindi and Hinglish.',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSamplePromptCard({
    required String title,
    required String description,
    required IconData icon,
    required String sampleText,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _applySamplePrompt(sampleText),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryLight, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
