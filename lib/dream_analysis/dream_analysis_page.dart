import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DreamAnalysisPage extends StatelessWidget {
  const DreamAnalysisPage({Key? key}) : super(key: key);

  Widget _buildPatternCard(
      String title, String? frequency, List<DreamExample> examples) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2D3E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (frequency != null) ...[
            SizedBox(height: 8),
            Text(
              'Frequency',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            Text(
              frequency,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
          if (examples.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Examples',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            ...examples.map((example) => _buildDreamExample(example)),
          ],
        ],
      ),
    );
  }

  Widget _buildDreamExample(DreamExample example) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            example.excerpt,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Text(
            example.analysis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolSection(String symbol, List<DreamExample> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          symbol,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        ...examples.map((example) => _buildDreamExample(example)),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Dream Analysis',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Outfit',
                color: Colors.white,
              ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatternCard(
              'Lucid Dreaming',
              'Occasional',
              [
                DreamExample(
                  excerpt:
                      'I suddenly realized I was in a train station, but the walls were made of shifting light. When I touched them, my hand passed through, and I knew I was dreaming.',
                  analysis:
                      'Clear moment of lucidity where dream awareness emerged through physical impossibilities.',
                ),
                DreamExample(
                  excerpt:
                      'The numbers on my phone kept changing every time I looked at them. This triggered my awareness that I was in a dream state, allowing me to take control.',
                  analysis:
                      'Reality check leading to lucid state - common trigger through inconsistent dream details.',
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Recurring Symbols',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildSymbolSection(
              'Flying',
              [
                DreamExample(
                  excerpt:
                      'As I spread my arms, gravity seemed to lose its hold. I floated upward, passing through clouds that felt like cool mist on my skin.',
                  analysis:
                      'Represents feelings of freedom and transcendence, often occurring during periods of personal growth.',
                ),
              ],
            ),
            _buildSymbolSection(
              'Falling',
              [
                DreamExample(
                  excerpt:
                      'The ground disappeared beneath me, and that familiar sensation of falling began. But unlike usual falling dreams, I felt peaceful, almost floating.',
                  analysis:
                      'Indicates a sense of losing control but with acceptance, suggesting personal transformation.',
                ),
                DreamExample(
                  excerpt:
                      'The elevator cables snapped, and as we fell, time seemed to slow down. I could see every detail of the metal walls reflecting our descent.',
                  analysis:
                      'Classic anxiety manifestation about loss of control in life situations.',
                ),
              ],
            ),
            _buildSymbolSection(
              'Water',
              [
                DreamExample(
                  excerpt:
                      'The crystal-clear water revealed an entire city beneath. As I swam deeper, the buildings seemed to pulse with their own light, welcoming me.',
                  analysis:
                      'Deep water symbolizes exploration of the subconscious, with the illuminated city representing hidden knowledge or memories.',
                ),
                DreamExample(
                  excerpt:
                      'Waves crashed over the boat, but the water was warm and glowing with bioluminescence. Each splash created patterns of light that told stories.',
                  analysis:
                      'Turbulent but beautiful water scenes often represent emotional processing and spiritual awakening.',
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Emotional Patterns',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildPatternCard(
              'Positive Emotions',
              null,
              [
                DreamExample(
                  excerpt:
                      'The garden was filled with flowers that sang in colors I\'ve never seen before. Each step brought waves of pure joy and understanding.',
                  analysis:
                      'Manifestation of deep inner peace and spiritual connection through unprecedented sensory experiences.',
                ),
              ],
            ),
            _buildPatternCard(
              'Challenging Emotions',
              null,
              [
                DreamExample(
                  excerpt:
                      'The shadows kept shifting, taking forms of unfinished tasks and conversations. Though unsettling, I felt compelled to face each one.',
                  analysis:
                      'Processing of daily anxieties through symbolic confrontation, showing healthy emotional processing.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DreamExample {
  final String excerpt;
  final String analysis;

  DreamExample({
    required this.excerpt,
    required this.analysis,
  });
}
