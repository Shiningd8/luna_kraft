import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'add_post1_widget.dart' show AddPost1Widget;
import 'package:flutter/material.dart';

class AddPost1Model extends FlutterFlowModel<AddPost1Widget> {
  ///  Local state fields for this page.

  String apiResponse = '';

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Backend Call - API (GeminiAPI)] action in Button widget.
  ApiCallResponse? apiResultssd;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
