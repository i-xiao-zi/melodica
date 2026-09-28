import 'package:flutter/material.dart';
import 'package:melodica/tray.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions options = const WindowOptions(
    size: Size(800, 600),
    title: '口风琴',
    alwaysOnTop: true,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(1,1),
    backgroundColor: Colors.transparent,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  Tray();
  runApp(const App());
}