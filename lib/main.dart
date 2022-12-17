import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'klondike_game.dart';
import 'package:flame_splash_screen/flame_splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreenGame(),
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreenGame extends StatefulWidget {
  const SplashScreenGame({super.key});

  @override
  SplashScreenGameState createState() => SplashScreenGameState();
}

class SplashScreenGameState extends State<SplashScreenGame> {
  late FlameSplashController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlameSplashScreen(
        showBefore: (BuildContext context) {
          return Image.asset('assets/images/logo-no-background.png');
        },
        // showAfter: (BuildContext context) {
        //   return const Text('After logo');
        // },
        theme: FlameSplashTheme.dark,
        onFinish: (context) => Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(
              builder: (context) => GameWidget(game: KlondikeGame())),
        ),
      ),
    );
  }
}
