import 'dart:isolate';

import 'package:logger/logger.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:melodica/worker.dart';
import 'package:win32/win32.dart';
import 'package:path/path.dart';
import 'dart:io';

class ScoreToken {
  final List<String> mods;
  final String? key;
  final int ms;
  final bool isPause;
  ScoreToken({required this.mods, this.key, required this.ms, required this.isPause});
}

class ScoreLine {
  final List<ScoreToken> tokens;
  final String lyric;
  ScoreLine({required this.tokens, required this.lyric});
}

class Player {
  static DateTime? _time;
  static SendPort? _sender;
  static set sender(SendPort sender) {
    _sender = sender;
  }
  static String name = '';
  static bool playing = true;
  // 当前按住状态
  static String? _activeKey;
  static List<String> _activeMods = [];

  static Future<void> _start(DateTime time) async {
    await Future.delayed(Duration(seconds: 2));
    File(Platform.resolvedExecutable).parent;
    final lines = await _musicFile(name).readAsLines();
    for(String line in lines) {
      if(_time != time) {
        return;
      }
      line = line.trim();
      if (line.isEmpty) continue;
      final parts = line.split('|');
      final score = parts[0].trim();
      final lyric = parts.length > 1 ? parts[1].trim() : '';
      if (score.isEmpty) continue;
      final rawTokens = score.split(RegExp(r'\s+'));
      final tokenList = <ScoreToken>[];
      for(final raw in rawTokens) {
        if(raw.startsWith('0(')){
          // 停顿 0(500)
          final m = RegExp(r'^0\((\d+)\)$').firstMatch(raw);
          final ms = int.parse(m!.group(1)!);
          tokenList.add(ScoreToken(mods: [], key:null, ms:ms, isPause:true));
          continue;
        }
        final m = RegExp(r'^([\^_#]*)([1-7])\((\d+)\)$').firstMatch(raw);
        if(m == null) {
          Logger().w("无法解析token $raw");
          continue;
        }
        final mods = m.group(1)!.split('').toList();
        final key = m.group(2)!;
        final ms = int.parse(m.group(3)!);
        tokenList.add(ScoreToken(mods: mods, key:key, ms:ms, isPause:false));
      }
      await _execute(ScoreLine(tokens:tokenList, lyric:lyric), time);
    }
    _releaseAll();
    _sender?.send(WorkerMessage(WorkerMessageType.complete, name));
    playing = false;
    name = '';
    _time = null;
  }
  static void _releaseAll() {
    if (_activeKey != null) {
      _sendKey(_activeKey!, true);
    }
    for (final m in _activeMods) {
      _sendMouse(m, true);
    }
    _activeKey = null;
    _activeMods.clear();
  }

  static Future<void> _execute(ScoreLine score, DateTime time) async {
    _sender?.send(WorkerMessage(WorkerMessageType.lyric, score.lyric));
    for(final token in score.tokens){
      while(!playing) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      if(_time != time) {
        return;
      }
      if(token.isPause){
        _releaseAll();
        await Future.delayed(Duration(milliseconds: token.ms));
        continue;
      }
      // 新音符，释放旧音
      _releaseAll();
      // 按下修饰键
      for(final mod in token.mods){
        _sendMouse(mod, false);
      }
      await Future.delayed(Duration(milliseconds:20));
      // 按下主键
      _sendKey(token.key!, false);
      _activeKey = token.key;
      _activeMods = token.mods;
      // 保持指定时长
      await Future.delayed(Duration(milliseconds: token.ms));
      // 播放完这个音，释放
      _releaseAll();
    }
    // await Future.delayed(Duration(milliseconds: 500));
  }

  static VIRTUAL_KEY _getKey(String key) {
    return {
      '1': VK_Z,
      '2': VK_X,
      '3': VK_C,
      '4': VK_V,
      '5': VK_B,
      '6': VK_N,
      '7': VK_M,
    }[key] as VIRTUAL_KEY;
  }
  static MOUSE_EVENT_FLAGS _getFlag(String flag, bool up) {
    return (up ? {
      '^': MOUSEEVENTF_RIGHTUP,
      '_': MOUSEEVENTF_LEFTUP,
      '#': MOUSEEVENTF_MIDDLEUP,
    } : {
      '^': MOUSEEVENTF_RIGHTDOWN,
      '_': MOUSEEVENTF_LEFTDOWN,
      '#': MOUSEEVENTF_MIDDLEDOWN,
    })[flag] as MOUSE_EVENT_FLAGS;
  }

  static void _sendKey(String key, bool up) {
    final input = calloc<INPUT>();
    input.ref.type = INPUT_KEYBOARD;
    input.ref.ki.wVk = VIRTUAL_KEY(0);
    input.ref.ki.wScan = MapVirtualKey(_getKey(key), MAPVK_VK_TO_VSC);
    input.ref.ki.dwFlags = KEYEVENTF_SCANCODE;
    if(up) {
      input.ref.ki.dwFlags |= KEYEVENTF_KEYUP;
    }
    SendInput(1, input, sizeOf<INPUT>());
    calloc.free(input);
  }

  static void _sendMouse(String mod, bool up) {
    final input = calloc<INPUT>();
    input.ref.type = INPUT_MOUSE;
    input.ref.mi.dx = 0;
    input.ref.mi.dy = 0;
    input.ref.mi.mouseData = 0;
    input.ref.mi.dwFlags = _getFlag(mod, up);
    input.ref.mi.time = 0;
    input.ref.mi.dwExtraInfo = 0;
    SendInput(1, input, sizeOf<INPUT>());
    calloc.free(input);
  }

  static File _musicFile(String file){
    return File(join(_musicDir.path, file));
  }
  static Future<void> play(String music) async {
    if(name != music) {
      name = music;
      _time = DateTime.now();
      _start(_time!);
    }
    playing = true;
  }
  static void pause(String? name) {
    playing = false;
  }
  static Directory get _musicDir => Directory(join(File(Platform.resolvedExecutable).parent.path, 'music'));
  static List<String> get musics => _musicDir.listSync().map((f) => basename(f.path)).toList();
  static Stream<bool?> stream(String music) async* {
    while(true) {
      await Future.delayed(Duration(milliseconds: 300));
      yield name == music ? playing : null;
    }
  }
}
