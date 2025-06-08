import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';

/// A custom text form field with text selection enabled but no context menu tools
class CustomTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final bool enabled;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputDecoration? decoration;
  final TextStyle? style;
  final bool autocorrect;
  final bool enableSuggestions;
  final EdgeInsetsGeometry? contentPadding;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final ScrollPhysics? scrollPhysics;

  const CustomTextFormField({
    Key? key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.decoration,
    this.style,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.contentPadding,
    this.inputFormatters,
    this.autovalidateMode,
    this.scrollPhysics,
  }) : super(key: key);

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Returns an empty context menu to disable tools while keeping selection
  Widget _buildEmptyContextMenu(BuildContext context, EditableTextState editableTextState) {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = widget.decoration ??
        InputDecoration(
          hintText: widget.hintText,
          hintStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Figtree',
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).primary.withValues(alpha: 128),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).error,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context).error,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: FlutterFlowTheme.of(context).secondaryBackground.withValues(alpha: 128),
          contentPadding: widget.contentPadding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
        );

    // Create a text selection theme with nice iOS-style colors
    final textSelectionTheme = TextSelectionThemeData(
      selectionColor: CupertinoColors.systemBlue.withOpacity(0.2),
      cursorColor: CupertinoColors.systemBlue,
      selectionHandleColor: CupertinoColors.systemBlue,
    );

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: textSelectionTheme,
      ),
      child: widget.validator != null
          ? _buildFormField(effectiveDecoration)
          : _buildTextField(effectiveDecoration),
    );
  }

  Widget _buildTextField(InputDecoration decoration) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      decoration: decoration,
      style: widget.style ?? FlutterFlowTheme.of(context).bodyMedium,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      inputFormatters: widget.inputFormatters,
      scrollPhysics: widget.scrollPhysics ?? ClampingScrollPhysics(),
      enableInteractiveSelection: true,
      contextMenuBuilder: _buildEmptyContextMenu,
      onTapOutside: (PointerDownEvent event) {
        FocusScope.of(context).unfocus();
      },
    );
  }

  Widget _buildFormField(InputDecoration effectiveDecoration) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      decoration: effectiveDecoration,
      style: widget.style ?? FlutterFlowTheme.of(context).bodyMedium,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      inputFormatters: widget.inputFormatters,
      scrollPhysics: widget.scrollPhysics ?? ClampingScrollPhysics(),
      autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.disabled,
      enableInteractiveSelection: true,
      contextMenuBuilder: _buildEmptyContextMenu,
      onTapOutside: (PointerDownEvent event) {
        FocusScope.of(context).unfocus();
      },
    );
  }
} 