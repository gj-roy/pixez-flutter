import 'package:bot_toast/bot_toast.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:pixez/constants.dart';
import 'package:pixez/main.dart';
import 'package:pixez/page/fluent/splash/splash_page.dart';
import 'package:pixez/platform/platform.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'er/leader.dart';

Color? _fluentuiBgColor = null;
AccentColor? _accentColor;

initFluent(List<String> args) async {
  Constants.isFluent = true;
  await singleInstance(
    args,
    "Pixez::{fe97f8e1-32e5-44ec-9bfb-cde274b87f61}",
    (args) {
      debugPrint("从另一实例接收到的参数: $args");
      _argsParser(args);
    },
  );
  final dbPath = await getDBPath();
  if (dbPath != null) databaseFactory.setDatabasesPath(dbPath);

  final effect = await getEffect();
  final isDark = await useDarkTheme();
  final accent = await getAccentColor();

  if (effect != WindowEffect.disabled)
    await windowManager.setBackgroundColor(
      _fluentuiBgColor = Colors.transparent,
    );

  _accentColor = accent.toAccentColor();

  debugPrint("背景特效: $effect; 暗色主题: $isDark; 强调色: $accent");

  // Must add this line.
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      center: true,
      skipTaskbar: false,
      minimumSize: const Size(350, 600),
    ),
    () async {
      await Window.initialize();
      await Window.setEffect(
        effect: effect,
        dark: isDark,
      );

      await windowManager.show();
      await windowManager.focus();
    },
  );
}

// 解析命令行参数字符串
_argsParser(List<String> args) async {
  if (args.length < 1) return;

  final uri = Uri.tryParse(args[0]);
  if (uri != null) {
    debugPrint("::_argsParser(): 合法的Uri: \"${uri}\"");
    Leader.pushWithUri(routeObserver.navigator!.context, uri);
  }
}

Widget buildFluentUI(BuildContext context) {
  return Observer(builder: (context) {
    final botToastBuilder = BotToastInit();
    return FluentApp(
      home: Builder(builder: (context) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(statusBarColor: _fluentuiBgColor),
          child: SplashPage(),
        );
      }),
      builder: (context, child) {
        child = botToastBuilder(context, child);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: NavigationPaneTheme(
            data: NavigationPaneThemeData(backgroundColor: _fluentuiBgColor),
            child: child,
          ),
        );
      },
      title: 'PixEz',
      locale: userSetting.locale,
      navigatorObservers: [
        BotToastNavigatorObserver(),
        routeObserver,
      ],
      themeMode: userSetting.themeMode,
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        visualDensity: VisualDensity.standard,
        accentColor: _accentColor,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      theme: FluentThemeData(
        brightness: Brightness.light,
        visualDensity: VisualDensity.standard,
        accentColor: _accentColor,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      localizationsDelegates: [
        _FluentLocalizationsDelegate(),
        ...AppLocalizations.localizationsDelegates
      ],
      supportedLocales: AppLocalizations.supportedLocales, // Add this line
    );
  });
}

class _FluentLocalizationsDelegate
    extends LocalizationsDelegate<FluentLocalizations> {
  const _FluentLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.contains(locale);
  }

  @override
  Future<FluentLocalizations> load(Locale locale) {
    return FluentLocalizations.delegate.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<FluentLocalizations> old) {
    return false;
  }
}
