import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../backend/schema/dream_analysis_record.dart';
import '../backend/schema/posts_record.dart';
import '../backend/schema/util/record_data.dart';

class DreamAnalysisService {
  static Future<DreamAnalysisRecord> analyzeDream(
      List<PostsRecord> dreams) async {
    // Get the current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // Create a new dream analysis document
    final analysisRef = DreamAnalysisRecord.collection.doc();

    // Analyze the dreams and create insights
    final analysis = _generateAnalysis(dreams);

    // Get the user reference
    final userRef =
        FirebaseFirestore.instance.collection('User').doc(currentUser.uid);

    // Create the record data
    final data = createDreamAnalysisRecordData(
      moodAnalysis: analysis['mood_analysis'],
      moodEvidence: analysis['mood_evidence'],
      dreamPersona: analysis['dream_persona'],
      personaEvidence: analysis['persona_evidence'],
      dreamEnvironment: analysis['dream_environment'],
      environmentEvidence: analysis['environment_evidence'],
      personalGrowthInsights: analysis['personal_growth_insights'],
      growthEvidence: analysis['growth_evidence'],
      recommendedActions: analysis['recommended_actions'],
      actionEvidence: analysis['action_evidence'],
      date: DateTime.now(),
      userref: userRef,
    );

    // Save to Firestore
    await analysisRef.set(data);

    // Return the record
    return DreamAnalysisRecord.fromSnapshot(
      await analysisRef.get(),
    );
  }

  static Future<Map<String, dynamic>> generateMoodTimeline(
    List<PostsRecord> dreams,
  ) async {
    return {
      'dates': dreams.map((d) => d.date).toList(),
      'moods': dreams.map((d) => _extractMoodFromDream(d)).toList(),
    };
  }

  static Future<Map<String, dynamic>> calculateDreamFrequency(
    List<PostsRecord> dreams,
  ) async {
    return {
      'categories': _categorizeDreams(dreams),
    };
  }

  static Map<String, dynamic> _generateAnalysis(List<PostsRecord> dreams) {
    return {
      'mood_analysis': _analyzeMood(dreams),
      'mood_evidence': _generateMoodEvidence(dreams),
      'dream_persona': _analyzePersona(dreams),
      'persona_evidence': _generatePersonaEvidence(dreams),
      'dream_environment': _analyzeEnvironment(dreams),
      'environment_evidence': _generateEnvironmentEvidence(dreams),
      'personal_growth_insights': _generateGrowthInsights(dreams),
      'growth_evidence': _generateGrowthEvidence(dreams),
      'recommended_actions': _generateRecommendedActions(dreams),
      'action_evidence': _generateActionEvidence(dreams),
    };
  }

