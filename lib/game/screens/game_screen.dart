import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../main_game.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/score_overlay.dart';
import '../style/game_style.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB), // Light sky blue
              Color(0xFF1976D2), // Medium blue
            ],
          ),
        ),
        child: GameWidget<SleepySheepGame>(
          game: SleepySheepGame(),
          overlayBuilderMap: {
            'gameOver': (context, game) => GameOverOverlay(game: game),
            'score': (context, game) => ScoreOverlay(game: game),
          },
          loadingBuilder: (context) => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Loading Sleepy Sheep...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          backgroundBuilder: (context) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF87CEEB), // Light sky blue
                  Color(0xFF1976D2), // Medium blue
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
