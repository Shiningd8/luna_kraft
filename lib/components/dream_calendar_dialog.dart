import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'package:luna_kraft/backend/backend.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_util.dart';
import 'package:luna_kraft/components/standardized_post_item.dart';
import '/utils/serialization_helpers.dart';

class DreamCalendarDialog extends StatefulWidget {
  final List<PostsRecord> dreams;
  final DocumentReference userReference;

  const DreamCalendarDialog({
    Key? key,
    required this.dreams,
    required this.userReference,
  }) : super(key: key);

  @override
  State<DreamCalendarDialog> createState() => _DreamCalendarDialogState();
}

class _DreamCalendarDialogState extends State<DreamCalendarDialog> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late Map<DateTime, List<PostsRecord>> _dreamsByDay;
  bool _isCalendarView = true;

  @override
  void initState() {
    super.initState();
    _initDreamsByDay();
  }

  void _initDreamsByDay() {
    _dreamsByDay = {};

    for (var dream in widget.dreams) {
      if (dream.date != null) {
        final date = DateTime(
          dream.date!.year,
          dream.date!.month,
          dream.date!.day,
        );

        if (_dreamsByDay[date] == null) {
          _dreamsByDay[date] = [];
        }

        _dreamsByDay[date]!.add(dream);
      }
    }
  }

  List<PostsRecord> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _dreamsByDay[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final List<PostsRecord> selectedDayDreams = _getEventsForDay(_selectedDay);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 60),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context)
                  .primaryBackground
                  .withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dream Calendar',
                        style:
                            FlutterFlowTheme.of(context).headlineSmall.override(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isCalendarView
                                  ? Icons.view_list
                                  : Icons.calendar_month,
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                            onPressed: () {
                              setState(() {
                                _isCalendarView = !_isCalendarView;
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Body
                if (_isCalendarView) _buildCalendarView() else _buildListView(),

                // Dreams for selected day
                if (_isCalendarView && selectedDayDreams.isNotEmpty)
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.1),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              '${DateFormat.yMMMMd().format(_selectedDay)} · ${selectedDayDreams.length} ${selectedDayDreams.length == 1 ? 'Dream' : 'Dreams'}',
                              style: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.only(bottom: 16),
                              itemCount: selectedDayDreams.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: DreamListItem(
                                      dream: selectedDayDreams[index]),
                                )
                                    .animate()
                                    .fade(duration: 300.ms)
                                    .slideY(begin: 0.2, end: 0);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isCalendarView &&
                    selectedDayDreams.isEmpty &&
                    widget.dreams.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Lottie.asset(
                          'assets/lottie/bookshelf.json',
                          height: 120,
                          repeat: true,
                          animate: true,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No dreams on ${DateFormat.yMMMMd().format(_selectedDay)}',
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // Empty state if no dreams at all
                if (widget.dreams.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        Lottie.asset(
                          'assets/lottie/dream_text.json',
                          height: 150,
                          repeat: true,
                          animate: true,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No dreams to show yet',
                          style: FlutterFlowTheme.of(context).titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start sharing your dreams to see them in your calendar',
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return TableCalendar(
      firstDay: DateTime.utc(2022, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: _getEventsForDay,
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primary,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        selectedDecoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
      ),
    );
  }

  Widget _buildListView() {
    final dreamsByMonth = <String, List<PostsRecord>>{};

    // Group dreams by month
    for (var dream in widget.dreams) {
      if (dream.date != null) {
        final monthKey = DateFormat('MMMM yyyy').format(dream.date!);
        if (dreamsByMonth[monthKey] == null) {
          dreamsByMonth[monthKey] = [];
        }
        dreamsByMonth[monthKey]!.add(dream);
      }
    }

    // Sort months in reverse chronological order
    final sortedMonths = dreamsByMonth.keys.toList()
      ..sort((a, b) {
        try {
          final aDate = DateFormat('MMMM yyyy').parse(a);
          final bDate = DateFormat('MMMM yyyy').parse(b);
          return bDate.compareTo(aDate); // Newest first
        } catch (e) {
          return 0;
        }
      });

    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.only(bottom: 16),
        itemCount: sortedMonths.length,
        itemBuilder: (context, index) {
          final month = sortedMonths[index];
          final dreamsInMonth = dreamsByMonth[month]!;

          // Sort dreams by date (newest first)
          dreamsInMonth.sort((a, b) => b.date!.compareTo(a.date!));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  month,
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: dreamsInMonth.length,
                itemBuilder: (context, dreamIndex) {
                  final dream = dreamsInMonth[dreamIndex];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dreamIndex == 0 ||
                            DateFormat('MMM d').format(dream.date!) !=
                                DateFormat('MMM d').format(
                                    dreamsInMonth[dreamIndex - 1].date!))
                          Padding(
                            padding: EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              DateFormat('EEEE, MMM d').format(dream.date!),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Figtree',
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        DreamListItem(dream: dream),
                      ],
                    ),
                  ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// Simple item to display a dream preview
class DreamListItem extends StatelessWidget {
  final PostsRecord dream;

  const DreamListItem({
    Key? key,
    required this.dream,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(
        'Detailedpost',
        queryParameters: {
          'docref': serializeParam(
            dream.reference,
            ParamType.DocumentReference,
          ),
          'userref': serializeParam(
            dream.poster,
            ParamType.DocumentReference,
          ),
        }.withoutNulls,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 40,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dream.title,
                    style: FlutterFlowTheme.of(context).titleSmall.override(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    dream.dream,
                    style: FlutterFlowTheme.of(context).bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Text(
              DateFormat.jm().format(dream.date!),
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Figtree',
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