  static String _extractMoodFromDream(PostsRecord dream) {
    final content = dream.dream.toLowerCase();

    // Enhanced emotion detection with broader vocabulary and contextual clues
    final Map<String, List<String>> emotionKeywords = {
      'Happy': [
        'happy',
        'joy',
        'excited',
        'delighted',
        'pleased',
        'cheerful',
        'blissful',
        'elated',
        'thrilled',
        'overjoyed',
        'ecstatic',
        'laughing',
        'smiling',
        'celebration',
        'wonderful',
        'fantastic'
      ],
      'Sad': [
        'sad',
        'depressed',
        'unhappy',
        'gloomy',
        'melancholy',
        'miserable',
        'grief',
        'sorrow',
        'tearful',
        'crying',
        'despair',
        'heartbroken',
        'disappointed',
        'regretful',
        'down',
        'blue',
        'hopeless'
      ],
      'Fearful': [
        'scary',
        'fear',
        'terrified',
        'afraid',
        'frightened',
        'panic',
        'horrified',
        'scared',
        'anxious',
        'worried',
        'nervous',
        'dread',
        'terror',
        'horror',
        'spooked',
        'threatened',
        'intimidated'
      ],
      'Peaceful': [
        'peaceful',
        'calm',
        'tranquil',
        'serene',
        'relaxed',
        'harmonious',
        'content',
        'restful',
        'quiet',
        'stillness',
        'soothing',
        'gentle',
        'composed',
        'ease',
        'comforted',
        'balanced',
        'meditative'
      ],
      'Confused': [
        'confused',
        'puzzled',
        'perplexed',
        'bewildered',
        'disoriented',
        'uncertain',
        'unclear',
        'lost',
        'muddled',
        'unsure',
        'doubtful',
        'questioning',
        'disorganized',
        'chaotic',
        'complicated'
      ],
      'Angry': [
        'angry',
        'furious',
        'rage',
        'outraged',
        'irritated',
        'annoyed',
        'frustrated',
        'mad',
        'hostile',
        'aggressive',
        'bitter',
        'enraged',
        'fuming',
        'indignant',
        'heated',
        'temper',
        'irate'
      ],
      'Excited': [
        'excited',
        'thrilled',
        'enthusiastic',
        'eager',
        'animated',
        'energetic',
        'lively',
        'vibrant',
        'passionate',
        'ardent',
        'anticipating',
        'keen',
        'electrified',
        'pumped',
        'exhilarated'
      ],
      'Nostalgic': [
        'nostalgic',
        'reminiscent',
        'memory',
        'childhood',
        'past',
        'longing',
        'remembered',
        'familiar',
        'sentimental',
        'wistful',
        'yearning',
        'bygone',
        'recollection',
        'homesick'
      ]
    };

    // Score the content for each emotion
    Map<String, int> scores = {};

    for (var emotion in emotionKeywords.keys) {
      int score = 0;
      for (var keyword in emotionKeywords[emotion]!) {
        // Full word matching to avoid false positives
        RegExp wordPattern = RegExp(r'\b' + keyword + r'\b');

        // Count occurrences
        final matches = wordPattern.allMatches(content);
        score += matches.length;

        // Check for negations that reverse the meaning
        for (var match in matches) {
          // Look at the 5 words before the match to check for negations
          int start = match.start - 30 < 0 ? 0 : match.start - 30;
          String beforeContext = content.substring(start, match.start);
          if (beforeContext.contains("not ") ||
              beforeContext.contains("don't ") ||
              beforeContext.contains("didn't ") ||
              beforeContext.contains("wasn't ") ||
              beforeContext.contains("no ")) {
            score--; // Reduce score for negated emotion
          }
        }
      }

      // Also check for contextual tags
      if (dream.tags.isNotEmpty) {
        final tags = dream.tags.toLowerCase();
        for (var keyword in emotionKeywords[emotion]!) {
          if (tags.contains(keyword)) {
            score += 2; // Tags have higher weight
          }
        }
      }

      if (score > 0) {
        scores[emotion] = score;
      }
    }

    // Return the emotion with the highest score, or Neutral if none found
    if (scores.isEmpty) {
      return 'Neutral';
    }

    // Sort by score
    final sortedEmotions = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEmotions.first.key;
  }

  static Map<String, int> _categorizeDreams(List<PostsRecord> dreams) {
    final categories = <String, int>{
      'Adventure': 0,
      'Nightmare': 0,
      'Lucid': 0,
      'Recurring': 0,
      'Symbolic': 0,
      'Healing': 0,
      'Prophetic': 0,
      'Other': 0,
    };

    // More comprehensive categorization with context awareness
    for (var dream in dreams) {
      final content = dream.dream.toLowerCase();
      final tags = dream.tags.toLowerCase();
      bool categorized = false;

      // Adventure dreams
      if (content.contains('adventure') ||
          content.contains('explore') ||
          content.contains('journey') ||
          content.contains('quest') ||
          content.contains('discover') ||
          tags.contains('adventure')) {
        categories['Adventure'] = (categories['Adventure'] ?? 0) + 1;
        categorized = true;
      }

      // Nightmare detection
      if (content.contains('scary') ||
          content.contains('fear') ||
          content.contains('nightmare') ||
          content.contains('terrif') ||
          content.contains('horror') ||
          content.contains('scream') ||
          content.contains('panic') ||
          tags.contains('nightmare') ||
          tags.contains('scary')) {
        categories['Nightmare'] = (categories['Nightmare'] ?? 0) + 1;
        categorized = true;
      }

      // Lucid dreams
      if (content.contains('aware i was dreaming') ||
          content.contains('lucid') ||
          content.contains('control the dream') ||
          content.contains('realized it was a dream') ||
          content.contains('conscious in my dream') ||
          tags.contains('lucid')) {
        categories['Lucid'] = (categories['Lucid'] ?? 0) + 1;
        categorized = true;
      }

      // Recurring dreams
      if (content.contains('again and again') ||
          content.contains('recurring') ||
          content.contains('same dream') ||
          content.contains('dream repeats') ||
          content.contains('dreamt before') ||
          content.contains('familiar dream') ||
          tags.contains('recurring')) {
        categories['Recurring'] = (categories['Recurring'] ?? 0) + 1;
        categorized = true;
      }

      // Symbolic dreams
      if (content.contains('symbol') ||
          content.contains('meaning') ||
          content.contains('represent') ||
          content.contains('metaphor') ||
          tags.contains('symbolic')) {
        categories['Symbolic'] = (categories['Symbolic'] ?? 0) + 1;
        categorized = true;
      }

      // Healing dreams
      if (content.contains('heal') ||
          content.contains('therapy') ||
          content.contains('recover') ||
          content.contains('better') ||
          content.contains('resolve') ||
          tags.contains('healing')) {
        categories['Healing'] = (categories['Healing'] ?? 0) + 1;
        categorized = true;
      }

      // Prophetic dreams
      if (content.contains('future') ||
          content.contains('premonition') ||
          content.contains('predict') ||
          content.contains('foresee') ||
          content.contains('vision') ||
          tags.contains('prophetic')) {
        categories['Prophetic'] = (categories['Prophetic'] ?? 0) + 1;
        categorized = true;
      }

      // Catch-all for uncategorized dreams
      if (!categorized) {
        categories['Other'] = (categories['Other'] ?? 0) + 1;
      }
    }

    // Remove categories with zero count
    categories.removeWhere((key, value) => value == 0);

    return categories;
  }

