import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_colors.dart';
import 'core/app_theme.dart';
import 'data/app_state.dart';
import 'screens/onboarding/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.cream,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(KaamSaathiApp(state: AppState()..init()));
}

class KaamSaathiApp extends StatelessWidget {
  const KaamSaathiApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'KaamSaathi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('hi', 'IN'),
        supportedLocales: const [Locale('hi', 'IN'), Locale('en', 'IN')],
        // Required for a non-English locale: provides Hindi Material/Cupertino
        // strings (back tooltip, etc.) — without these AppBar throws.
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // Keep text readable even when the phone uses a very large font scale.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3)),
            child: child!,
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
