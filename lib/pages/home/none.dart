import 'dart:isolate';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../player.dart';
import '../../worker.dart';

class WindowSize {
  static Size mini    = Size(50, 50);
  static Size middle  = Size(300, 50);
  static Size full    = Size(300, 400);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Size _windowSize = WindowSize.mini;
  late SendPort _sender;
  final ReceivePort _receiver = ReceivePort();
  Isolate? _isolate;

  @override
  void initState() {
    super.initState();
    windowManager.setAsFrameless();
    windowManager.setSize(WindowSize.mini);
    windowManager.setBackgroundColor(Colors.transparent);
    _startWorker();
  }

  Future<void> _startWorker() async {

    // _isolate = await Isolate.spawn(workerEntryPoint, _receiver.sendPort);
    // _receiver.listen((message) {
    //   if (message is SendPort) {
    //     _sender = message;
    //   }
    //   Logger().t(message);
    // });

  }
  Future<void> onEnter(PointerEnterEvent event) async {
    await windowManager.setSize(WindowSize.full);
    setState(() {
      _windowSize = WindowSize.full;
    });
  }
  Future<void> onExit(PointerExitEvent event) async {
    setState(() {
      _windowSize = WindowSize.mini;
    });
    Future.delayed(Duration(seconds: 2), () async {
      await windowManager.setSize(WindowSize.mini);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MouseRegion(
        onEnter: onEnter,
        onExit: onExit,
        child: AnimatedContainer(
          decoration: BoxDecoration(
            borderRadius:BorderRadius.circular( _windowSize == WindowSize.mini ? 40: 15,),
            color: Colors.purple,
          ),
          duration: Duration(seconds: 1),
          width: _windowSize.width,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.music_note),
                  Visibility(
                    visible: _windowSize != WindowSize.mini,
                    child: FutureBuilder(
                      future: Future.delayed(Duration(seconds: 1)),
                      builder: (context, snapshot){
                        Logger().t(snapshot.data);
                        // setState(() {
                        //   _windowSize = WindowSize.full;
                        // });
                        return Expanded(child: Text('口风琴'));
                      },
                    ),
                  ),
                ],
              ),
              // Visibility(
              //   visible: _windowSize == WindowSize.full,
              //   child: Expanded(
              //     child: ListView.builder(
              //       scrollDirection: Axis.vertical,
              //       shrinkWrap: true,
              //       itemCount: Player.musics.length,
              //       itemBuilder: (BuildContext context, int index) {
              //         final music = Player.musics[index];
              //         return ListTile(
              //           leading: Icon(Icons.music_note),
              //           trailing: IconButton(
              //             onPressed: (){},
              //             icon: Icon(Icons.play_arrow),
              //           ),
              //           title: Text(music),
              //           onTap: (){
              //             final player = Player();
              //             player.parse(music);
              //           },
              //         );
              //       },
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
