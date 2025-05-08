import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'detailedpost_widget.dart' show DetailedpostWidget;
import 'package:flutter/material.dart';
import '/backend/schema/comments_record.dart';

class DetailedpostModel extends FlutterFlowModel<DetailedpostWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Comment that is being replied to
  CommentsRecord? replyingToComment;
  // Map to track expanded replies state for each parent comment
  Map<String, bool> expandedReplies = {};

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
