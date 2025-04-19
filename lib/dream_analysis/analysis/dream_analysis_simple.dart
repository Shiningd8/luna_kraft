import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/backend/backend.dart';
import 'package:intl/intl.dart';

class DreamAnalysisSimple extends StatefulWidget {
  const DreamAnalysisSimple({super.key});

  @override
  State<DreamAnalysisSimple> createState() => _DreamAnalysisSimpleState();
}

class _DreamAnalysisSimpleState extends State<DreamAnalysisSimple> {
  bool _isLoading = true;
  String? _error;
  AnalysisResults? _analysisResults;
  final currentUser = FirebaseAuth.instance.currentUser;
  Future<QuerySnapshot>? _dreamsFuture;
  bool _disposed = false;
  late FlutterFlowTheme _theme;

  @override
  void initState() {
    super.initState();
    _dreamsFuture = _fetchDreams();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache the theme
    _theme = FlutterFlowTheme.of(context);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<QuerySnapshot> _fetchDreams() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('date', descending: true)
        .limit(100)
        .get();
  }

  Future<void> _refreshDreams() async {
    if (!_disposed) {
      setState(() {
        _dreamsFuture = _fetchDreams();
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050A30),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Dream Analysis',
          style: _theme.headlineMedium.override(
            fontFamily: 'Figtree',
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (!_disposed) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshDreams,
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _dreamsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error loading dreams: ${snapshot.error}');
            return _buildErrorState('Error loading dreams: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return _buildLoadingState();
          }

          // Filter dreams for current user
          final userDreams = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['uid'] == currentUser!.uid ||
                data['userId'] == currentUser!.uid ||
                data['user_id'] == currentUser!.uid ||
                (data['userref'] is DocumentReference &&
                    data['userref'].path.contains(currentUser!.uid)) ||
                (data['poster'] is DocumentReference &&
                    data['poster'].path.contains(currentUser!.uid));
          }).toList();

          // Convert to DreamData objects
          final dreams = userDreams
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final date = data['date'] is Timestamp
                    ? (data['date'] as Timestamp).toDate()
                    : DateTime.now();

                String emotion = 'Unknown';
                if (data['themes'] != null &&
                    data['themes'].toString().isNotEmpty) {
                  emotion = data['themes'].toString();
                } else if (data['Tags'] != null &&
                    data['Tags'].toString().isNotEmpty) {
                  emotion = data['Tags'].toString();
                }

                String dreamContent = '';
                if (data['Dream'] != null &&
                    data['Dream'].toString().isNotEmpty) {
                  dreamContent = data['Dream'].toString();
                } else if (data['dream'] != null &&
                    data['dream'].toString().isNotEmpty) {
                  dreamContent = data['dream'].toString();
                }

                if (dreamContent.isNotEmpty) {
                  return DreamData(
                    date: date,
                    emotion: emotion,
                    dream: dreamContent,
                  );
                }
                return null;
              })
              .where((dream) => dream != null)
              .cast<DreamData>()
              .toList();

