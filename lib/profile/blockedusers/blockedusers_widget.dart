import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:lottie/lottie.dart';
import 'blockedusers_model.dart';
export 'blockedusers_model.dart';

class BlockedusersWidget extends StatefulWidget {
  const BlockedusersWidget({
    super.key,
    required this.userref,
  });

  final DocumentReference? userref;

  static String routeName = 'blockedusers';
  static String routePath = '/blockedusers';

  @override
  State<BlockedusersWidget> createState() => _BlockedusersWidgetState();
}

class _BlockedusersWidgetState extends State<BlockedusersWidget>
    with SingleTickerProviderStateMixin {
  late BlockedusersModel _model;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BlockedusersModel());
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _model.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showUnblockConfirmation(BuildContext context, UserRecord user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: FlutterFlowTheme.of(context).primary,
              ),
              SizedBox(height: 20),
              Text(
                'Unblock User',
                style: FlutterFlowTheme.of(context).titleLarge,
              ),
              SizedBox(height: 10),
              Text(
                'Are you sure you want to unblock ${user.userName}?',
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _unblockUser(user);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Unblock'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unblockUser(UserRecord user) async {
    try {
      await currentUserReference!.update({
        'blocked_users': FieldValue.arrayRemove([user.reference]),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User unblocked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unblocking user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:
            FlutterFlowTheme.of(context).secondaryBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
                leading: FlutterFlowIconButton(
                  borderColor: Colors.transparent,
            borderRadius: 30,
            borderWidth: 1,
            buttonSize: 60,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: FlutterFlowTheme.of(context).primaryText,
              size: 30,
                  ),
                  onPressed: () async {
                    context.pop();
                  },
                ),
                title: Text(
                  'Blocked Users',
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                  fontFamily: 'Figtree',
                        letterSpacing: 0.0,
                      ),
                ),
                actions: [],
                centerTitle: false,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
          child: Column(
            children: [
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_alt_outlined,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Blocked Users',
                        style: FlutterFlowTheme.of(context).titleMedium,
                      ),
                      Spacer(),
                      AuthUserStreamWidget(
                        builder: (context) => Container(
                    padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(currentUserDocument?.blockedUsers.toList() ?? []).length}',
                            style: TextStyle(
                              color: FlutterFlowTheme.of(context).primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ),
              Expanded(
                  child: AuthUserStreamWidget(
                      builder: (context) {
                      final blockedUsers =
                          (currentUserDocument?.blockedUsers.toList() ?? []);

                      if (blockedUsers.isEmpty) {
                                    return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.block_outlined,
                                size: 64,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No blocked users',
                                style: FlutterFlowTheme.of(context).titleMedium,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Users you block will appear here',
                                style: FlutterFlowTheme.of(context).bodyMedium,
                              ),
                            ],
                                      ),
                                    );
                                  }

                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: blockedUsers.length,
                        itemBuilder: (context, index) {
                          final userRef = blockedUsers[index];
                          return StreamBuilder<UserRecord>(
                            stream: UserRecord.getDocument(userRef),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                  return Container(
                                  margin: EdgeInsets.only(bottom: 16),
                                  height: 80,
                                    decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                );
                              }

                              final user = snapshot.data!;
                              return _buildGlassContainer(
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                            child: Image.network(
                                      user.photoUrl ?? '',
                                      width: 50,
                                      height: 50,
                                              fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                                  Icon(Icons.person, size: 30),
                                            ),
                                          ),
                                  title: Text(
                                    user.userName ?? '',
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium,
                                  ),
                                  subtitle: Text(
                                    'Blocked User',
                                    style:
                                        FlutterFlowTheme.of(context).bodySmall,
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.block_flipped,
                                      color: FlutterFlowTheme.of(context).error,
                                    ),
                                    onPressed: () =>
                                        _showUnblockConfirmation(context, user),
                                  ),
                              ),
                            );
                          },
                        );
                      },
                      );
                    },
                  ),
                ),
              ],
              ),
          ),
        ),
      ),
    );
  }
}
