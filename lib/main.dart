import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_shell.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web & Desktop SQLite initialization
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Device Preview configuration:
  // - Defaults to true on Web (for instant mobile testing in Chrome)
  // - Defaults to false on native Desktop (runs standard native Windows app)
  // - Can be explicitly overridden with --dart-define=PREVIEW=true / false
  const previewEnv = bool.hasEnvironment('PREVIEW')
      ? bool.fromEnvironment('PREVIEW')
      : kIsWeb;

  runApp(
    DevicePreview(
      enabled: !kReleaseMode && previewEnv,
      defaultDevice: Devices.ios.iPhone13ProMax,
      builder: (context) => ProviderScope(
        child: OpenFantacalcioApp(useDevicePreview: previewEnv),
      ),
    ),
  );
}

class OpenFantacalcioApp extends ConsumerWidget {
  final bool useDevicePreview;
  const OpenFantacalcioApp({super.key, this.useDevicePreview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      locale: useDevicePreview ? DevicePreview.locale(context) : locale,
      builder: useDevicePreview ? DevicePreview.appBuilder : null,
      title: 'Open Fantacalcio Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      supportedLocales: const [
        Locale('it'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}
