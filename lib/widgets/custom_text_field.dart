import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// A custom text field that handles iOS text selection properly
/// and provides a consistent experience across the app.
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextAlign textAlign;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool enableSuggestions;
  final bool autocorrect;
  
  const CustomTextField({
    Key? key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.textStyle,
    this.hintStyle,
    this.textAlign = TextAlign.start,
    this.decoration,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.enableSuggestions = true,
    this.autocorrect = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use platform-specific selection controls
    final bool isIOS = Theme.of(context).platform == TargetPlatform.iOS || 
                        Theme.of(context).platform == TargetPlatform.macOS;
    
    // Proper decoration that doesn't interfere with selection
    final effectiveDecoration = decoration ?? 
        InputDecoration(
          hintText: hintText,
          hintStyle: hintStyle,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        );
    
    // For iOS, we need to use specific iOS native styling
    if (isIOS) {
      // Create a specific TextSelectionTheme for iOS that matches native behavior
      return Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: CupertinoColors.systemBlue, // Changed to Cupertino color
            cursorColor: CupertinoColors.activeBlue,
            selectionHandleColor: CupertinoColors.activeBlue,
          ),
          platform: TargetPlatform.iOS, // Force iOS platform for controls
          // Avoid setting any MaterialApp specific theming that could cause grey boxes
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          textAlign: textAlign,
          decoration: effectiveDecoration,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofocus: autofocus,
          maxLines: maxLines,
          minLines: minLines,
          enabled: enabled,
          onChanged: onChanged,
          onTap: onTap,
          onEditingComplete: onEditingComplete,
          onSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          enableSuggestions: enableSuggestions,
          autocorrect: autocorrect,
          
          // Force enable selection with iOS controls
          enableInteractiveSelection: true,
          // Use Cupertino selection controls to ensure iOS native behavior
          selectionControls: CupertinoTextSelectionControls(),
          // iOS scrolling physics
          scrollPhysics: const ClampingScrollPhysics(),
          // Context menu using adaptiveTextSelectionToolbar to properly handle iOS
          contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
            return AdaptiveTextSelectionToolbar.editableText(
              editableTextState: editableTextState,
            );
          },
        ),
      );
    }
    
    // For Android/other platforms, use material controls
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: textStyle,
      textAlign: textAlign,
      decoration: effectiveDecoration,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      onChanged: onChanged,
      onTap: onTap,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      
      // Default selection behavior for Android
      enableInteractiveSelection: true,
      selectionControls: MaterialTextSelectionControls(),
      scrollPhysics: const ClampingScrollPhysics(),
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
    );
  }
}

/// FormField version of CustomTextField for use with Form widgets
class CustomTextFormField extends FormField<String> {
  CustomTextFormField({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? hintText,
    TextStyle? textStyle,
    TextStyle? hintStyle,
    TextAlign textAlign = TextAlign.start,
    InputDecoration? decoration,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool autofocus = false,
    int? maxLines = 1,
    int? minLines,
    bool enabled = true,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enableSuggestions = true,
    bool autocorrect = true,
    FormFieldValidator<String>? validator,
    FormFieldSetter<String>? onSaved,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    String initialValue = '',
  }) : super(
          key: key,
          initialValue: controller?.text ?? initialValue,
          validator: validator,
          onSaved: onSaved,
          autovalidateMode: autovalidateMode,
          builder: (FormFieldState<String> state) {
            // Sync the internal state with the controller if provided
            if (controller != null) {
              controller.addListener(() {
                state.didChange(controller.text);
              });
            }
            
            // Override decoration to show error message if any
            final InputDecoration effectiveDecoration = (decoration ?? 
                InputDecoration(
                  hintText: hintText,
                  hintStyle: hintStyle,
                  contentPadding: EdgeInsets.zero,
                )).copyWith(
                  errorText: state.errorText,
                );
            
            return CustomTextField(
              controller: controller,
              focusNode: focusNode,
              hintText: hintText,
              textStyle: textStyle,
              hintStyle: hintStyle,
              textAlign: textAlign,
              decoration: effectiveDecoration,
              keyboardType: keyboardType,
              obscureText: obscureText,
              autofocus: autofocus,
              maxLines: maxLines,
              minLines: minLines,
              enabled: enabled,
              onChanged: (value) {
                state.didChange(value);
                onChanged?.call(value);
              },
              onTap: onTap,
              onEditingComplete: onEditingComplete,
              onSubmitted: onSubmitted,
              inputFormatters: inputFormatters,
              textInputAction: textInputAction,
              textCapitalization: textCapitalization,
              enableSuggestions: enableSuggestions,
              autocorrect: autocorrect,
            );
          },
        );
} 