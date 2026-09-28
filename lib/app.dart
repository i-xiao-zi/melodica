import 'package:flutter/material.dart';
import 'package:melodica/theme.dart';
import 'package:melodica/home.dart';


class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: HomePage(),
    );
  }
}