  static String _analyzeMood(List<PostsRecord> dreams) {
    final moods = <String, int>{};
    for (var dream in dreams) {
      final mood = _extractMoodFromDream(dream);
      moods[mood] = (moods[mood] ?? 0) + 1;
    }

    final dominantMood = moods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (dominantMood.isEmpty) {
      return 'Your dreams show a balanced emotional state with no dominant emotions.';
    }

    // More meaningful and personalized analysis
    final mood = dominantMood[0].key;
    final count = dominantMood[0].value;
    final percentage = dreams.isNotEmpty ? (count / dreams.length) * 100 : 0;

    Map<String, String> moodInsights = {
      'Happy':
          'Your dreams predominantly show $mood emotions (${percentage.toStringAsFixed(0)}%). This suggests your subconscious mind is processing positive experiences and may reflect contentment or optimism in your waking life.',
      'Sad':
          'Your dreams predominantly show $mood emotions (${percentage.toStringAsFixed(0)}%). This might indicate you\'re processing grief or disappointment, or need to address unresolved feelings.',
      'Fearful':
          'Your dreams predominantly show $mood emotions (${percentage.toStringAsFixed(0)}%). This could reflect anxiety or concerns you\'re experiencing, possibly related to upcoming challenges or past experiences that need resolution.',
      'Peaceful':
          'Your dreams predominantly show $mood emotions (${percentage.toStringAsFixed(0)}%). This suggests inner harmony and a calm mental state, possibly reflecting good emotional balance in your life.',
      'Confused':
          'Your dreams predominantly show $mood emotions (${percentage.toStringAsFixed(0)}%). This may indicate you\'re processing complex situations or decisions that require clarity.',
      'Angry':
          'Your dreams predominantly show $mood emotions (${percentage.toStringAsFixed(0)}%). This might suggest repressed frustration or unresolved conflicts that need addressing.',
      'Excited':
          'Your dreams predominantly show $mood emotions (${percentage.toStringAsFixed(0)}%). This reflects anticipation or enthusiasm about upcoming events or opportunities in your life.',
      'Nostalgic':
          'Your dreams predominantly show $mood emotions (${percentage.toStringAsFixed(0)}%). This suggests you may be reflecting on your past experiences, possibly seeking connection with your roots or earlier life stages.',
      'Neutral':
          'Your dreams show predominantly neutral emotions (${percentage.toStringAsFixed(0)}%). This might indicate a period of emotional stability or a tendency to process emotions intellectually rather than feeling them intensely.',
    };

    // Return personalized insight for the dominant mood
    return moodInsights[mood] ??
        'Your dreams predominantly show $mood emotions (${percentage.toStringAsFixed(0)}%), suggesting this emotional state is significant in your current life.';
  }

  static Map<String, List<String>> _generateMoodEvidence(
      List<PostsRecord> dreams) {
    final evidence = <String, List<String>>{};
    for (var dream in dreams) {
      final content = dream.dream.toLowerCase();
      final sentences = dream.dream.split(RegExp(r'[.!?]+'));

      if (content.contains('happy') ||
          content.contains('joy') ||
          content.contains('excited')) {
        _addEvidence(evidence, 'Positive Emotions', sentences,
            ['happy', 'joy', 'excited']);
      }
      if (content.contains('sad') ||
          content.contains('depressed') ||
          content.contains('unhappy')) {
        _addEvidence(evidence, 'Negative Emotions', sentences,
            ['sad', 'depressed', 'unhappy']);
      }
      if (content.contains('scary') ||
          content.contains('fear') ||
          content.contains('terrified')) {
        _addEvidence(evidence, 'Fearful Emotions', sentences,
            ['scary', 'fear', 'terrified']);
      }
      if (content.contains('peaceful') ||
          content.contains('calm') ||
          content.contains('tranquil')) {
        _addEvidence(evidence, 'Peaceful Emotions', sentences,
            ['peaceful', 'calm', 'tranquil']);
      }
    }

    return evidence;
  }

