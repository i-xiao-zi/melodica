import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';
import 'package:melodica/player.dart';
import 'package:win32/win32.dart';

class WorkerTask {
  final int id;
  final String text;
  WorkerTask(this.id, this.text);
}

class WorkerResult {
  final int id;
  WorkerResult(this.id);
}

enum WorkerMessageType {
  log,
  play,
  pause,
  complete,
  lyric,
  key,
}

class WorkerMessage {
  final WorkerMessageType type;
  final dynamic data;
  const WorkerMessage(this.type, this.data);
  Map<String, dynamic> toMap() => {
    'type': type,
    'data': data,
  };
  @override
  String toString() => toMap().toString();
}

class Worker {
  static bool _started = false;
  static SendPort? receiver;
  static ReceivePort port = ReceivePort();
  static void start(void Function(WorkerMessage)? onData) {
    if (_started) return;
    _started = true;
    port.listen((message){
      if(message is SendPort) {
        receiver = message;
      }
      if(message is WorkerMessage) {
        onData?.call(message);
      }
    });
    Isolate.spawn(_entry, port.sendPort);
  }

  static void send(WorkerMessage message){
    receiver?.send(message);
  }
  static void _entry(SendPort sender){
    final port = ReceivePort();
    sender.send(port.sendPort);
    port.listen((message) async {
      if (message is WorkerMessage) {
        switch (message.type) {
          case WorkerMessageType.play:
            Player.play(message.data);
            break;
          case WorkerMessageType.pause:
            Player.pause(message.data);
            break;
          default:
        }
      }
    });
    sender.send(port.sendPort);
    Player.sender = sender;
  }
}