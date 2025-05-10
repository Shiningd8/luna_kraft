import 'dart:async';
import 'package:flutter/material.dart';
import '/services/notification_service.dart';

class NotificationHandler extends StatefulWidget {
  final Widget child;

  const NotificationHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NotificationHandler> createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  late StreamSubscription<NotificationPayload> _notificationSubscription;

  @override
  void initState() {
    super.initState();

    // Subscribe to notification events
    _notificationSubscription =
        NotificationService().notificationStream.listen(_handleNotification);
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  void _handleNotification(NotificationPayload notification) {
    // The actual snackbar display is handled in NotificationService._showSnackbar
    // This widget just listens to the stream for any additional handling
    // we might want to add in the future
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
