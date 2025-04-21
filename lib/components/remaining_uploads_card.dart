import 'package:flutter/material.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../services/dream_upload_service.dart';

class RemainingUploadsCard extends StatelessWidget {
  final int remainingUploads;
  final int totalFreeUploads = DreamUploadService.MAX_FREE_UPLOADS;

  const RemainingUploadsCard({
    Key? key,
    required this.remainingUploads,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure we never show negative uploads
    final displayUploads = remainingUploads < 0 ? 0 : remainingUploads;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'Daily Uploads',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Figtree',
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$displayUploads/${totalFreeUploads} Free Uploads',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Figtree',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              _buildRemainingIndicator(displayUploads),
            ],
          ),
          SizedBox(height: 8),
          Text(
            displayUploads > 0
                ? 'You have $displayUploads free upload${displayUploads == 1 ? '' : 's'} left today'
                : 'You\'ve used all free uploads for today',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Figtree',
                  color: displayUploads > 0
                      ? Colors.white.withOpacity(0.7)
                      : Color(0xFFE57373),
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingIndicator(int displayUploads) {
    return Row(
      children: List.generate(
        totalFreeUploads,
        (index) => Container(
          width: 12,
          height: 12,
          margin: EdgeInsets.only(right: index < totalFreeUploads - 1 ? 4 : 0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < displayUploads
                ? Color(0xFF4CAF50)
                : Colors.white.withOpacity(0.2),
            border: Border.all(
              color: index < displayUploads
                  ? Color(0xFF4CAF50).withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
