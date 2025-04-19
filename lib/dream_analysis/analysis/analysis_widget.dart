import '/backend/backend.dart';
import '/backend/schema/dream_analysis_record.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/services/dream_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:ui';

/// Create a Dream Analysis Page with a dark, starry night theme.
///
/// Include these sections:
///
/// Mood Analysis: Pie chart showing dream emotions.
/// Mood Timeline: Line graph tracking mood over time.
/// Top Keywords: Word cloud or chips for common keywords.
/// Dream Category: Cards labeling the dream type (e.g., Nightmare,
/// Adventure).
/// Dream Frequency: Bar chart showing how often dreams are logged.
/// Dream Persona: Fun persona card (e.g., "Lucid Explorer").
/// Dream Insight: Motivational AI-generated prediction.
class AnalysisWidget extends StatefulWidget {
  const AnalysisWidget({super.key});

  static String routeName = 'Analysis';
  static String routePath = '/analysis';

  @override
  State<AnalysisWidget> createState() => _AnalysisWidgetState();
}

class _AnalysisWidgetState extends State<AnalysisWidget>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _debounceTimer;
  bool _isLoading = false;
  bool _isLoadingAnalysis = false;
  bool _isNavigating = false;
  bool _isTransitioning = false;
  bool _isStateLocked = false;
  bool _isDisposed = false;
  DreamAnalysisRecord? _latestAnalysis;
  List<PostsRecord> _recentDreams = [];
  Map<String, dynamic>? _moodTimeline;
  Map<String, dynamic>? _dreamFrequency;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Theme values
  static const Color _primaryColor = Color(0xFF4B39EF);
  static const Color _secondaryColor = Color(0xFF39D2C0);
  static const Color _accentColor = Color(0xFFFF6B6B);
  static const Color _backgroundColor = Color(0xFF1A1A1A);
  static const Color _cardBackgroundColor = Color(0x1AFFFFFF);
  static const Color _textColor = Colors.white;
  static const Color _textSecondaryColor = Color(0xB3FFFFFF);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();

    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (mounted && !_isDisposed) {
        _loadAnalysis();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _isDisposed = true;
    super.dispose();
  }

  void _setState(VoidCallback fn) {
    if (!_isDisposed &&
        !_isNavigating &&
        !_isTransitioning &&
        !_isStateLocked &&
        mounted) {
      setState(fn);
    }
  }

  Future<void> _loadAnalysis() async {
    if (_isDisposed ||
        _isNavigating ||
        _isTransitioning ||
        _isStateLocked ||
        !mounted) return;

    _setState(() {
      _isLoading = true;
      _isLoadingAnalysis = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      final userRef =
          FirebaseFirestore.instance.collection('User').doc(currentUser.uid);

      // Get recent dreams
      final dreamsQuery = await PostsRecord.collection
          .where('userref', isEqualTo: userRef)
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      _setState(() {
        _recentDreams = dreamsQuery.docs
            .map((doc) => PostsRecord.fromSnapshot(doc))
            .toList();
      });

      // Check for existing analysis
      final analysisQuery = await DreamAnalysisRecord.collection
          .where('userref', isEqualTo: userRef)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (!mounted) return;

      if (analysisQuery.docs.isNotEmpty) {
        _setState(() {
          _latestAnalysis =
              DreamAnalysisRecord.fromSnapshot(analysisQuery.docs.first);
        });
      } else if (_recentDreams.isNotEmpty) {
        try {
          final newAnalysis =
              await DreamAnalysisService.analyzeDream(_recentDreams);
          if (!mounted) return;
          _setState(() {
            _latestAnalysis = newAnalysis;
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating dream analysis: $e')),
          );
        }
      }

      // Generate mood timeline and frequency
      if (_recentDreams.isNotEmpty) {
        try {
          final timeline =
              await DreamAnalysisService.generateMoodTimeline(_recentDreams);
          final frequency =
              await DreamAnalysisService.calculateDreamFrequency(_recentDreams);
          if (!mounted) return;
          _setState(() {
            _moodTimeline = timeline;
            _dreamFrequency = frequency;
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating dream statistics: $e')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dream analysis: $e')),
      );
    } finally {
      if (!mounted) return;
      _setState(() {
        _isLoading = false;
        _isLoadingAnalysis = false;
      });
    }
  }

  Future<void> _handleNavigation() async {
    if (_isLoadingAnalysis || _isNavigating || _isTransitioning) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please wait while analysis is loading...')),
      );
      return;
    }

    setState(() {
      _isNavigating = true;
      _isTransitioning = true;
      _isStateLocked = true;
    });

    if (!mounted) return;

    // Clean up resources
    _debounceTimer?.cancel();
    _animationController.stop();

    // Ensure we're not in a build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _handleRefresh() async {
    if (_isLoadingAnalysis || _isNavigating || _isTransitioning) return;

    _setState(() {
      _isLoadingAnalysis = true;
    });

    try {
      if (_latestAnalysis != null) {
        await _latestAnalysis!.reference.delete();
      }
      await _loadAnalysis();
    } finally {
      if (mounted) {
        _setState(() {
          _isLoadingAnalysis = false;
        });
      }
    }
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(borderRadius ?? 20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMoodAnalysis() {
    if (_latestAnalysis == null) return Container();

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.mood, color: _primaryColor),
              ),
              SizedBox(width: 12),
              Text(
                'Mood Analysis',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _latestAnalysis!.moodAnalysis ?? 'No mood analysis available',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 16,
            ),
          ),
          if (_latestAnalysis!.hasMoodEvidence()) ...[
            SizedBox(height: 16),
            Text(
              'Evidence from your dreams:',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            ..._latestAnalysis!.moodEvidence.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    ...entry.value.map((text) => Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $text',
                            style: TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        )),
                    SizedBox(height: 8),
                  ],
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildDreamCategories() {
    if (_dreamFrequency == null) return Container();

    final categories = _dreamFrequency!['categories'] as Map<String, int>;
    if (categories.isEmpty) {
      return _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _secondaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.category, color: _secondaryColor),
                ),
                SizedBox(width: 12),
                Text(
                  'Dream Categories',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'No dream categories available yet. Start recording your dreams to see them categorized here.',
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final total = categories.values.fold(0, (sum, count) => sum + count);

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _secondaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.category, color: _secondaryColor),
              ),
              SizedBox(width: 12),
              Text(
                'Dream Categories',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...categories.entries.map((entry) {
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: entry.value / total,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(_secondaryColor),
                    minHeight: 8,
                  ),
                ),
                SizedBox(height: 12),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDreamPersona() {
    if (_latestAnalysis == null) return Container();

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person, color: _accentColor),
              ),
              SizedBox(width: 12),
              Text(
                'Your Dream Persona',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _latestAnalysis!.dreamPersona ?? 'No persona available',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 16,
            ),
          ),
          if (_latestAnalysis!.hasPersonaEvidence()) ...[
            SizedBox(height: 16),
            Text(
              'Evidence from your dreams:',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            ..._latestAnalysis!.personaEvidence.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    ...entry.value.map((text) => Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $text',
                            style: TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        )),
                    SizedBox(height: 8),
                  ],
                )),
          ],
          SizedBox(height: 16),
          Text(
            'Dream Environment',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _latestAnalysis!.dreamEnvironment ??
                'No environment details available',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 16,
            ),
          ),
          if (_latestAnalysis!.hasEnvironmentEvidence()) ...[
            SizedBox(height: 16),
            Text(
              'Evidence from your dreams:',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            ..._latestAnalysis!.environmentEvidence.entries
                .map((entry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        ...entry.value.map((text) => Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $text',
                                style: TextStyle(
                                  color: _textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            )),
                        SizedBox(height: 8),
                      ],
                    )),
          ],
        ],
      ),
    );
  }

  Widget _buildDreamInsights() {
    if (_latestAnalysis == null) return Container();

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lightbulb, color: _primaryColor),
              ),
              SizedBox(width: 12),
              Text(
                'Dream Insights',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _latestAnalysis!.personalGrowthInsights ?? 'No insights available',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 16,
            ),
          ),
          if (_latestAnalysis!.hasGrowthEvidence()) ...[
            SizedBox(height: 16),
            Text(
              'Evidence from your dreams:',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            ..._latestAnalysis!.growthEvidence.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    ...entry.value.map((text) => Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $text',
                            style: TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        )),
                    SizedBox(height: 8),
                  ],
                )),
          ],
          SizedBox(height: 16),
          Text(
            'Recommended Actions',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _latestAnalysis!.recommendedActions ??
                'No recommendations available',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 16,
            ),
          ),
          if (_latestAnalysis!.hasActionEvidence()) ...[
            SizedBox(height: 16),
            Text(
              'Evidence from your dreams:',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            ..._latestAnalysis!.actionEvidence.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    ...entry.value.map((text) => Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $text',
                            style: TextStyle(
                              color: _textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        )),
                    SizedBox(height: 8),
                  ],
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildDreamGrowthActivities() {
    if (_latestAnalysis == null) return Container();

    // Generate personalized activities based on dream analysis
    List<Map<String, String>> personalizedActivities = [];

    // Activity 1: Based on mood analysis
    if (_latestAnalysis!.hasMoodAnalysis()) {
      String moodActivity = '';
      String moodTitle = '';

      if (_latestAnalysis!.moodAnalysis?.toLowerCase().contains('negative') ==
              true ||
          _latestAnalysis!.moodAnalysis?.toLowerCase().contains('fearful') ==
              true ||
          _latestAnalysis!.moodAnalysis?.toLowerCase().contains('sad') ==
              true) {
        moodTitle = 'Positive Visualization';
        moodActivity =
            'Before sleep, spend 5 minutes visualizing positive scenarios to help reshape your dream content. Focus on peaceful scenes, happy memories, or successful outcomes to challenges you\'re facing.';
      } else if (_latestAnalysis!.moodAnalysis
                  ?.toLowerCase()
                  .contains('peaceful') ==
              true ||
          _latestAnalysis!.moodAnalysis?.toLowerCase().contains('positive') ==
              true) {
        moodTitle = 'Dream Extension';
        moodActivity =
            'Your positive dream patterns are valuable! When you wake up from a pleasant dream, spend a few minutes with closed eyes, consciously extending the narrative. This can help reinforce positive dream patterns.';
      } else {
        moodTitle = 'Emotion Journaling';
        moodActivity =
            'Keep a separate emotion journal alongside your dream journal. Track your feelings before bed and upon waking to identify connections between your waking emotions and dream content.';
      }

      personalizedActivities
          .add({'title': moodTitle, 'description': moodActivity});
    }

    // Activity 2: Based on dream persona
    if (_latestAnalysis!.hasDreamPersona()) {
      String personaActivity = '';
      String personaTitle = '';

      if (_latestAnalysis!.dreamPersona?.toLowerCase().contains('explorer') ==
              true ||
          _latestAnalysis!.dreamPersona?.toLowerCase().contains('adventure') ==
              true) {
        personaTitle = 'Dream Map Creation';
        personaActivity =
            'Create a physical or digital "map" of your dream worlds. Each time you have an adventure dream, add the new locations. This can help you recognize patterns and potentially gain more control in future dreams.';
      } else if (_latestAnalysis!.dreamPersona
                  ?.toLowerCase()
                  .contains('observer') ==
              true ||
          _latestAnalysis!.dreamPersona?.toLowerCase().contains('passive') ==
              true) {
        personaTitle = 'Active Dreaming Exercise';
        personaActivity =
            'Practice making small decisions before bed. Visualize yourself taking action in various scenarios. This can help shift your dream persona from passive observer to active participant.';
      } else if (_latestAnalysis!.dreamPersona
                  ?.toLowerCase()
                  .contains('creative') ==
              true ||
          _latestAnalysis!.dreamPersona
                  ?.toLowerCase()
                  .contains('imaginative') ==
              true) {
        personaTitle = 'Creative Inspiration Capture';
        personaActivity =
            'Keep a sketchpad or voice recorder by your bed to quickly capture creative ideas from your dreams. Set an intention before sleep to bring back inspiration that you can use in your waking creative pursuits.';
      } else {
        personaTitle = 'Dream Role Play';
        personaActivity =
            'Before sleep, imagine yourself as the main character in a story. Set an intention to continue this narrative in your dreams, taking an active role in shaping the events.';
      }

      personalizedActivities
          .add({'title': personaTitle, 'description': personaActivity});
    }

    // Activity 3: Based on dream environment
    if (_latestAnalysis!.hasDreamEnvironment()) {
      String environmentActivity = '';
      String environmentTitle = '';

      if (_latestAnalysis!.dreamEnvironment
                  ?.toLowerCase()
                  .contains('natural') ==
              true ||
          _latestAnalysis!.dreamEnvironment
                  ?.toLowerCase()
                  .contains('outdoor') ==
              true) {
        environmentTitle = 'Nature Connection';
        environmentActivity =
            'Spend time in natural settings during the day and bring natural elements into your bedroom (plants, nature sounds, etc.). This can help deepen your connection to positive natural dream environments.';
      } else if (_latestAnalysis!.dreamEnvironment
                  ?.toLowerCase()
                  .contains('confined') ==
              true ||
          _latestAnalysis!.dreamEnvironment
                  ?.toLowerCase()
                  .contains('restrict') ==
              true) {
        environmentTitle = 'Spatial Freedom Practice';
        environmentActivity =
            'Practice mindfulness in open spaces during the day. Before sleep, visualize yourself in expansive, open environments. This can help counteract feelings of confinement in dreams.';
      } else if (_latestAnalysis!.dreamEnvironment
                  ?.toLowerCase()
                  .contains('childhood') ==
              true ||
          _latestAnalysis!.dreamEnvironment
                  ?.toLowerCase()
                  .contains('familiar') ==
              true) {
        environmentTitle = 'Memory Integration';
        environmentActivity =
            'Set aside time to mindfully reflect on positive childhood memories. Before sleep, intentionally revisit these places in your mind with an adult perspective, creating new associations.';
      } else {
        environmentTitle = 'Environment Design';
        environmentActivity =
            'Sketch or write about your ideal dream setting before bed. Focus on details like colors, sensations, and feelings. Set an intention to visit this place in your dreams.';
      }

      personalizedActivities
          .add({'title': environmentTitle, 'description': environmentActivity});
    }

    // Activity 4: Based on personal growth insights
    if (_latestAnalysis!.hasPersonalGrowthInsights()) {
      String growthActivity = '';
      String growthTitle = '';

      if (_latestAnalysis!.personalGrowthInsights
                  ?.toLowerCase()
                  .contains('stress') ==
              true ||
          _latestAnalysis!.personalGrowthInsights
                  ?.toLowerCase()
                  .contains('anxiety') ==
              true) {
        growthTitle = 'Stress Relief Technique';
        growthActivity =
            'Practice progressive muscle relaxation before sleep. Starting at your feet and moving upward, tense each muscle group for 5 seconds, then release. This can reduce stress that may be manifesting in your dreams.';
      } else if (_latestAnalysis!.personalGrowthInsights
                  ?.toLowerCase()
                  .contains('relationship') ==
              true ||
          _latestAnalysis!.personalGrowthInsights
                  ?.toLowerCase()
                  .contains('connect') ==
              true) {
        growthTitle = 'Dream Dialogue Practice';
        growthActivity =
            'Before sleep, imagine a constructive conversation with someone who appears in your dreams. Set an intention to continue this dialogue in your dreams, focusing on resolution and understanding.';
      } else if (_latestAnalysis!.personalGrowthInsights
                  ?.toLowerCase()
                  .contains('fear') ==
              true ||
          _latestAnalysis!.personalGrowthInsights
                  ?.toLowerCase()
                  .contains('conflict') ==
              true) {
        growthTitle = 'Courage Visualization';
        growthActivity =
            'Practice "brave response" visualizations before sleep. Imagine yourself confidently facing challenging situations that have appeared in your dreams, equipped with exactly what you need to overcome them.';
      } else {
        growthTitle = 'Growth Integration';
        growthActivity =
            'Write a brief reflection on how you\'ve grown or what you\'ve learned from recent experiences. Before sleep, set an intention to process these lessons in your dreams in a constructive way.';
      }

      personalizedActivities
          .add({'title': growthTitle, 'description': growthActivity});
    }

    // Activity 5: Based on recommended actions (or default if not available)
    if (_latestAnalysis!.hasRecommendedActions()) {
      String actionActivity = '';
      String actionTitle = '';

      if (_latestAnalysis!.recommendedActions
                  ?.toLowerCase()
                  .contains('lucid') ==
              true ||
          _latestAnalysis!.recommendedActions
                  ?.toLowerCase()
                  .contains('aware') ==
              true) {
        actionTitle = 'Lucidity Training';
        actionActivity =
            'Practice looking at your hands several times throughout the day and asking, "Am I dreaming?" This habit can carry into your dreams, triggering lucidity. When in a dream, looking at your hands often appears distorted, signaling you\'re dreaming.';
      } else if (_latestAnalysis!.recommendedActions
                  ?.toLowerCase()
                  .contains('symbol') ==
              true ||
          _latestAnalysis!.recommendedActions
                  ?.toLowerCase()
                  .contains('meaning') ==
              true) {
        actionTitle = 'Symbol Dictionary';
        actionActivity =
            'Create a personal dream symbol dictionary. When recurring symbols appear in your dreams, record them and explore what they specifically mean to you, rather than relying on generic interpretations.';
      } else {
        actionTitle = 'Dream Incubation';
        actionActivity =
            'Before sleeping, focus on a specific theme or question you want to dream about. Visualize yourself dreaming about this topic and affirm your intention to remember the dream upon waking.';
      }

      personalizedActivities
          .add({'title': actionTitle, 'description': actionActivity});
    } else {
      // Default activity if no recommended actions
      personalizedActivities.add({
        'title': 'Dream Incubation',
        'description':
            'Before sleeping, focus on a specific theme or question you want to dream about. Visualize yourself dreaming about this topic and affirm your intention to remember the dream upon waking.'
      });
    }

    // Add general dream recall activity if we have fewer than 5 activities
    if (personalizedActivities.length < 5) {
      personalizedActivities.add({
        'title': 'Dream Recall Enhancement',
        'description':
            'When you first wake up, remain still with eyes closed and try to recall your dream before engaging with the day. Say to yourself, "I remember my dreams" before sleeping to strengthen recall ability.'
      });
    }

    // Ensure we have at most 5 activities
    if (personalizedActivities.length > 5) {
      personalizedActivities = personalizedActivities.sublist(0, 5);
    }

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _secondaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.psychology, color: _secondaryColor),
              ),
              SizedBox(width: 12),
              Text(
                'Personalized Dream Activities',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Activities tailored to your dream patterns:',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),

          // Generate activities dynamically
          ...List.generate(personalizedActivities.length, (index) {
            final activity = personalizedActivities[index];
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _secondaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _secondaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: _secondaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['title'] ?? '',
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  activity['description'] ?? '',
                                  style: TextStyle(
                                    color: _textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isLoadingAnalysis || _isNavigating || _isTransitioning) {
          if (!mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please wait while analysis is loading...')),
          );
          return false;
        }

        setState(() {
          _isTransitioning = true;
          _isStateLocked = true;
        });

        // Clean up resources
        _debounceTimer?.cancel();
        _animationController.stop();

        // Ensure we're not in a build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });

        return false;
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _backgroundColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: _isLoadingAnalysis ? null : _handleNavigation,
          ),
          title: GradientText(
            'Dream Analysis',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
            colors: [
              Color(0xFF4B39EF),
              Color(0xFF39D2C0),
              Color(0xFFFF6B6B),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoadingAnalysis ? null : _handleRefresh,
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: Stack(
          children: [
            // Background image with overlay
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withOpacity(0.8),
                  ],
                ).createShader(bounds),
                blendMode: BlendMode.darken,
                child: Image.asset(
                  'assets/images/Gemini_Generated_Image_a0fv1za0fv1za0fv.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Content
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 100), // Account for app bar
                            _buildPageHeader(),
                            SizedBox(height: 24),
                            _buildMoodAnalysis(),
                            SizedBox(height: 16),
                            _buildDreamCategories(),
                            SizedBox(height: 16),
                            _buildDreamPersona(),
                            SizedBox(height: 16),
                            _buildDreamInsights(),
                            SizedBox(height: 16),
                            _buildDreamGrowthActivities(),
                            SizedBox(height: 40), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.nightlight_round, color: _primaryColor),
              ),
              SizedBox(width: 12),
              Text(
                'Dream Insights',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Your dreams provide a window into your subconscious mind. Here, AI analyzes patterns from your dream journal to reveal insights about your emotions, recurring themes, and personal growth opportunities.',
            style: TextStyle(
              color: _textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
