import 'package:flutter/material.dart';
import '../main_game.dart';
import '../style/game_style.dart';

class ScoreOverlay extends StatelessWidget {
  final SleepySheepGame game;

  const ScoreOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Score display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: GameStyle.scoreYellow,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    ValueListenableBuilder<int>(
                      valueListenable: game.scoreNotifier,
                      builder: (context, score, child) {
                        return Text(
                          score.toString(),
                          style: GameStyle.scoreStyle,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Back button
              GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .pop(); // Navigate back to previous screen
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),

              // Pause button
              GestureDetector(
                onTap: () {
                  if (game.isGameOver) return;

                  if (game.isPaused) {
                    game.resumeGame();
                  } else {
                    game.pauseGame();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: game.pausedNotifier,
                    builder: (context, isPaused, child) {
                      return Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 30,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
