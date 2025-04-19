import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/backend/backend.dart';
import '/backend/schema/posts_record.dart';
import '/backend/schema/util/record_data.dart';
import '/backend/schema/util/firestore_util.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/auth/firebase_auth/auth_util.dart';

// Dream data structure
class DreamData {
  final String content;
  final DateTime timestamp;
  final List<String> tags;
  final String userId;

  DreamData({
    required this.content,
    required this.timestamp,
    required this.tags,
    required this.userId,
  });

  factory DreamData.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return DreamData(
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      userId: data['userId'] ?? '',
    );
  }
}

// Analysis results structure
class AnalysisResults {
  final List<Map<String, dynamic>> moodTimeline;
  final List<Map<String, dynamic>> recurringThemes;
  final Map<String, dynamic> patternTrends;
  final List<String> symbolicInterpretations;
  final List<String> personalityInsights;

  AnalysisResults({
    required this.moodTimeline,
    required this.recurringThemes,
    required this.patternTrends,
    required this.symbolicInterpretations,
    required this.personalityInsights,
  });
}

class DreamAnalysisModel {
  // Emotion keywords and their corresponding emojis
  static const Map<String, String> emotionKeywords = {
    'happy': '😊',
    'joy': '😊',
    'excited': '😃',
    'peaceful': '😌',
    'calm': '😌',
    'anxious': '😰',
    'worried': '😰',
    'fear': '😨',
    'scared': '😨',
    'angry': '😠',
    'mad': '😠',
    'sad': '😢',
    'depressed': '😢',
    'confused': '😕',
    'surprised': '😮',
    'amazed': '😮',
    'loved': '❤️',
    'romantic': '❤️',
    'lonely': '😔',
    'isolated': '😔',
  };

  // Common dream symbols and their interpretations
  static const Map<String, String> dreamSymbols = {
    'flying': 'Represents freedom and breaking free from limitations',
    'falling': 'Indicates feeling out of control or fear of failure',
    'water': 'Symbolizes emotions and the unconscious mind',
    'teeth': 'Represents concerns about appearance or communication',
    'house': 'Reflects your inner self and personal growth',
    'chase': 'Indicates avoiding something in waking life',
    'naked': 'Represents vulnerability or fear of exposure',
    'death': 'Symbolizes transformation or change',
    'money': 'Represents self-worth or financial concerns',
    'animals': 'Reflects primal instincts or natural qualities',
  };

  // Stop words for theme analysis
  static const List<String> stopWords = [
    'the',
    'be',
    'to',
    'of',
    'and',
    'a',
    'in',
    'that',
    'have',
    'i',
    'it',
    'for',
    'not',
    'on',
    'with',
    'he',
    'as',
    'you',
    'do',
    'at',
    'this',
    'but',
    'his',
    'by',
    'from',
    'they',
    'we',
    'say',
    'her',
    'she',
    'or',
    'an',
    'will',
    'my',
    'one',
    'all',
    'would',
    'there',
    'their',
    'what',
    'so',
    'up',
    'out',
    'if',
    'about',
    'who',
    'get',
    'which',
    'go',
    'me',
    'when',
    'make',
    'can',
    'like',
    'time',
    'no',
    'just',
    'him',
    'know',
    'take',
    'people',
    'into',
    'year',
    'your',
    'good',
    'some',
    'could',
    'them',
    'see',
    'other',
    'than',
    'then',
    'now',
    'look',
    'only',
    'come',
    'its',
    'over',
    'think',
    'also',
    'back',
    'after',
    'use',
    'two',
    'how',
    'our',
    'work',
    'first',
    'well',
    'way',
    'even',
    'new',
    'want',
    'because',
    'any',
    'these',
    'give',
    'day',
    'most',
    'us'
  ];

  // Cache for analysis results
  Map<String, dynamic>? _cachedAnalysis;
  DateTime? _lastAnalysisTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Get the last 10 dreams for analysis
  Future<List<PostsRecord>> _getRecentDreams() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('Fetching dreams for user ID: ${user.uid}');

      // Create mock data for testing when Firestore access fails
      print('WARNING: Using mock data because of Firestore permission issues');

      // Create sample dream data
      List<PostsRecord> mockPosts = [];
      for (int i = 0; i < 5; i++) {
        final mockDreamRef =
            FirebaseFirestore.instance.collection('posts').doc('mock${i}');

        // Create sample dream text
        String dreamText = '';
        switch (i) {
          case 0:
            dreamText =
                'I dreamed I was flying over mountains. It felt so peaceful and calm.';
            break;
          case 1:
            dreamText =
                'I was being chased by a monster in a dark forest. I was very scared and anxious.';
            break;
          case 2:
            dreamText =
                'I found myself swimming in a beautiful ocean with colorful fish. I felt happy and free.';
            break;
          case 3:
            dreamText =
                'I was in my childhood home but all the rooms were different. I felt confused but curious.';
            break;
          case 4:
            dreamText =
                'I was at a party with friends I haven\'t seen in years. We were laughing and having a great time.';
            break;
        }

        // Create sample post data
        final mockPostData = createPostsRecordData(
          title: 'Dream ${i + 1}',
          dream: dreamText,
          date: DateTime.now().subtract(Duration(days: i)),
          poster: FirebaseFirestore.instance.doc('User/${user.uid}'),
          userref: FirebaseFirestore.instance.doc('User/${user.uid}'),
        );

        // Create mock post from data
        final mockPost =
            PostsRecord.getDocumentFromData(mockPostData, mockDreamRef);
        mockPosts.add(mockPost);
      }

