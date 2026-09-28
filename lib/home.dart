import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:melodica/player.dart';
import 'package:melodica/worker.dart';
import 'package:melodica/keyboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _music;
  bool? _playing;
  String _lyric = '';

  @override
  void initState() {
    super.initState();
    windowManager.setAsFrameless();
    windowManager.setSize(Size(150, 300));
    windowManager.setAlignment(Alignment(-0.95, 0));
    windowManager.setBackgroundColor(Colors.transparent);
    Worker.start((message){
      switch (message.type) {
        case WorkerMessageType.complete:
          setState(() {
            _music = null;
            _playing = null;
            _lyric = '';
          });
          break;
        case WorkerMessageType.lyric:
          setState(() {
            _lyric = message.data;
          });
          break;
        default:
      }
    });
    GlobalKeyboardListener.start((KeyboardMessage message){
      Logger().t(message);
      if(message.type == KeyboardMessageType.key) {
        if(['Tab'].contains(message.data)){
          if(_playing == true && _music != null && _music!.isNotEmpty) {
            Worker.send(WorkerMessage(WorkerMessageType.pause, _music));
            setState(() {
              _playing = false;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          ListTile(
            title: Center(child: Text('口风琴', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight(800), color: Colors.white), ),),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
            tileColor: Colors.blue.withAlpha(200),
          ),
          Expanded(
            child: ColoredBox(
              color: Colors.grey.withAlpha(128),
              child: ListView(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                children: ListTile.divideTiles(context: context, tiles: Player.musics.map((music) => Material(
                  color: Colors.transparent,
                  child: ListTile(
                    tileColor: _music == music ? Colors.cyan.withAlpha(128) : null,
                    leading: Icon(_music == music && _playing == true ? Icons.pause : Icons.play_arrow),
                    contentPadding: EdgeInsetsGeometry.symmetric(horizontal: 1.0),
                    title: Text(music),
                    onTap: (){
                      Worker.send(WorkerMessage(_playing == true ? WorkerMessageType.pause : WorkerMessageType.play, music));
                      windowManager.setIgnoreMouseEvents(_playing != true);
                      setState(() {
                        _music = music;
                        _playing = _playing == true ? false : true;
                      });
                    },
                  ),
                ))).toList(),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 20,
            child: Text(_lyric, textAlign: TextAlign.center, style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }
}
