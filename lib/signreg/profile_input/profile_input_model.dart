import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'profile_input_widget.dart' show ProfileInputWidget;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfileInputModel extends FlutterFlowModel<ProfileInputWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  bool isDataUploading1 = false;
  FFUploadedFile uploadedLocalFile1 =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl1 = '';
  String? uploadError;

  bool isDataUploading2 = false;
  FFUploadedFile uploadedLocalFile2 =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl2 = '';

  // State field(s) for DisplayName widget.
  FocusNode? displayNameFocusNode;
  TextEditingController? displayNameTextController;
  String? Function(BuildContext, String?)? displayNameTextControllerValidator;
  // State field(s) for UserID widget.
  FocusNode? userIDFocusNode;
  TextEditingController? userIDTextController;
  String? Function(BuildContext, String?)? userIDTextControllerValidator;
  DateTime? datePicked;
  String? selectedGender;

  // Flag to track whether validation errors should be displayed
  bool showValidationErrors = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    displayNameFocusNode?.dispose();
    displayNameTextController?.dispose();

    userIDFocusNode?.dispose();
    userIDTextController?.dispose();
  }
}
