import 'package:agro_stick/l10n/app_localizations.dart';
import 'package:agro_stick/splash_screen/splash_screen.dart';
import 'package:agro_stick/main_home_screen.dart';
import 'package:agro_stick/auth_screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/locale_notifier.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'features/chat/chat_sheet.dart';
import 'ui/chat_visibility.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<bool> chatOpenNotifier = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: AppLocalizations.of(context)?.appTitle ?? 'Agrostick App',
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        primarySwatch: Colors.green,
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          foregroundColor: Colors.white,
        ),
      ),
      builder: (context, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: chatOpenNotifier,
          builder: (context, isChatOpen, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: chatEnabledNotifier,
              builder: (context, chatEnabled, __) {
                return Stack(
                  children: [
                    if (child != null) child,
                    if (chatEnabled && !isChatOpen)
                      Positioned(
                        right: 14,
                        bottom: 86, // just above bottom bar
                        child: GestureDetector(
                          onTap: () async {
                            final ctx = appNavigatorKey.currentContext;
                            if (ctx != null) {
                              chatOpenNotifier.value = true;
                              await showModalBottomSheet(
                                context: ctx,
                                useRootNavigator: true,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                builder: (_) => const ChatSheet(),
                              ).whenComplete(() {
                                chatOpenNotifier.value = false;
                              });
                            }
                          },
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.black,
                            backgroundImage: AssetImage('assets/chatbot_img.png'), // replace with your image path
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
      home: const SplashScreen(),
        );
      },
    );
  }
}

// AuthWrapper no longer used; SplashScreen handles routing after showing splash
