import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'constants/strings.dart';
import 'pages/auth/landing_page.dart';
import 'pages/main_page.dart';
import 'providers/auth_provider.dart';
import 'providers/base_provider.dart';
import 'providers/family_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/fridge_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/shopping_list_provider.dart';
import 'providers/meal_plan_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/product_provider.dart';
import 'providers/admin_user_provider.dart';
import 'providers/admin_category_provider.dart';
import 'providers/admin_product_provider.dart';
import 'routes.dart';
import 'services/locator.dart';
import 'services/shared_pref/shared_pref.dart';
import 'utils/translation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupLocator();
  await SharedPref.init();

  final authProvider = AuthProvider()..loadUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => BaseProvider()),
        ChangeNotifierProvider(create: (_) => FridgeProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingListProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
        ChangeNotifierProvider(create: (_) => AdminCategoryProvider()),
        ChangeNotifierProvider(create: (_) => AdminProductProvider()),
      ],
      child: const MyApp(),
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
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (auth.isLoggedIn) {
            return const MainPage();
          } else {
            return const LandingPage();
          }
        },
      ),
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