  static String _analyzePersona(List<PostsRecord> dreams) {
    final personas = <String, int>{};
    for (var dream in dreams) {
      final content = dream.dream.toLowerCase();
      if (content.contains('explore') || content.contains('adventure')) {
        personas['Explorer'] = (personas['Explorer'] ?? 0) + 1;
      }
      if (content.contains('help') || content.contains('save')) {
        personas['Helper'] = (personas['Helper'] ?? 0) + 1;
      }
      if (content.contains('create') || content.contains('build')) {
        personas['Creator'] = (personas['Creator'] ?? 0) + 1;
      }
      if (content.contains('learn') || content.contains('study')) {
        personas['Learner'] = (personas['Learner'] ?? 0) + 1;
      }
    }

    final dominantPersona = personas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (dominantPersona.isEmpty) {
      return 'Your dream persona is adaptable and versatile.';
    }

    final persona = dominantPersona[0].key;
    final count = dominantPersona[0].value;
    return 'Your dream persona is primarily that of a $persona ($count occurrences), suggesting this role resonates strongly with your subconscious mind.';
  }

  static Map<String, List<String>> _generatePersonaEvidence(
      List<PostsRecord> dreams) {
    final evidence = <String, List<String>>{};
    for (var dream in dreams) {
      final content = dream.dream.toLowerCase();
      final sentences = dream.dream.split(RegExp(r'[.!?]+'));

      if (content.contains('explore') || content.contains('adventure')) {
        _addEvidence(evidence, 'Explorer', sentences, ['explore', 'adventure']);
      }
      if (content.contains('help') || content.contains('save')) {
        _addEvidence(evidence, 'Helper', sentences, ['help', 'save']);
      }
      if (content.contains('create') || content.contains('build')) {
        _addEvidence(evidence, 'Creator', sentences, ['create', 'build']);
      }
      if (content.contains('learn') || content.contains('study')) {
        _addEvidence(evidence, 'Learner', sentences, ['learn', 'study']);
      }
    }

    return evidence;
  }