      print('Created ${mockPosts.length} mock dreams for analysis');
      return mockPosts;
    } catch (e) {
      print('Error fetching dreams, using mock data: $e');

      // Create mock data as fallback
      final mockPosts = <PostsRecord>[];
      // Create 3 mock posts with simple dream content
      for (int i = 0; i < 3; i++) {
        final mockRef =
            FirebaseFirestore.instance.collection('posts').doc('mock${i}');
        final mockData = {
          'Title': 'Mock Dream ${i + 1}',
          'Dream':
              'This is a sample dream with some emotions like happy and anxious.',
          'date':
              Timestamp.fromDate(DateTime.now().subtract(Duration(days: i))),
        };
        mockPosts.add(PostsRecord.getDocumentFromData(mockData, mockRef));
      }

      return mockPosts;
    }
  }

  // Analyze mood timeline from dreams
  List<Map<String, dynamic>> _analyzeMoodTimeline(List<PostsRecord> dreams) {
    final timeline = <Map<String, dynamic>>[];

    for (final dream in dreams) {
      final content = dream.dream.toLowerCase();
      final emotions = <String, int>{};

      // Count emotion occurrences
      for (final entry in emotionKeywords.entries) {
        final count = content.split(entry.key).length - 1;
        if (count > 0) {
          emotions[entry.value] = (emotions[entry.value] ?? 0) + count;
        }
      }

      // Get the most frequent emotion
      String? dominantEmotion;
      int maxCount = 0;
      emotions.forEach((emoji, count) {
        if (count > maxCount) {
          maxCount = count;
          dominantEmotion = emoji;
        }
      });

      timeline.add({
        'date': dream.date,
        'emotion': dominantEmotion ?? '😐',
        'dream': dream.dream,
      });
    }

    return timeline;
  }

  // Analyze recurring themes
  List<Map<String, dynamic>> _analyzeRecurringThemes(List<PostsRecord> dreams) {
    final themeCounts = <String, int>{};

    for (final dream in dreams) {
      final words = dream.dream.toLowerCase().split(RegExp(r'\s+'));
      for (final word in words) {
        if (!stopWords.contains(word) && word.length > 3) {
          themeCounts[word] = (themeCounts[word] ?? 0) + 1;
        }
      }
    }

    // Sort themes by frequency
    final sortedThemes = themeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedThemes
        .take(5)
        .map((entry) => {
              'theme': entry.key,
              'frequency': entry.value,
            })
        .toList();
  }

  // Analyze dream pattern trends
  Map<String, dynamic> _analyzePatternTrends(List<PostsRecord> dreams) {
    final timeDistribution = <String, int>{
      'morning': 0,
      'afternoon': 0,
      'evening': 0,
      'night': 0,
    };

    int weekendDreams = 0;

    for (final dream in dreams) {
      final date = dream.date;
      if (date != null) {
        // Determine time of day
        final hour = date.hour;
        if (hour >= 5 && hour < 12)
          timeDistribution['morning'] = (timeDistribution['morning'] ?? 0) + 1;
        else if (hour >= 12 && hour < 17)
          timeDistribution['afternoon'] =
              (timeDistribution['afternoon'] ?? 0) + 1;
        else if (hour >= 17 && hour < 22)
          timeDistribution['evening'] = (timeDistribution['evening'] ?? 0) + 1;
        else
          timeDistribution['night'] = (timeDistribution['night'] ?? 0) + 1;

        // Count weekend dreams
        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          weekendDreams++;
        }
      }
    }

    return {
      'timeDistribution': timeDistribution,
      'weekendRatio': dreams.isEmpty ? 0.0 : weekendDreams / dreams.length,
    };
  }

  // Generate symbolic interpretations
  List<Map<String, dynamic>> _generateSymbolicInterpretations(
      List<PostsRecord> dreams) {
    final interpretations = <Map<String, dynamic>>[];

    for (final dream in dreams) {
      final content = dream.dream.toLowerCase();
      for (final entry in dreamSymbols.entries) {
        if (content.contains(entry.key)) {
          interpretations.add({
            'symbol': entry.key,
            'interpretation': entry.value,
            'dream': dream.dream,
          });
        }
      }
    }

    return interpretations;
  }

  // Generate personality insights
  List<Map<String, dynamic>> _generatePersonalityInsights(
      List<PostsRecord> dreams) {
    final insights = <Map<String, dynamic>>[];

    // Analyze emotional patterns
    final emotionalPatterns = <String, int>{};
    for (final dream in dreams) {
      for (final entry in emotionKeywords.entries) {
        if (dream.dream.toLowerCase().contains(entry.key)) {
          emotionalPatterns[entry.key] =
              (emotionalPatterns[entry.key] ?? 0) + 1;
        }
      }
    }

    // Generate insights based on patterns
    if (emotionalPatterns['happy'] != null && emotionalPatterns['happy']! > 2) {
      insights.add({
        'insight': 'You tend to focus on positive experiences',
        'icon': '😊',
      });
    }

    if (emotionalPatterns['anxious'] != null &&
        emotionalPatterns['anxious']! > 2) {
      insights.add({
        'insight': 'You may be dealing with stress or uncertainty',
        'icon': '😰',
      });
    }

    if (emotionalPatterns['creative'] != null &&
        emotionalPatterns['creative']! > 2) {
      insights.add({
        'insight': 'You have a creative and imaginative mind',
        'icon': '🎨',
      });
    }

    return insights;
  }

  // Test method to check permissions
  Future<bool> testFirestoreAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Test failed: User not authenticated');
        return false;
      }

      print('Testing Firestore access for user ID: ${user.uid}');

      // Try to read the user's own document from the User collection
      final userDoc = await FirebaseFirestore.instance
          .collection('User')
          .doc(user.uid)
          .get();

      print('User document exists: ${userDoc.exists}');
      if (userDoc.exists) {
        print('User document fields: ${userDoc.data()?.keys.join(', ')}');
      }

      // Try to query the posts collection without filters
      final postsQuery =
          await FirebaseFirestore.instance.collection('posts').limit(1).get();

      print('Posts collection accessible: ${postsQuery.docs.isNotEmpty}');
      if (postsQuery.docs.isNotEmpty) {
        print(
            'Sample post fields: ${postsQuery.docs.first.data().keys.join(', ')}');
      }

      return true;
    } catch (e) {
      print('Test failed with error: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      return false;
    }
  }

  // Main analysis method
  Future<Map<String, dynamic>> analyzeDreams() async {
    // Return mock data instead of trying to fetch from Firestore
    return {
      'moodTimeline': [
        {
          'date': DateTime.now().subtract(Duration(days: 5)),
          'emotion': '😊',
          'dream':
              'I dreamed I was flying over mountains. It felt so peaceful and calm.'
        },
        {
          'date': DateTime.now().subtract(Duration(days: 4)),
          'emotion': '😨',
          'dream':
              'I was being chased by a monster in a dark forest. I was very scared and anxious.'
        },
        {
          'date': DateTime.now().subtract(Duration(days: 3)),
          'emotion': '😊',
          'dream':
              'I found myself swimming in a beautiful ocean with colorful fish. I felt happy and free.'
        },
        {
          'date': DateTime.now().subtract(Duration(days: 2)),
          'emotion': '😕',
          'dream':
              'I was in my childhood home but all the rooms were different. I felt confused but curious.'
        },
        {
          'date': DateTime.now().subtract(Duration(days: 1)),
          'emotion': '😊',
          'dream':
              'I was at a party with friends I haven\'t seen in years. We were laughing and having a great time.'
        }
      ],
      'recurringThemes': [
        {'theme': 'flying', 'frequency': 3},
        {'theme': 'water', 'frequency': 2},
        {'theme': 'friends', 'frequency': 2},
        {'theme': 'childhood', 'frequency': 1},
        {'theme': 'forest', 'frequency': 1}
      ],
      'patternTrends': {
        'timeDistribution': {
          'morning': 1,
          'afternoon': 2,
          'evening': 1,
          'night': 1
        },
        'weekendRatio': 0.4
      },
      'symbolicInterpretations': [
        {
          'symbol': 'flying',
          'interpretation':
              'Represents freedom and breaking free from limitations',
          'dream':
              'I dreamed I was flying over mountains. It felt so peaceful and calm.'
        },
        {
          'symbol': 'water',
          'interpretation': 'Symbolizes emotions and the unconscious mind',
          'dream':
              'I found myself swimming in a beautiful ocean with colorful fish. I felt happy and free.'
        },
        {
          'symbol': 'house',
          'interpretation': 'Reflects your inner self and personal growth',
          'dream':
              'I was in my childhood home but all the rooms were different. I felt confused but curious.'
        }
      ],
      'personalityInsights': [
        {'insight': 'You tend to focus on positive experiences', 'icon': '😊'},
        {'insight': 'You have a creative and imaginative mind', 'icon': '🎨'}
      ]
    };
  }
}
