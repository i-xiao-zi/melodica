import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

enum KeyboardMessageType {
  log,
  key,
}

class KeyboardMessage{
  final KeyboardMessageType type;
  final String data;
  const KeyboardMessage(this.type, this.data);
  Map<String, dynamic> toMap() => {
    'type': type,
    'data': data,
  };
  @override
  String toString() => toMap().toString();
}

class GlobalKeyboardListener {
  static bool _started = false;
  static ReceivePort? _receivePort;

  static void start(void Function(KeyboardMessage event)? onEvent) {
    if (_started) return;
    _started = true;

    _receivePort = ReceivePort();
    _receivePort!.listen((message) {
      if (message is KeyboardMessage) {
        onEvent?.call(message);
      }
    });

    Isolate.spawn(_runHookLoop, _receivePort!.sendPort);
  }

  static void _runHookLoop(SendPort sendPort) {
    // HOOKPROC = IntPtr Function(Int32 code, IntPtr wParam, IntPtr lParam)
    final hookCallback = NativeCallable<HOOKPROC>.isolateLocal(
      (int nCode, int wParam, int lParam) =>
          _hookProc(nCode, wParam, lParam, sendPort),
      exceptionalReturn: 0,
    );

    // 安装全局低级键盘钩子（WH_KEYBOARD_LL = 13，全局生效，无需 DLL）
    final hookResult = SetWindowsHookEx(
      WH_KEYBOARD_LL,
      hookCallback.nativeFunction,
      null, // HINSTANCE? 可空：传 null 表示当前模块
      0,
    );
    if (hookResult.error != ERROR_SUCCESS) {
      sendPort.send(KeyboardMessage(KeyboardMessageType.log, '安装钩子失败，错误码: ${hookResult.error}'));
      return;
    }
    final hook = hookResult.value;
    sendPort.send(KeyboardMessage(KeyboardMessageType.log, '钩子已安装，开始监听键盘…'));

    // 消息循环：低级钩子的回调只会在本线程处理消息时被系统调用
    final msg = calloc<MSG>();
    while (true) {
      final result = GetMessage(msg, null, 0, 0);
      if (result.error != ERROR_SUCCESS) break; // GetMessage 出错（-1）
      if (!result.value) break; // WM_QUIT，退出消息循环
      TranslateMessage(msg);
      DispatchMessage(msg);
    }
    calloc.free(msg);
    UnhookWindowsHookEx(hook); // 循环退出后卸载钩子
    hookCallback.close();
  }

  static int _hookProc(int nCode, int wParam, int lParam, SendPort sendPort) {
    if (nCode == HC_ACTION) {
      final info = Pointer<KBDLLHOOKSTRUCT>.fromAddress(lParam).ref;
      final isDown = wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN;
      final isUp = wParam == WM_KEYUP || wParam == WM_SYSKEYUP;
      if (isDown) { //  || isUp
        sendPort.send(KeyboardMessage(KeyboardMessageType.key, _keyName(info.scanCode, info.flags)));
        // sendPort.send(
        //   '${isDown ? '按下' : '抬起'} ${_keyName(info.scanCode, info.flags)}'
        //   ' (vk=0x${info.vkCode.toRadixString(16).padLeft(2, '0')}, '
        //   'scan=${info.scanCode})',
        // );
      }
    }
    return CallNextHookEx(null, nCode, WPARAM(wParam), LPARAM(lParam));
  }

  /// 根据扫描码查询按键名称（如 "A"、"F1"、"Ctrl"）
  static String _keyName(int scanCode, KBDLLHOOKSTRUCT_FLAGS flags) {
    final lParam = (scanCode << 16) |
        (flags.has(LLKHF_EXTENDED) ? 0x01000000 : 0);
    final buf = calloc<Uint16>(256);
    final len = GetKeyNameText(lParam, PWSTR(buf.cast<Utf16>()), 256).value;
    if (len == 0) {
      calloc.free(buf);
      return '(unknown)';
    }
    final sb = StringBuffer();
    for (var i = 0; i < len; i++) {
      sb.writeCharCode((buf + i).value);
    }
    calloc.free(buf);
    return sb.toString();
  }
}