  static String _analyzeEnvironment(List<PostsRecord> dreams) {
    final Map<String, List<String>> environmentKeywords = {
      'Nature': [
        'nature',
        'forest',
        'ocean',
        'mountain',
        'beach',
        'river',
        'lake',
        'garden',
        'wilderness',
        'outdoors',
        'trees',
        'plants',
        'flowers',
        'sea',
        'jungle',
        'desert',
        'valley',
        'meadow',
        'waterfall'
      ],
      'Urban': [
        'city',
        'building',
        'street',
        'town',
        'downtown',
        'skyline',
        'apartment',
        'road',
        'skyscraper',
        'urban',
        'metropolis',
        'sidewalk',
        'alley',
        'traffic',
        'bridge',
        'mall',
        'store',
        'shop'
      ],
      'Home': [
        'home',
        'house',
        'room',
        'kitchen',
        'bedroom',
        'bathroom',
        'living room',
        'dining room',
        'basement',
        'attic',
        'garage',
        'porch',
        'yard',
        'garden',
        'apartment',
        'condo',
        'cabin',
        'dwelling'
      ],
      'Work/Study': [
        'school',
        'work',
        'office',
        'classroom',
        'university',
        'college',
        'library',
        'laboratory',
        'desk',
        'meeting',
        'conference',
        'study',
        'workplace',
        'job',
        'assignment',
        'project',
        'class'
      ],
      'Fantastical': [
        'castle',
        'kingdom',
        'magic',
        'fantasy',
        'space',
        'alien',
        'other world',
        'dimension',
        'mythical',
        'fairy',
        'dragon',
        'supernatural',
        'heaven',
        'underworld',
        'enchanted',
        'futuristic',
        'ancient'
      ],
      'Transport': [
        'car',
        'vehicle',
        'train',
        'bus',
        'airplane',
        'ship',
        'boat',
        'flying',
        'journey',
        'travel',
        'trip',
        'road',
        'highway',
        'path',
        'transit',
        'route',
        'commute',
        'voyage'
      ],
      'Liminal': [
        'hallway',
        'corridor',
        'doorway',
        'staircase',
        'elevator',
        'threshold',
        'gate',
        'portal',
        'entrance',
        'exit',
        'between',
        'transition',
        'bridge',
        'passage',
        'tunnel',
        'crossing',
        'border'
      ]
    };

    // Track environments and their scores
    final environments = <String, int>{};

    for (var dream in dreams) {
      final content = dream.dream.toLowerCase();
      final tags = dream.tags.toLowerCase();

      // Score each environment type
      for (var entry in environmentKeywords.entries) {
        int score = 0;
        for (var keyword in entry.value) {
          if (content.contains(keyword)) {
            score++;
          }
          if (tags.contains(keyword)) {
            score += 2; // Tags have higher weight
          }
        }

        if (score > 0) {
          environments[entry.key] = (environments[entry.key] ?? 0) + score;
        }
      }
    }

    final dominantEnvironment = environments.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (dominantEnvironment.isEmpty) {
      return 'Your dreams take place in varied or abstract environments without a clear dominant setting.';
    }

    final environment = dominantEnvironment[0].key;
    final count = dominantEnvironment[0].value;

    // Meaningful interpretations for each environment type
    Map<String, String> environmentInsights = {
      'Nature':
          'Your dreams frequently occur in natural settings ($count references), suggesting a deep connection to the natural world. This may reflect a desire for peace, renewal, or a return to simplicity. Nature in dreams often symbolizes growth, freedom, and your authentic self.',
      'Urban':
          'Urban environments dominate your dreams ($count references), which may reflect your engagement with social structures, civilization, and the complexities of modern life. City settings can symbolize opportunity, social dynamics, or the structured aspects of your thinking.',
      'Home':
          'Home settings appear frequently in your dreams ($count references), suggesting themes of security, identity, and personal space are important to you. Dream homes often represent your inner self, with different rooms symbolizing different aspects of your personality or life.',
      'Work/Study':
          'Work or educational environments feature prominently ($count references), reflecting focus on achievement, learning, or professional identity. These dreams may process your ambitions, intellectual growth, or anxieties about performance and responsibilities.',
      'Fantastical':
          'Your dreams often take place in fantastical or magical settings ($count references), indicating a rich imagination and possibly a desire to escape ordinary reality. These environments might represent your creative potential or exploration of possibilities beyond conventional boundaries.',
      'Transport':
          'Transportation settings and journeys appear frequently ($count references), symbolizing life transitions, personal progress, or changes you\'re experiencing. These dreams often reflect how you navigate through life and approach your goals.',
      'Liminal':
          'Transitional spaces like hallways, doorways, and thresholds appear often ($count references), suggesting you\'re in a period of transition or facing important life decisions. These in-between spaces represent thresholds between different states of being or phases of life.'
    };

    return environmentInsights[environment] ??
        'Your dreams frequently occur in $environment settings ($count references), suggesting this environment holds special significance for you.';
  }

  static Map<String, List<String>> _generateEnvironmentEvidence(
      List<PostsRecord> dreams) {
    final evidence = <String, List<String>>{};
    for (var dream in dreams) {
      final content = dream.dream.toLowerCase();
      final sentences = dream.dream.split(RegExp(r'[.!?]+'));

      if (content.contains('nature') ||
          content.contains('forest') ||
          content.contains('ocean')) {
        _addEvidence(
            evidence, 'Nature', sentences, ['nature', 'forest', 'ocean']);
      }
      if (content.contains('city') ||
          content.contains('building') ||
          content.contains('street')) {
        _addEvidence(
            evidence, 'Urban', sentences, ['city', 'building', 'street']);
      }
      if (content.contains('home') ||
          content.contains('house') ||
          content.contains('room')) {
        _addEvidence(evidence, 'Home', sentences, ['home', 'house', 'room']);
      }
      if (content.contains('school') ||
          content.contains('work') ||
          content.contains('office')) {
        _addEvidence(
            evidence, 'Work/Study', sentences, ['school', 'work', 'office']);
      }
    }

    return evidence;
  }

