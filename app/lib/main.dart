import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'constants/app_theme.dart';
import 'constants/strings.dart';
import 'pages/auth/landing_page.dart';
import 'pages/main_page.dart';
import 'providers/auth_provider.dart';
import 'providers/base_provider.dart';
import 'providers/family_provider.dart'; // Import FamilyProvider
import 'providers/fridge_provider.dart';
import 'routes.dart';
import 'services/locator.dart';
import 'services/shared_pref/shared_pref.dart';
import 'utils/translation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SharedPref.init();
  setupLocator();

  final authProvider = AuthProvider();

  await SentryFlutter.init(
    (options) async {
      options.dsn = Strings.dnsSentry;
      await Firebase.initializeApp();
    },
    appRunner: () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => BaseProvider()),
          ChangeNotifierProvider(create: (_) => FridgeProvider()),
          ChangeNotifierProvider(create: (_) => FamilyProvider()), // Register FamilyProvider
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Strings.appName,
      theme: themeData,
      routes: Routes.routes,
      home: const LandingPage(),
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        TranslationsDelegate(),
      ],
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> supportedLocales) {
        if (locale != null) {
          for (Locale supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return supportedLocales.first;
      },
    );
  }
}
