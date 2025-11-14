import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/v2ray_provider.dart';
import 'providers/language_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/privacy_welcome_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/windows_setup_screen.dart';
import 'screens/update_check_wrapper.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('🚀 Starting Tiksar VPN...');
    debugPrint('📱 Platform: ${Platform.operatingSystem}');
    
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        debugPrint('📲 Initializing Firebase for mobile...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        
        final analytics = FirebaseAnalytics.instance;
        await analytics.setAnalyticsCollectionEnabled(true);
        await NotificationService().initialize();
        await analytics.logAppOpen();
        
        debugPrint('✅ Firebase initialized successfully');
      } else {
        debugPrint('💻 Desktop platform detected - skipping Firebase');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Firebase initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    debugPrint('🌐 Initializing language provider...');
    final languageProvider = LanguageProvider();
    await languageProvider.initialize();
    debugPrint('✅ Language provider initialized');

    debugPrint('💾 Loading preferences...');
    final prefs = await SharedPreferences.getInstance();
    final bool languageSelected = prefs.getBool('language_selected') ?? false;
    final bool privacyAccepted = prefs.getBool('privacy_accepted') ?? false;
    debugPrint('✅ Preferences loaded: lang=$languageSelected, privacy=$privacyAccepted');

    debugPrint('🎨 Launching app...');
    runApp(
      MyApp(
        languageSelected: languageSelected,
        privacyAccepted: privacyAccepted, 
        languageProvider: languageProvider
      ),
    );
  }, (error, stackTrace) {
    debugPrint('💥 FATAL ERROR: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  final bool languageSelected;
  final bool privacyAccepted;
  final LanguageProvider languageProvider;

  const MyApp({
    super.key,
    required this.languageSelected,
    required this.privacyAccepted,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ Building MyApp widget...');
    
    List<NavigatorObserver> observers = [];
    final bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
        final FirebaseAnalyticsObserver observer = 
            FirebaseAnalyticsObserver(analytics: analytics);
        observers.add(observer);
      } catch (e) {
        debugPrint('⚠️ Firebase Analytics observer error: $e');
      }
    }
    
    final bool needsSetup = !languageSelected || !privacyAccepted;
    debugPrint('🎯 Platform: ${isDesktop ? 'Desktop' : 'Mobile'}, NeedsSetup: $needsSetup');
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider(
          create: (context) {
            debugPrint('🔧 Creating V2RayProvider...');
            try {
              return V2RayProvider();
            } catch (e, stackTrace) {
              debugPrint('❌ V2RayProvider creation error: $e');
              debugPrint('Stack trace: $stackTrace');
              rethrow;
            }
          },
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, child) {
          debugPrint('🌍 Current language: ${langProvider.currentLanguage.code}');
          
          Widget homeScreen;
          
          try {
            if (isDesktop && needsSetup) {
              debugPrint('📺 Loading WindowsSetupScreen...');
              homeScreen = const WindowsSetupScreen();
            } else if (!languageSelected) {
              debugPrint('🌐 Loading LanguageSelectionScreen...');
              homeScreen = const LanguageSelectionScreen();
            } else if (!privacyAccepted) {
              debugPrint('🔒 Loading PrivacyWelcomeScreen...');
              homeScreen = const PrivacyWelcomeScreen();
            } else {
              debugPrint('🏠 Loading MainNavigationScreen...');
              homeScreen = const MainNavigationScreen();
            }
          } catch (e, stackTrace) {
            debugPrint('❌ Screen selection error: $e');
            debugPrint('Stack trace: $stackTrace');
            homeScreen = _buildErrorScreen(e.toString());
          }
          
          debugPrint('✅ Home screen selected, building MaterialApp...');
          
          return MaterialApp(
            title: 'Tiksar VPN',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme(langProvider.currentLanguage.code),
            locale: langProvider.locale,
            navigatorObservers: observers,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('fa'),
            ],
            home: isDesktop ? homeScreen : UpdateCheckWrapper(child: homeScreen),
            builder: (context, widget) {
              debugPrint('🎨 MaterialApp builder called');
              return widget ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
  
  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'Application Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  debugPrint('🔄 Restarting app...');
                  exit(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