  static String _generateGrowthInsights(List<PostsRecord> dreams) {
    final Map<String, List<String>> growthKeywords = {
      'Learning': [
        'learn',
        'discover',
        'study',
        'knowledge',
        'wisdom',
        'understand',
        'insight',
        'enlighten',
        'education',
        'comprehend',
        'realize',
        'awareness',
        'epiphany',
        'grasp',
        'revelation'
      ],
      'Transformation': [
        'change',
        'transform',
        'evolve',
        'metamorphosis',
        'shift',
        'alter',
        'convert',
        'transition',
        'rebirth',
        'renewal',
        'development',
        'modification',
        'adjustment',
        'adaptation',
        'progression'
      ],
      'Overcoming Challenges': [
        'challenge',
        'overcome',
        'obstacle',
        'struggle',
        'difficulty',
        'hurdle',
        'problem',
        'hardship',
        'trial',
        'triumph',
        'victory',
        'success',
        'achievement',
        'accomplish',
        'resolve',
        'surmount',
        'conquer'
      ],
      'Self-Discovery': [
        'identity',
        'self',
        'who am i',
        'authentic',
        'true self',
        'inner',
        'core',
        'essence',
        'soul',
        'spirit',
        'purpose',
        'meaning',
        'reflection',
        'mirror',
        'introspection',
        'examination',
        'recognize myself',
        'understand myself'
      ],
      'Healing': [
        'heal',
        'recover',
        'mend',
        'restore',
        'therapy',
        'wholeness',
        'health',
        'well-being',
        'coping',
        'treatment',
        'rehabilitation',
        'renewal',
        'rejuvenation',
        'revitalization',
        'care',
        'remedy',
        'alleviate'
      ],
      'Connection': [
        'connect',
        'relationship',
        'bond',
        'attachment',
        'together',
        'unity',
        'friendship',
        'love',
        'family',
        'community',
        'belonging',
        'alliance',
        'partnership',
        'association',
        'network',
        'link',
        'tie'
      ],
      'Creation': [
        'create',
        'build',
        'make',
        'design',
        'craft',
        'construct',
        'produce',
        'develop',
        'generate',
        'form',
        'shape',
        'fabricate',
        'manufacture',
        'compose',
        'author',
        'invent',
        'innovate'
      ]
    };

    // Track growth themes and their scores
    final themes = <String, int>{};

    for (var dream in dreams) {
      final content = dream.dream.toLowerCase();
      final tags = dream.tags.toLowerCase();

      // Score each growth theme
      for (var entry in growthKeywords.entries) {
        int score = 0;
        for (var keyword in entry.value) {
          RegExp wordPattern = RegExp(r'\b' + keyword + r'\b');
          final matches = wordPattern.allMatches(content);
          score += matches.length;

          if (tags.contains(keyword)) {
            score += 2; // Tags have higher weight
          }
        }

        if (score > 0) {
          themes[entry.key] = (themes[entry.key] ?? 0) + score;
        }
      }
    }

    final dominantTheme = themes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (dominantTheme.isEmpty) {
      return 'Your dreams suggest you are in a period of stability, with no dominant growth themes emerging.';
    }

    final theme = dominantTheme[0].key;
    final count = dominantTheme[0].value;

    // Personalized growth insights for each theme
    Map<String, String> growthInsights = {
      'Learning':
          'Your dreams prominently feature themes of learning and discovery ($count references), suggesting intellectual growth is important to you right now. Your subconscious may be encouraging you to pursue new knowledge or skills that will expand your horizons.',
      'Transformation':
          'Transformation appears as a significant theme in your dreams ($count references), indicating you may be going through or preparing for important life changes. These dreams reflect your capacity for growth and adaptation during periods of transition.',
      'Overcoming Challenges':
          'Your dreams frequently show you facing and overcoming obstacles ($count references), reflecting inner resilience and determination. This suggests you have the internal resources to address current challenges, even if they seem difficult in your waking life.',
      'Self-Discovery':
          'Self-discovery emerges as a key theme ($count references), suggesting you\'re in a period of identity exploration or reconnection with your authentic self. Your dreams are inviting you to better understand who you truly are and what matters most to you.',
      'Healing':
          'Healing appears prominently in your dreams ($count references), which may indicate recovery from past difficulties or a focus on improving your wellbeing. These dreams support your journey toward wholeness and resolution of unresolved issues.',
      'Connection':
          'Themes of connection and relationship appear consistently ($count references), highlighting the importance of your social bonds. Your dreams suggest that meaningful interactions with others play a significant role in your personal development right now.',
      'Creation':
          'Creative themes dominate your dreams ($count references), reflecting your capacity for innovation and bringing new ideas into reality. Your subconscious is highlighting your ability to shape your circumstances and express yourself authentically.'
    };

    return growthInsights[theme] ??
        'Your dreams indicate a focus on $theme ($count references), suggesting this area is important for your personal development.';
  }

