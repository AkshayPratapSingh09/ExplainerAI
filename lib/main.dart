import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'core/audio/app_audio_controller.dart';
import 'core/storage/app_storage.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize System Background Audio Service
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.explainerai.channel.audio',
      androidNotificationChannelName: 'Explainer AI Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    );
  } catch (e) {
    debugPrint('JustAudioBackground init error: $e');
  }

  // System UI overlay styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Local Storage
  final storage = await AppStorage.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storage: storage),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (ctx) {
            final chatProvider = ChatProvider(storage: storage);
            final settings = ctx.read<SettingsProvider>().settings;
            chatProvider.syncDefaultsWithSettings(settings);
            return chatProvider;
          },
        ),
        ChangeNotifierProvider<AppAudioController>(
          create: (_) => AppAudioController(),
        ),
      ],
      child: const ExplainerAIApp(),
    ),
  );
}

class ExplainerAIApp extends StatelessWidget {
  const ExplainerAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Explainer AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
