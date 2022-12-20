import 'package:flutter/material.dart';
import '../klondike_game.dart';

class MainMenu extends StatelessWidget {
  // Reference to parent game.
  final KlondikeGame game;

  const MainMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    const blackTextColor = Color.fromRGBO(0, 0, 0, 1.0);
    const whiteTextColor = Color.fromRGBO(255, 255, 255, 1.0);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          height: 250,
          width: MediaQuery.of(context).size.width / 3,
          decoration: const BoxDecoration(
            color: blackTextColor,
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Klondike',
                style: TextStyle(
                  color: whiteTextColor,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 10,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        game.overlays.remove('MainMenu');
                        game.isEasy = true;
                        game.initCards();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteTextColor,
                      ),
                      child: const Text(
                        'Easy',
                        style: TextStyle(
                          fontSize: 30.0,
                          color: blackTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 10,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        game.overlays.remove('MainMenu');
                        game.isEasy = true;
                        game.initCards();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteTextColor,
                      ),
                      child: const Text(
                        'Hard',
                        style: TextStyle(
                          fontSize: 30.0,
                          color: blackTextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