  static Map<String, List<String>> _generateGrowthEvidence(
      List<PostsRecord> dreams) {
    final evidence = <String, List<String>>{};
    for (var dream in dreams) {
      final content = dream.dream.toLowerCase();
      final sentences = dream.dream.split(RegExp(r'[.!?]+'));

      if (content.contains('learn') || content.contains('discover')) {
        _addEvidence(evidence, 'Learning', sentences, ['learn', 'discover']);
      }
      if (content.contains('change') || content.contains('transform')) {
        _addEvidence(
            evidence, 'Transformation', sentences, ['change', 'transform']);
      }
      if (content.contains('challenge') || content.contains('overcome')) {
        _addEvidence(evidence, 'Overcoming Challenges', sentences,
            ['challenge', 'overcome']);
      }
      if (content.contains('create') || content.contains('build')) {
        _addEvidence(evidence, 'Creation', sentences, ['create', 'build']);
      }
    }

    return evidence;
  }

  static String _generateRecommendedActions(List<PostsRecord> dreams) {
    // Extract meaningful patterns from dreams
    final moods = <String, int>{};
    final environments = <String, int>{};
    final challenges = <String, int>{};
    final symbols = <String, List<String>>{};

    for (var dream in dreams) {
      final content = dream.dream.toLowerCase();

      // Extract mood
      final mood = _extractMoodFromDream(dream);
      moods[mood] = (moods[mood] ?? 0) + 1;

      // Track environments
      if (content.contains('nature') || content.contains('outdoor')) {
        environments['Nature'] = (environments['Nature'] ?? 0) + 1;
      }
      if (content.contains('home') || content.contains('house')) {
        environments['Home'] = (environments['Home'] ?? 0) + 1;
      }
      if (content.contains('work') || content.contains('office')) {
        environments['Work'] = (environments['Work'] ?? 0) + 1;
      }

      // Track challenges
      if (content.contains('avoid') ||
          content.contains('escape') ||
          content.contains('run')) {
        challenges['Avoidance'] = (challenges['Avoidance'] ?? 0) + 1;
      }
      if (content.contains('conflict') ||
          content.contains('argument') ||
          content.contains('fight')) {
        challenges['Conflict'] = (challenges['Conflict'] ?? 0) + 1;
      }
      if (content.contains('lost') ||
          content.contains('searching') ||
          content.contains('find')) {
        challenges['Seeking'] = (challenges['Seeking'] ?? 0) + 1;
      }

      // Track symbols (basic implementation)
      final commonSymbols = [
        'water',
        'flying',
        'falling',
        'door',
        'key',
        'child',
        'animal',
        'death',
        'money',
        'vehicle',
        'school',
        'test'
      ];

      for (var symbol in commonSymbols) {
        if (content.contains(symbol)) {
          if (!symbols.containsKey(symbol)) {
            symbols[symbol] = [];
          }
          var sentences = dream.dream.split(RegExp(r'[.!?]'));
          for (var sentence in sentences) {
            if (sentence.toLowerCase().contains(symbol)) {
              symbols[symbol]!.add(sentence.trim());
              break;
            }
          }
        }
      }
    }

    // Generate personalized recommendations based on patterns
    final recommendations = <String>[];

    // Add mood-based recommendations
    final dominantMood = moods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (dominantMood.isNotEmpty) {
      final mood = dominantMood[0].key;

      Map<String, String> moodRecommendations = {
        'Happy':
            'Your dreams show positive emotions. Consider keeping a gratitude journal to further enhance this positive mindset.',
        'Sad':
            'Your dreams reflect sadness. Consider journaling about unresolved emotions or speaking with a trusted friend or therapist.',
        'Fearful':
            'Your dreams show anxiety themes. Practice relaxation techniques before bed, like deep breathing or guided meditation.',
        'Peaceful':
            'Your dreams reflect tranquility. Continue mindfulness practices that foster this sense of peace.',
        'Confused':
            'Your dreams show confusion. Try organizing your thoughts through structured journaling or mind mapping exercises.',
        'Angry':
            'Your dreams reflect frustration. Consider physical activities that help release tension, like exercise or creative expression.',
        'Excited':
            'Your dreams show enthusiasm. Channel this energy into creative projects or planning future endeavors.',
        'Nostalgic':
            'Your dreams reflect connection to the past. Explore family history or reconnect with people from your past in a positive way.'
      };

      if (moodRecommendations.containsKey(mood)) {
        recommendations.add(moodRecommendations[mood]!);
      }
    }

    // Add environment-based recommendations
    final dominantEnvironment = environments.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (dominantEnvironment.isNotEmpty) {
      final environment = dominantEnvironment[0].key;

      Map<String, String> environmentRecommendations = {
        'Nature':
            'Your dreams feature natural settings. Consider spending more time outdoors to enhance your connection with nature.',
        'Home':
            'Home environments appear frequently in your dreams. Create a more nurturing living space that reflects your ideal sanctuary.',
        'Work':
            'Work settings appear in your dreams. Evaluate your work-life balance and consider ways to make your workspace more positive.'
      };

      if (environmentRecommendations.containsKey(environment)) {
        recommendations.add(environmentRecommendations[environment]!);
      }
    }

    // Add challenge-based recommendations
    final dominantChallenge = challenges.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (dominantChallenge.isNotEmpty) {
      final challenge = dominantChallenge[0].key;

      Map<String, String> challengeRecommendations = {
        'Avoidance':
            'Your dreams suggest you may be avoiding something. Consider facing one small challenge directly rather than postponing it.',
        'Conflict':
            'Your dreams feature conflict. Practice communication techniques that help express your needs assertively but diplomatically.',
        'Seeking':
            'Your dreams show searching themes. Reflect on what you might be seeking in your waking life, whether it\'s purpose, answers, or closure.'
      };

      if (challengeRecommendations.containsKey(challenge)) {
        recommendations.add(challengeRecommendations[challenge]!);
      }
    }

    // Add symbol-based recommendations if we have meaningful symbols
    if (symbols.isNotEmpty) {
      Map<String, String> symbolRecommendations = {
        'water':
            'Water in dreams symbolizes emotions. Consider activities that help process your feelings.',
        'flying':
            'Flying suggests desire for freedom. Find ways to experience more autonomy in restricted areas of life.',
        'falling':
            'Falling indicates feeling out of control. Practice grounding techniques when overwhelmed.',
        'door':
            'Doors represent opportunities or transitions. Stay open to new possibilities.',
        'key':
            'Keys suggest solutions are available. Try approaching problems from a different angle.',
        'child':
            'Children in dreams represent innocence or new beginnings. Nurture your creative or playful side.',
        'animal':
            'Animals symbolize instincts or traits you identify with. Consider what qualities these animals represent to you.',
        'death':
            'Death often symbolizes transformation or endings, not literal death. Embrace necessary changes in your life.',
        'money':
            'Money represents value or self-worth. Examine your relationship with personal resources and value.',
        'vehicle':
            'Vehicles show how you navigate life\'s journey. Consider if you feel in control of your direction.',
        'school':
            'School settings relate to learning or evaluation. Identify areas where you feel tested or need to grow.',
        'test':
            'Tests suggest you feel evaluated or unprepared. Address areas where you feel inadequate.'
      };

      for (var symbol in symbols.keys) {
        if (symbolRecommendations.containsKey(symbol)) {
          recommendations.add(symbolRecommendations[symbol]!);
          break; // Just add one symbol recommendation to avoid overloading
        }
      }
    }

    // Add a general recommendation if we have fewer than 2 specific ones
    if (recommendations.isEmpty) {
      recommendations.add(
          'Consider keeping a dream journal beside your bed to record dreams immediately upon waking, which can enhance your dream recall and recognition of patterns.');
      recommendations.add(
          'Practice a brief meditation before sleep, focusing on your intention to remember your dreams more vividly.');
    } else if (recommendations.length < 2) {
      recommendations.add(
          'Regularly review your dream journal to identify recurring patterns and insights that may not be immediately obvious.');
    }

    // Combine recommendations into a coherent paragraph
    return recommendations.join(' ');
  }