          if (dreams.isEmpty) {
            return Center(
              child: Text(
                'No dreams found. Start by adding some dreams!',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // Sort dreams by date (newest first)
          dreams.sort((a, b) => b.date.compareTo(a.date));

          // Take exactly 10 dreams or all if less than 10
          final analyzeDreams = dreams.take(10).toList();

          // Analyze the dreams
          if (_isLoading || analyzeDreams.isNotEmpty) {
            _analyzeDreams(analyzeDreams).then((results) {
              _safeSetState(() {
                _analysisResults = results;
                _isLoading = false;
              });
            }).catchError((error) {
              print('Analysis error: $error');
              _safeSetState(() {
                _error = error.toString();
                _isLoading = false;
              });
            });
          }

          if (_isLoading) {
            return _buildLoadingState();
          }

          if (_error != null) {
            return _buildErrorState(_error!);
          }

          return _buildAnalysisContent();
        },
      ),
    );
  }

  Future<AnalysisResults> _analyzeDreams(List<DreamData> dreams) async {
    // Define more meaningful dream themes and their variations
    final Map<String, List<String>> themeKeywords = {
      'Flying': [
        'fly',
        'flying',
        'soar',
        'soaring',
        'air',
        'sky',
        'float',
        'levitate',
        'wings',
        'bird-like'
      ],
      'Falling': [
        'fall',
        'falling',
        'drop',
        'plummet',
        'descent',
        'tumbling',
        'gravity',
        'weightless'
      ],
      'Water': [
        'water',
        'ocean',
        'sea',
        'river',
        'lake',
        'swim',
        'drowning',
        'beach',
        'shore',
        'waves',
        'underwater',
        'submerged'
      ],
      'Lucid': [
        'realize',
        'aware',
        'conscious',
        'control',
        'lucid',
        'knew I was dreaming',
        'could change',
        'reality check'
      ],
    };

    // Analyze each dream for themes and extract relevant excerpts
    Map<String, List<DreamExcerpt>> themeExcerpts = {};
    for (var dream in dreams) {
      for (var theme in themeKeywords.entries) {
        for (var keyword in theme.value) {
          if (dream.dream.toLowerCase().contains(keyword.toLowerCase())) {
            // Find the sentence containing the keyword
            final sentences = dream.dream.split(RegExp(r'[.!?]+'));
            for (var sentence in sentences) {
              if (sentence.toLowerCase().contains(keyword.toLowerCase())) {
                // Find surrounding context (previous and next sentence if available)
                int sentenceIndex = sentences.indexOf(sentence);
                String context = '';

                // Add previous sentence for context if available
                if (sentenceIndex > 0) {
                  context += sentences[sentenceIndex - 1].trim() + '. ';
                }

                // Add current sentence
                context += sentence.trim() + '. ';

                // Add next sentence for context if available
                if (sentenceIndex < sentences.length - 1) {
                  context += sentences[sentenceIndex + 1].trim() + '. ';
                }

                themeExcerpts.putIfAbsent(theme.key, () => []);
                themeExcerpts[theme.key]!.add(
                  DreamExcerpt(
                    excerpt: context.trim(),
                    date: dream.date,
                    analysis: _generateThemeAnalysis(theme.key, context),
                  ),
                );
                break; // Found relevant excerpt for this keyword
              }
            }
          }
        }
      }
    }

    // Generate meaningful analysis for each theme
    Map<String, dynamic> themeAnalysis = {};
    for (var theme in themeExcerpts.entries) {
      if (theme.value.isNotEmpty) {
        themeAnalysis[theme.key] = {
          'frequency': theme.value.length,
          'examples': theme.value
              .take(2)
              .map((e) => {
                    'excerpt': e.excerpt,
                    'date': e.date,
                    'analysis': e.analysis,
                  })
              .toList(),
        };
      }
    }

    // Set default emotions if missing
    for (var i = 0; i < dreams.length; i++) {
      if (dreams[i].emotion.isEmpty || dreams[i].emotion == 'Unknown') {
        // Text analysis to determine emotions from dream content
        final String dreamText = dreams[i].dream.toLowerCase();
        String determinedEmotion = 'Neutral';

        // Advanced emotion detection with comprehensive vocabulary and context awareness
        final Map<String, List<String>> emotionKeywords = {
          'Fear': [
            'afraid',
            'fear',
            'scary',
            'terrified',
            'terrifying',
            'horror',
            'dread',
            'panic',
            'frightened',
            'scared',
            'phobia',
            'terror',
            'alarmed',
            'spooked',
            'nightmare',
            'threatened',
            'intimidated',
            'trembling'
          ],
          'Joy': [
            'happy',
            'joy',
            'delighted',
            'excited',
            'cheerful',
            'ecstatic',
            'elated',
            'pleased',
            'thrilled',
            'blissful',
            'overjoyed',
            'jubilant',
            'gleeful',
            'celebrating',
            'laughing',
            'smiling',
            'enchanted',
            'radiant',
            'beaming'
          ],
          'Sadness': [
            'sad',
            'grief',
            'somber',
            'depressed',
            'melancholy',
            'gloomy',
            'sorrowful',
            'downcast',
            'miserable',
            'heartbroken',
            'tearful',
            'crying',
            'weeping',
            'mourning',
            'despair',
            'despondent',
            'forlorn',
            'downhearted',
            'blue'
          ],
          'Anxiety': [
            'anxious',
            'worry',
            'nervous',
            'stress',
            'uneasy',
            'apprehensive',
            'tense',
            'distressed',
            'fretting',
            'concerned',
            'restless',
            'agitated',
            'jittery',
            'troubled',
            'preoccupied',
            'fretful',
            'on edge',
            'disquieted',
            'disturbed'
          ],
          'Confusion': [
            'confused',
            'uncertainty',
            'puzzled',
            'bewildered',
            'perplexed',
            'disoriented',
            'unsure',
            'unclear',
            'ambiguous',
            'baffled',
            'muddled',
            'lost',
            'disarray',
            'foggy',
            'jumbled',
            'chaotic',
            'mystified',
            'bemused',
            'questioning'
          ],
          'Peace': [
            'calm',
            'peace',
            'tranquil',
            'serene',
            'relaxed',
            'content',
            'harmony',
            'quiet',
            'still',
            'composed',
            'soothing',
            'gentle',
            'comfort',
            'ease',
            'placid',
            'collected',
            'untroubled',
            'balanced',
            'zen'
          ],
          'Wonder': [
            'curious',
            'wonder',
            'fascinated',
            'amazed',
            'astonished',
            'awe',
            'marvel',
            'intrigued',
            'spellbound',
            'captivated',
            'mesmerized',
            'enthralled',
            'surprised',
            'stunned',
            'dazzled',
            'mystified',
            'impressed',
            'inquisitive',
            'interested'
          ],
          'Anger': [
            'angry',
            'furious',
            'rage',
            'mad',
            'irritated',
            'annoyed',
            'enraged',
            'hostile',
            'bitter',
            'upset',
            'temper',
            'irate',
            'outraged',
            'indignant',
            'frustrated',
            'fuming',
            'incensed',
            'livid',
            'infuriated'
          ],
          'Love': [
            'love',
            'affection',
            'passion',
            'romantic',
            'adoration',
            'fond',
            'cherish',
            'infatuation',
            'tenderness',
            'devotion',
            'attachment',
            'intimate',
            'desire',
            'caring',
            'compassion',
            'warmth',
            'attracted',
            'enamored',
            'smitten'
          ],
          'Disgust': [
            'disgust',
            'repulsed',
            'nauseated',
            'revolted',
            'sickened',
            'offended',
            'appalled',
            'abhorrence',
            'aversion',
            'distaste',
            'dislike',
            'repugnance',
            'loathing',
            'revulsion',
            'abomination',
            'contempt',
            'disdain',
            'horror',
            'hatred'
          ]
        };

        // Score each emotion
        Map<String, int> emotionScores = {};

        for (var emotion in emotionKeywords.keys) {
          int score = 0;
          for (var keyword in emotionKeywords[emotion]!) {
            if (dreamText.contains(keyword)) {
              score++;

              // Check for intensifiers
              final intensifiers = [
                'very',
                'extremely',
                'incredibly',
                'deeply',
                'profoundly',
                'utterly'
              ];
              for (var intensifier in intensifiers) {
                if (dreamText.contains('$intensifier $keyword')) {
                  score += 2; // Extra weight for intensified emotions
                }
              }

              // Check for negation (simple implementation)
              final negationPatterns = [
                'not $keyword',
                'didn\'t $keyword',
                'wasn\'t $keyword',
                'no $keyword'
              ];
              for (var pattern in negationPatterns) {
                if (dreamText.contains(pattern)) {
                  score -= 2; // Reduce score for negated emotions
                }
              }
            }
          }

          if (score > 0) {
            emotionScores[emotion] = score;
          }
        }

        // If no emotions detected, default to Neutral
        if (emotionScores.isEmpty) {
          determinedEmotion = 'Neutral';
        } else {
          // Find emotion with highest score
          var maxScore = 0;
          for (var entry in emotionScores.entries) {
            if (entry.value > maxScore) {
              maxScore = entry.value;
              determinedEmotion = entry.key;
            }
          }
        }

        // Check dream tags for additional context
        if (dreams[i].emotion.isNotEmpty && dreams[i].emotion != 'Unknown') {
          final tags = dreams[i].emotion.toLowerCase();
          for (var emotion in emotionKeywords.keys) {
            for (var keyword in emotionKeywords[emotion]!) {
              if (tags.contains(keyword)) {
                // If tag matches an emotion keyword, this strengthens our interpretation
                determinedEmotion = emotion;
                break;
              }
            }
          }
        }

        dreams[i] = DreamData(
          date: dreams[i].date,
          emotion: determinedEmotion,
          dream: dreams[i].dream,
        );
      }
    }

    // Calculate recurring themes with proper keyword matching
    final Map<String, int> themes = {};
    for (var dream in dreams) {
      final dreamText = dream.dream.toLowerCase();
      for (var entry in themeKeywords.entries) {
        for (var keyword in entry.value) {
          if (dreamText.contains(keyword)) {
            themes[entry.key] = (themes[entry.key] ?? 0) + 1;
            break; // Count theme only once per dream
          }
        }
      }
    }

    // Sort themes by frequency
    final sortedThemes = Map.fromEntries(
        themes.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));

    // Calculate pattern trends
    final Map<String, dynamic> patternTrends = {
      'Time Distribution': {
        'Morning':
            dreams.where((d) => d.date.hour >= 6 && d.date.hour < 12).length,
        'Afternoon':
            dreams.where((d) => d.date.hour >= 12 && d.date.hour < 18).length,
        'Evening':
            dreams.where((d) => d.date.hour >= 18 && d.date.hour < 22).length,
        'Night':
            dreams.where((d) => d.date.hour >= 22 || d.date.hour < 6).length,
      },
      'Weekend Ratio': dreams.isNotEmpty
          ? dreams.where((d) => d.date.weekday > 5).length / dreams.length
          : 0.0,
      'Dream Length': {
        'Short': dreams.where((d) => d.dream.split(' ').length < 50).length,
        'Medium': dreams
            .where((d) =>
                d.dream.split(' ').length >= 50 &&
                d.dream.split(' ').length < 200)
            .length,
        'Long': dreams.where((d) => d.dream.split(' ').length >= 200).length,
      }
    };

    // Generate psychologically-grounded symbolic interpretations based on actual themes found
    final Map<String, String> symbolicInterpretations = {
      'Flying': themes['Flying'] != null
          ? 'Flying (${themes['Flying']!} occurrences): Represents freedom, transcendence, or aspirations. Effortless flight suggests confidence, while struggling indicates anxiety about control. May reflect feelings about personal autonomy or escape from restrictions.'
          : '',
      'Falling': themes['Falling'] != null
          ? 'Falling (${themes['Falling']!} occurrences): Often occurs during transitions or insecurity. Represents losing control, anxiety about failure, or letting go. Context matters - falling into water suggests emotional overwhelm, while darkness indicates fear of the unknown.'
          : '',
      'Water': themes['Water'] != null
          ? 'Water (${themes['Water']!} occurrences): Symbolizes emotions and the unconscious. Clear water reflects emotional clarity, while turbulent water suggests turmoil. Deep water represents overwhelming feelings or the depths of your unconscious. Swimming comfortably indicates emotional competence.'
          : '',
      'Nature': themes['Nature'] != null
          ? 'Nature (${themes['Nature']!} occurrences): Represents connection to your authentic self or desire for renewal. Lush landscapes symbolize vitality, while barren areas reflect depletion. Mountains represent challenges, forests symbolize the unknown aspects of psyche.'
          : '',
      'People': themes['People'] != null
          ? 'People (${themes['People']!} occurrences): Often represent aspects of your own personality. Strangers embody unfamiliar parts of yourself, while known individuals represent qualities you associate with them. Interactions mirror your internal dynamics or relationship patterns.'
          : '',
      'Buildings': themes['Buildings'] != null
          ? 'Buildings (${themes['Buildings']!} occurrences): Symbolize the constructs of your life and psyche. Houses represent the self, with different rooms reflecting different aspects of personality. Condition matters - dilapidated structures suggest neglected aspects, new construction indicates development.'
          : '',
      'Travel': themes['Travel'] != null
          ? 'Travel (${themes['Travel']!} occurrences): Reflects transitions, personal development, and life direction. Cars represent personal agency, while public transport suggests predetermined paths. Obstacles symbolize challenges to progress. Common during periods of change.'
          : '',
      'Pursuit': themes['Pursuit'] != null
          ? 'Pursuit (${themes['Pursuit']!} occurrences): Being chased represents avoidance of threatening emotions or situations. The pursuer embodies what you\'re avoiding. Unknown figures represent unacknowledged fears, while known individuals symbolize specific issues associated with them.'
          : '',
      'Conflict': themes['Conflict'] != null
          ? 'Conflict (${themes['Conflict']!} occurrences): Represents inner conflict or relationship challenges. Often occurs when experiencing cognitive dissonance or opposing desires. Fighting with known individuals reflects relationship dynamics, while unknown figures represent struggling with aspects of yourself.'
          : '',
      'Loss': themes['Loss'] != null
          ? 'Loss (${themes['Loss']!} occurrences): Often processes feelings of actual loss, fear of potential loss, or identity shifts. Searching dreams appear during questioning or uncertainty. Panic suggests fear of loss, while acceptance indicates processing completed grief.'
          : '',
      'Animals': themes['Animals'] != null
          ? 'Animals (${themes['Animals']!} occurrences): Represent instinctual aspects of self or specific qualities. Wild animals symbolize primal emotions, domestic animals represent integrated instincts. Threatening animals embody feared aspects, while helpful animals represent supportive resources.'
          : '',
      'Doors': themes['Doors'] != null
          ? 'Doors (${themes['Doors']!} occurrences): Symbolize transitions, opportunities, or access to different states. Locked doors represent blocked opportunities, open doors suggest new possibilities. Choosing between doors reflects decision-making, hidden doors indicate discovering unknown options.'
          : '',
      'Light/Darkness': themes['Light'] != null || themes['Darkness'] != null
          ? 'Light/Darkness (${(themes['Light'] ?? 0) + (themes['Darkness'] ?? 0)} occurrences): Light represents awareness, clarity, and positive emotions, while darkness symbolizes the unknown, unconscious, or confusion. Moving from darkness to light reflects increasing understanding, the reverse indicates retreating into uncertainty.'
          : '',
    };

    // Filter out empty interpretations
    symbolicInterpretations.removeWhere((key, value) => value.isEmpty);

    // Generate personality insights based on dream patterns
    final Map<String, String> personalityInsights = {
      'Adaptability': (themes['Flying'] != null && themes['Flying']! > 0) ||
              (themes['Water'] != null && themes['Water']! > 0)
          ? 'Your dreams suggest you have an adaptable nature, easily adjusting to new circumstances and environments. You likely handle change well and can see multiple perspectives.'
          : 'Your dream patterns suggest you may prefer stability and routine over frequent changes.',
      'Emotional Processing': themes['Water'] != null && themes['Water']! > 0
          ? 'Your dreams with water themes indicate deep emotional awareness. You likely process feelings thoroughly and have a rich emotional life.'
          : 'Your dreams suggest you may approach emotions in a more practical or reserved manner.',
      'Creative Thinking': sortedThemes.length > 3
          ? 'The diversity of themes in your dreams reflects a creative and imaginative mind. You likely excel at thinking outside conventional boundaries and generating novel ideas.'
          : 'Your dreams follow more consistent patterns, suggesting you may prefer structured thinking and established approaches.',
      'Social Dynamics': themes['People'] != null && themes['People']! > 1
          ? "The presence of people in your dreams indicates the importance of relationships in your life. You're likely socially aware and attentive to interpersonal dynamics."
          : 'Your dreams feature fewer social scenarios, suggesting you may be more independent or introspective by nature.',
    };

    // Analyze dream patterns with meaningful examples
    Map<String, dynamic> dreamPatterns = {};

    // Only include patterns with actual examples
    List<String> lucidExamples = dreams
        .where((d) =>
            d.dream.toLowerCase().contains('aware') ||
            d.dream.toLowerCase().contains('realize') ||
            d.dream.toLowerCase().contains('conscious'))
        .map((d) => _getTruncatedDream(d.dream))
        .toList();

    if (lucidExamples.isNotEmpty) {
      dreamPatterns['Lucid Dreaming'] = {
        'Frequency': lucidExamples.length > 1 ? 'Regular' : 'Occasional',
        'Examples': lucidExamples,
      };
    }

    // Check for recurring themes
    if (themes.isNotEmpty) {
      Map<String, List<String>> recurringSymbols = {};

      // Get top themes with examples
      themes.entries.take(3).forEach((theme) {
        final examples = dreams
            .where((d) => themeKeywords[theme.key]!
                .any((keyword) => d.dream.toLowerCase().contains(keyword)))
            .map((d) => _getTruncatedDream(d.dream))
            .take(2)
            .toList();

        if (examples.isNotEmpty) {
          recurringSymbols[theme.key] = examples;
        }
      });

      if (recurringSymbols.isNotEmpty) {
        dreamPatterns['Recurring Symbols'] = recurringSymbols;
      }
    }

    // Emotional patterns only if we have emotion data
    Map<String, List<String>> emotionalPatterns = {};

    List<String> positiveEmotions = dreams
        .where((d) => ['joy', 'peace', 'wonder', 'happiness']
            .contains(d.emotion.toLowerCase()))
        .map((d) => d.emotion)
        .toSet()
        .toList();

    List<String> challengingEmotions = dreams
        .where((d) => ['fear', 'anxiety', 'sadness', 'confusion']
            .contains(d.emotion.toLowerCase()))
        .map((d) => d.emotion)
        .toSet()
        .toList();

    if (positiveEmotions.isNotEmpty) {
      emotionalPatterns['Positive Emotions'] = positiveEmotions;
    }

    if (challengingEmotions.isNotEmpty) {
      emotionalPatterns['Challenging Emotions'] = challengingEmotions;
    }

    if (emotionalPatterns.isNotEmpty) {
      dreamPatterns['Emotional Patterns'] = emotionalPatterns;
    }

    // Analyze archetypes based on dream content
    final Map<String, dynamic> archetypalAnalysis = {};

    // Only include archetypes that are actually present
    if (themes['Travel'] != null || themes['Flying'] != null) {
      archetypalAnalysis['The Explorer'] = {
        'Strength': ((themes['Travel'] ?? 0) + (themes['Flying'] ?? 0)) > 2
            ? 'Strong'
            : 'Moderate',
        'Meaning':
            'Represents your drive to discover new territories, both literally and in terms of knowledge and experience.',
        'Examples': dreams
            .where((d) =>
                (themes['Travel'] != null &&
                    themeKeywords['Travel']!.any((keyword) =>
                        d.dream.toLowerCase().contains(keyword))) ||
                (themes['Flying'] != null &&
                    themeKeywords['Flying']!.any(
                        (keyword) => d.dream.toLowerCase().contains(keyword))))
            .map((d) => _getTruncatedDream(d.dream))
            .take(2)
            .toList(),
      };
    }

    // The Protector
    if (themes['People'] != null) {
      final protectorDreams = dreams
          .where((d) =>
              d.dream.toLowerCase().contains('protect') ||
              d.dream.toLowerCase().contains('save') ||
              d.dream.toLowerCase().contains('help') ||
              d.dream.toLowerCase().contains('rescue'))
          .toList();

      if (protectorDreams.isNotEmpty) {
        archetypalAnalysis['The Protector'] = {
          'Strength': protectorDreams.length > 1 ? 'Strong' : 'Moderate',
          'Meaning':
              'Represents your desire to care for others and ensure their safety and wellbeing.',
          'Examples': protectorDreams
              .map((d) => _getTruncatedDream(d.dream))
              .take(2)
              .toList(),
        };
      }
    }

    // The Shadow
    final shadowDreams = dreams
        .where((d) =>
            d.dream.toLowerCase().contains('dark') ||
            d.dream.toLowerCase().contains('shadow') ||
            d.dream.toLowerCase().contains('hidden') ||
            d.dream.toLowerCase().contains('secret'))
        .toList();

    if (shadowDreams.isNotEmpty) {
      archetypalAnalysis['The Shadow'] = {
        'Strength': shadowDreams.length > 1 ? 'Strong' : 'Moderate',
        'Meaning':
            'Represents aspects of yourself that you may have repressed or are not fully conscious of.',
        'Examples': shadowDreams
            .map((d) => _getTruncatedDream(d.dream))
            .take(2)
            .toList(),
      };
    }

    // Generate emotional insights based on actual emotions in dreams
    final Map<String, dynamic> emotionalInsights = {};

    final List<String> primaryEmotions = dreams
        .map((d) => d.emotion)
        .where((e) => e != 'Unknown' && e.isNotEmpty)
        .toSet()
        .toList();

    if (primaryEmotions.isNotEmpty) {
      emotionalInsights['Primary Emotions'] = primaryEmotions;
    }

    // Check emotional balance
    final int positiveCount = dreams
        .where((d) => ['joy', 'peace', 'wonder', 'happiness']
            .contains(d.emotion.toLowerCase()))
        .length;

    final int challengingCount = dreams
        .where((d) => ['fear', 'anxiety', 'sadness', 'confusion']
            .contains(d.emotion.toLowerCase()))
        .length;

    if (positiveCount > 0 || challengingCount > 0) {
      if (positiveCount > challengingCount) {
        final double percentage =
            dreams.isNotEmpty ? (positiveCount / dreams.length) * 100 : 0;
        emotionalInsights['Emotional Balance'] =
            'Your dreams show a generally positive emotional landscape, with ${percentage.toStringAsFixed(0)}% positive emotions.';
      } else if (challengingCount > positiveCount) {
        final double percentage =
            dreams.isNotEmpty ? (challengingCount / dreams.length) * 100 : 0;
        emotionalInsights['Emotional Balance'] =
            'Your dreams contain more challenging emotions (${percentage.toStringAsFixed(0)}%), suggesting you may be processing some difficulties or concerns.';
      } else {
        emotionalInsights['Emotional Balance'] =
            'Your dreams show a balanced emotional landscape with equal positive and challenging emotions.';
      }
    }

    // Growth areas
    final List<String> growthEmotions = dreams
        .where((d) => ['fear', 'anxiety', 'sadness', 'confusion']
            .contains(d.emotion.toLowerCase()))
        .map((d) => d.emotion)
        .toSet()
        .toList();

    if (growthEmotions.isNotEmpty) {
      emotionalInsights['Growth Areas'] = growthEmotions;

      List<String> growthInsights = [];

      if (growthEmotions.contains('Fear') || growthEmotions.contains('fear')) {
        growthInsights.add(
            'Your fear dreams suggest an opportunity to build courage and face concerns directly.');
      }

      if (growthEmotions.contains('Anxiety') ||
          growthEmotions.contains('anxiety')) {
        growthInsights.add(
            'Dreams with anxiety indicate a need to develop stress management techniques and identify the root causes of worry.');
      }

      if (growthEmotions.contains('Sadness') ||
          growthEmotions.contains('sadness')) {
        growthInsights.add(
            'Sadness in dreams often points to unprocessed grief or disappointment that may need acknowledgment.');
      }

      if (growthEmotions.contains('Confusion') ||
          growthEmotions.contains('confusion')) {
        growthInsights.add(
            'Confusion in dreams suggests a need for clarity and direction in some aspect of your life.');
      }

      if (growthInsights.isNotEmpty) {
        emotionalInsights['Growth Insights'] = growthInsights;
      }
    }

    // Generate personalized dream recommendations based on analysis
    final List<String> dreamRecommendations = [];

    // Theme-based recommendations
    if (themes['Flying'] != null && themes['Flying']! > 0) {
      dreamRecommendations.add(
          'Your flying dreams suggest a desire for freedom and perspective. Consider activities that give you a sense of expansion, like travel or learning new skills.');
    }

    if (themes['Falling'] != null && themes['Falling']! > 0) {
      dreamRecommendations.add(
          'Your falling dreams indicate feelings of insecurity. Focus on building confidence through small achievements and creating more stability in your daily routine.');
    }

    if (themes['Water'] != null && themes['Water']! > 0) {
      dreamRecommendations.add(
          'Water in your dreams connects to your emotional world. Regular journaling about your feelings can help you process emotions more effectively.');
    }

    if (themes['Nature'] != null && themes['Nature']! > 0) {
      dreamRecommendations.add(
          'Your nature dreams suggest a need for grounding. Make time to connect with natural environments regularly, even if just a local park or garden.');
    }

    if (themes['People'] != null && themes['People']! > 1) {
      dreamRecommendations.add(
          'Your dreams frequently involve people, reflecting the importance of relationships. Nurture your connections with meaningful conversations and quality time.');
    }

    if (themes['Pursuit'] != null && themes['Pursuit']! > 0) {
      dreamRecommendations.add(
          'Being chased in dreams often relates to avoidance. Consider what you might be running from in waking life and try facing it directly.');
    }

    // General recommendations
    dreamRecommendations.add(
        'Keep your dream journal consistently to identify longer-term patterns and changes over time.');
    dreamRecommendations.add(
        'Practice a brief meditation before sleep to improve dream recall and potentially experience more lucid dreams.');
    dreamRecommendations.add(
        'Review your dreams for recurring symbols and consider their personal meaning to you rather than generic interpretations.');

    // Sort by length for better display
    dreamRecommendations.sort((a, b) => a.length.compareTo(b.length));

    return AnalysisResults(
      moodTimeline: dreams,
      recurringThemes: sortedThemes,
      patternTrends: patternTrends,
      symbolicInterpretations: symbolicInterpretations,
      personalityInsights: personalityInsights,
      dreamPatterns: themeAnalysis,
      archetypalAnalysis: archetypalAnalysis,
      emotionalInsights: emotionalInsights,
      dreamRecommendations: dreamRecommendations,
    );
  }

  String _generateThemeAnalysis(String theme, String context) {
    switch (theme) {
      case 'Flying':
        if (context.toLowerCase().contains('control') ||
            context.toLowerCase().contains('freedom')) {
          return 'This flying dream indicates a sense of empowerment and liberation, suggesting personal growth and overcoming limitations.';
        } else if (context.toLowerCase().contains('fear') ||
            context.toLowerCase().contains('fall')) {
          return 'The combination of flying and anxiety suggests underlying concerns about maintaining control in a situation where you feel elevated or promoted.';
        }
        return 'Flying represents a desire for freedom and transcendence from current limitations.';

      case 'Falling':
        if (context.toLowerCase().contains('peaceful') ||
            context.toLowerCase().contains('floating')) {
          return 'This peaceful falling experience suggests acceptance of change and letting go of control, indicating personal growth.';
        } else if (context.toLowerCase().contains('wake') ||
            context.toLowerCase().contains('jolt')) {
          return 'The sudden falling and waking indicates processing of real-world anxieties about losing control or fear of failure.';
        }
        return 'Falling represents feelings of losing control or fear of failure in some aspect of life.';

      case 'Water':
        if (context.toLowerCase().contains('clear') ||
            context.toLowerCase().contains('calm')) {
          return 'The clear, calm water symbolizes emotional clarity and peace, suggesting good emotional processing.';
        } else if (context.toLowerCase().contains('storm') ||
            context.toLowerCase().contains('waves')) {
          return 'Turbulent water represents emotional upheaval or processing of intense feelings.';
        }
        return 'Water symbolizes your emotional state and unconscious mind.';

      case 'Lucid':
        if (context.toLowerCase().contains('control') ||
            context.toLowerCase().contains('change')) {
          return 'This lucid experience shows active engagement with your unconscious mind, indicating growing dream awareness and control.';
        } else if (context.toLowerCase().contains('realize') ||
            context.toLowerCase().contains('check')) {
          return 'The reality check leading to lucidity shows developing dream awareness skills and mindfulness.';
        }
        return 'Lucidity indicates growing awareness and control in your dream state.';

      default:
        return 'This dream theme reveals important patterns in your subconscious processing.';
    }
  }

  // Helper function to truncate dream text for display
  String _getTruncatedDream(String dream) {
    if (dream.length <= 100) return dream;
    return dream.substring(0, 97) + '...';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).primary,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Analyzing your dreams...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Dream Analysis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMoodTimeline(),
            SizedBox(height: 24),
            _buildRecurringThemes(),
            SizedBox(height: 24),
            _buildPatternTrends(),
            SizedBox(height: 24),
            _buildSymbolicInterpretations(),
            SizedBox(height: 24),
            _buildPersonalityInsights(),
            SizedBox(height: 24),
            _buildDreamPatterns(),
            SizedBox(height: 24),
            _buildArchetypalAnalysis(),
            SizedBox(height: 24),
            _buildEmotionalInsights(),
            SizedBox(height: 24),
            _buildDreamRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodTimeline() {
    return _buildGlassCard(
      title: 'Dream Emotion Timeline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'How your dream emotions have changed over time',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String text = '';
                        if (value == 1.0) {
                          text = 'Joy';
                        } else if (value == 0.8) {
                          text = 'Peace';
                        } else if (value == 0.6) {
                          text = 'Hope';
                        } else if (value == 0.4) {
                          text = 'Neutral';
                        } else if (value == 0.2) {
                          text = 'Sad';
                        } else if (value == 0.0) {
                          text = 'Fear';
                        }

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        );
                      },
                      reservedSize: 45,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >=
                            _analysisResults!.moodTimeline.length) {
                          return SizedBox.shrink();
                        }
                        final date =
                            _analysisResults!.moodTimeline[value.toInt()].date;
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      _analysisResults!.moodTimeline.length,
                      (index) => FlSpot(
                        index.toDouble(),
                        _getEmotionValue(
                            _analysisResults!.moodTimeline[index].emotion),
                      ),
                    ),
                    isCurved: true,
                    color: FlutterFlowTheme.of(context).primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: FlutterFlowTheme.of(context).primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                    ),
                  ),
                ],
                minX: 0,
                maxX: (_analysisResults!.moodTimeline.length - 1).toDouble(),
                minY: 0,
                maxY: 1,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Recent Dreams',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _analysisResults!.moodTimeline.length,
              itemBuilder: (context, index) {
                final dream = _analysisResults!.moodTimeline[index];
                // Skip empty dreams
                if (dream.dream.isEmpty) {
                  return SizedBox.shrink();
                }
                return Container(
                  width: 200,
                  margin: EdgeInsets.only(right: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .primary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              dream.emotion,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(dream.date),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          dream.dream,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringThemes() {
    return _buildGlassCard(
      title: 'Recurring Dream Themes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'The most common themes appearing in your dreams',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          _analysisResults!.recurringThemes.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No recurring themes found yet. Add more dreams to see patterns emerge.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _analysisResults!.recurringThemes.entries.length,
                    itemBuilder: (context, index) {
                      final entry = _analysisResults!.recurringThemes.entries
                          .elementAt(index);
                      final percentage = entry.value /
                          _analysisResults!.moodTimeline.length *
                          100;

                      return Container(
                        width: 120,
                        margin: EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).primary,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${entry.value}/${_analysisResults!.moodTimeline.length}',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              entry.key,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPatternTrends() {
    return _buildGlassCard(
      title: 'Dream Patterns',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildTimeDistributionItem(
                  'Morning',
                  _analysisResults!
                      .patternTrends['Time Distribution']!['Morning'] as int),
              _buildTimeDistributionItem(
                  'Afternoon',
                  _analysisResults!
                      .patternTrends['Time Distribution']!['Afternoon'] as int),
              _buildTimeDistributionItem(
                  'Evening',
                  _analysisResults!
                      .patternTrends['Time Distribution']!['Evening'] as int),
              _buildTimeDistributionItem(
                  'Night',
                  _analysisResults!.patternTrends['Time Distribution']!['Night']
                      as int),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Weekend Ratio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: _analysisResults!.patternTrends['Weekend Ratio'] as double,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).primary,
            ),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDistributionItem(String label, int value) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolicInterpretations() {
    return _buildGlassCard(
      title: 'Dream Symbol Meanings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Understanding the symbolic meaning behind recurring elements in your dreams',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          _analysisResults!.symbolicInterpretations.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No symbolic interpretations available yet. Add more dreams for deeper analysis.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount:
                      _analysisResults!.symbolicInterpretations.entries.length,
                  itemBuilder: (context, index) {
                    final entry = _analysisResults!
                        .symbolicInterpretations.entries
                        .elementAt(index);
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primary
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Spacer(),
                              Icon(
                                _getSymbolIcon(entry.key),
                                color: Colors.white70,
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            entry.value,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  IconData _getSymbolIcon(String symbol) {
    switch (symbol.toLowerCase()) {
      case 'flying':
        return Icons.flight;
      case 'falling':
        return Icons.arrow_downward;
      case 'water':
        return Icons.water;
      case 'nature':
        return Icons.nature;
      case 'people':
        return Icons.people;
      case 'buildings':
        return Icons.home;
      case 'travel':
        return Icons.map;
      case 'pursuit':
        return Icons.directions_run;
      case 'conflict':
        return Icons.flash_on;
      case 'loss':
        return Icons.search;
      default:
        return Icons.auto_awesome;
    }
  }

  Widget _buildPersonalityInsights() {
    return _buildGlassCard(
      title: 'Personality Insights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _analysisResults!.personalityInsights.entries.map((entry) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  entry.value,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDreamPatterns() {
    return _buildGlassCard(
      title: 'Dream Patterns',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _analysisResults!.dreamPatterns.entries.map((entry) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (entry.value is Map && entry.value['frequency'] != null)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'x${entry.value['frequency']}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                if (entry.value is Map && entry.value['examples'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (entry.value['examples'] as List)
                        .map<Widget>((example) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (example['date'] != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  DateFormat('MMM d, yyyy')
                                      .format(example['date']),
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            Text(
                              _truncateText(example['excerpt'] as String, 100),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            if (example['analysis'] != null)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  _truncateText(
                                      example['analysis'] as String, 80),
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context)
                                        .primary
                                        .withOpacity(0.8),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - 3) + '...';
  }

  Widget _buildArchetypalAnalysis() {
    return _buildGlassCard(
      title: 'Archetypal Analysis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _analysisResults!.archetypalAnalysis.entries.map((entry) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        entry.value['Strength'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Examples:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (entry.value['Examples'] as List).map((example) {
                    return Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        example,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmotionalInsights() {
    return _buildGlassCard(
      title: 'Emotional Insights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _analysisResults!.emotionalInsights.entries.map((entry) {
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                if (entry.value is List)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (entry.value as List).map((item) {
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDreamRecommendations() {
    return _buildGlassCard(
      title: 'Personalized Insights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Recommendations based on your unique dream patterns',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _analysisResults!.dreamRecommendations.length,
            itemBuilder: (context, index) {
              final recommendation =
                  _analysisResults!.dreamRecommendations[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context)
                            .primary
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getRecommendationIcon(recommendation),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getRecommendationTitle(recommendation),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            recommendation,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getRecommendationIcon(String recommendation) {
    if (recommendation.contains('flying')) {
      return Icons.flight_takeoff;
    } else if (recommendation.contains('water') ||
        recommendation.contains('emotions')) {
      return Icons.water_drop;
    } else if (recommendation.contains('nature') ||
        recommendation.contains('outdoors')) {
      return Icons.nature_people;
    } else if (recommendation.contains('relationships') ||
        recommendation.contains('people')) {
      return Icons.people;
    } else if (recommendation.contains('building') ||
        recommendation.contains('personal development')) {
      return Icons.auto_graph;
    } else if (recommendation.contains('journal')) {
      return Icons.book;
    } else if (recommendation.contains('meditation') ||
        recommendation.contains('sleep')) {
      return Icons.nightlight;
    } else if (recommendation.contains('lucid') ||
        recommendation.contains('recall')) {
      return Icons.lightbulb;
    } else if (recommendation.contains('falling') ||
        recommendation.contains('insecurity')) {
      return Icons.security;
    } else {
      return Icons.tips_and_updates;
    }
  }

  String _getRecommendationTitle(String recommendation) {
    if (recommendation.contains('flying')) {
      return 'Freedom & Aspiration';
    } else if (recommendation.contains('water') ||
        recommendation.contains('emotions')) {
      return 'Emotional Awareness';
    } else if (recommendation.contains('nature') ||
        recommendation.contains('outdoors')) {
      return 'Natural Connection';
    } else if (recommendation.contains('relationships') ||
        recommendation.contains('people')) {
      return 'Social Connection';
    } else if (recommendation.contains('building') ||
        recommendation.contains('personal development')) {
      return 'Personal Growth';
    } else if (recommendation.contains('journal')) {
      return 'Dream Journaling';
    } else if (recommendation.contains('meditation') ||
        recommendation.contains('sleep')) {
      return 'Sleep Quality';
    } else if (recommendation.contains('lucid') ||
        recommendation.contains('recall')) {
      return 'Dream Awareness';
    } else if (recommendation.contains('falling') ||
        recommendation.contains('insecurity')) {
      return 'Building Security';
    } else {
      return 'Dream Insight';
    }
  }

  Widget _buildGlassCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    ).animate().fade(duration: 600.ms).slideY(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOut,
        );
  }

  double _getEmotionValue(String emotion) {
    final String lowerEmotion = emotion.toLowerCase();

    // Positive emotions (higher values)
    if (lowerEmotion.contains('joy') ||
        lowerEmotion.contains('happy') ||
        lowerEmotion.contains('excite')) {
      return 1.0; // Maximum positive
    }

    if (lowerEmotion.contains('wonder') ||
        lowerEmotion.contains('amaze') ||
        lowerEmotion.contains('fascinate')) {
      return 0.85;
    }

    if (lowerEmotion.contains('peace') ||
        lowerEmotion.contains('calm') ||
        lowerEmotion.contains('tranquil') ||
        lowerEmotion.contains('serene')) {
      return 0.7;
    }

    if (lowerEmotion.contains('hope') ||
        lowerEmotion.contains('optimis') ||
        lowerEmotion.contains('positive')) {
      return 0.6;
    }

    // Neutral emotions (mid values)
    if (lowerEmotion.contains('curios') || lowerEmotion.contains('interest')) {
      return 0.5;
    }

    if (lowerEmotion.contains('surprise') ||
        lowerEmotion.contains('astonish')) {
      return 0.45;
    }

    if (lowerEmotion.contains('neutral') ||
        lowerEmotion.contains('ok') ||
        lowerEmotion == 'fine') {
      return 0.4;
    }

    // Challenging emotions (lower values)
    if (lowerEmotion.contains('confus') || lowerEmotion.contains('uncertain')) {
      return 0.3;
    }

    if (lowerEmotion.contains('sad') ||
        lowerEmotion.contains('depress') ||
        lowerEmotion.contains('grief') ||
        lowerEmotion.contains('somber')) {
      return 0.2;
    }

    if (lowerEmotion.contains('anxious') ||
        lowerEmotion.contains('worry') ||
        lowerEmotion.contains('nervous') ||
        lowerEmotion.contains('stress')) {
      return 0.1;
    }

    if (lowerEmotion.contains('fear') ||
        lowerEmotion.contains('terror') ||
        lowerEmotion.contains('afraid') ||
        lowerEmotion.contains('scared') ||
        lowerEmotion.contains('dread')) {
      return 0.0; // Maximum negative
    }

    // Default for unknown emotions
    return 0.4;
  }
}

class DreamData {
  final DateTime date;
  final String emotion;
  final String dream;

  DreamData({
    required this.date,
    required this.emotion,
    required this.dream,
  });
}

class AnalysisResults {
  final List<DreamData> moodTimeline;
  final Map<String, int> recurringThemes;
  final Map<String, dynamic> patternTrends;
  final Map<String, String> symbolicInterpretations;
  final Map<String, String> personalityInsights;
  final Map<String, dynamic> dreamPatterns;
  final Map<String, dynamic> archetypalAnalysis;
  final Map<String, dynamic> emotionalInsights;
  final List<String> dreamRecommendations;

  AnalysisResults({
    required this.moodTimeline,
    required this.recurringThemes,
    required this.patternTrends,
    required this.symbolicInterpretations,
    required this.personalityInsights,
    required this.dreamPatterns,
    required this.archetypalAnalysis,
    required this.emotionalInsights,
    required this.dreamRecommendations,
  });
}

class DreamExcerpt {
  final String excerpt;
  final DateTime date;
  final String analysis;

  DreamExcerpt({
    required this.excerpt,
    required this.date,
    required this.analysis,
  });
}
