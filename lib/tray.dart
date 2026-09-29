import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class Tray with TrayListener {
  static final TrayManager tray = TrayManager.instance;
  Tray() {
    tray.setIcon("assets/images/tray.png");
    tray.setToolTip("口风琴");
    tray.setContextMenu(_contextMenu);
    tray.addListener(this);
    Logger().t(Image.asset('assets/images/tray.png'));
  }

  Menu get _contextMenu => Menu(
    items: [
      MenuItem(label: '主页', onClick: _hide, icon: 'assets/images/home.png'),
      MenuItem.separator(),
      MenuItem(label: '退出', onClick: _quit),
    ]
  );

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    tray.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  Future<void> _hide(MenuItem item) async {
    if(await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await windowManager.show();
    }
  }

  Future<void> _quit(MenuItem item) async {
    await windowManager.close();
  }
}