  static Map<String, List<String>> _generateActionEvidence(
      List<PostsRecord> dreams) {
    final evidence = <String, List<String>>{};
    for (var dream in dreams) {
      final content = dream.dream.toLowerCase();
      final sentences = dream.dream.split(RegExp(r'[.!?]+'));

      if (content.contains('learn') || content.contains('study')) {
        _addEvidence(evidence, 'Learning', sentences, ['learn', 'study']);
      }
      if (content.contains('explore') || content.contains('adventure')) {
        _addEvidence(
            evidence, 'Exploration', sentences, ['explore', 'adventure']);
      }
      if (content.contains('create') || content.contains('build')) {
        _addEvidence(evidence, 'Creation', sentences, ['create', 'build']);
      }
      if (content.contains('help') || content.contains('support')) {
        _addEvidence(
            evidence, 'Helping Others', sentences, ['help', 'support']);
      }
    }

    return evidence;
  }

  static void _addEvidence(Map<String, List<String>> evidence, String category,
      List<String> sentences, List<String> keywords) {
    if (!evidence.containsKey(category)) {
      evidence[category] = [];
    }

    for (var sentence in sentences) {
      final lowerSentence = sentence.toLowerCase();
      if (keywords.any((keyword) => lowerSentence.contains(keyword))) {
        evidence[category]!.add(sentence.trim());
      }
    }
  }
}
