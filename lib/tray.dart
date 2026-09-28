import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class Tray with TrayListener {
  static final TrayManager tray = TrayManager.instance;
  Tray() {
    tray.setIcon("assets/images/tray.png");
    tray.setToolTip("口风琴");
    tray.setContextMenu(_contextMenu);
    tray.addListener(this);
  }

  Menu get _contextMenu => Menu(
    items: [
      MenuItem(label: '数学'),
      MenuItem.separator(),
      MenuItem(label: '添加曲谱'),
      MenuItem.separator(),
      MenuItem(label: '退出', onClick: _quit),
    ]
  );

  @override
  void onTrayIconMouseDown() {
    tray.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    tray.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  Future<void> _quit(MenuItem item) async {
    await windowManager.close();
  }
}

