import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:luna_kraft/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Custom text selection controls that handle the toolbar differently
class CustomTextSelectionControls extends MaterialTextSelectionControls {
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return _TextSelectionControlsToolbar(
      globalEditableRegion: globalEditableRegion,
      textLineHeight: textLineHeight,
      selectionMidpoint: selectionMidpoint,
      endpoints: endpoints,
      delegate: delegate,
      clipboardStatus: clipboardStatus,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
    );
  }
}

/// A toolbar that displays text selection options without the grey background box
class _TextSelectionControlsToolbar extends StatefulWidget {
  const _TextSelectionControlsToolbar({
    required this.globalEditableRegion,
    required this.textLineHeight,
    required this.selectionMidpoint,
    required this.endpoints,
    required this.delegate,
    required this.clipboardStatus,
    this.handleCut,
    this.handleCopy,
    this.handlePaste,
    this.handleSelectAll,
  });

  final Rect globalEditableRegion;
  final double textLineHeight;
  final Offset selectionMidpoint;
  final List<TextSelectionPoint> endpoints;
  final TextSelectionDelegate delegate;
  final ValueListenable<ClipboardStatus>? clipboardStatus;
  final VoidCallback? handleCut;
  final VoidCallback? handleCopy;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;

  @override
  _TextSelectionControlsToolbarState createState() => _TextSelectionControlsToolbarState();
}

class _TextSelectionControlsToolbarState extends State<_TextSelectionControlsToolbar> {
  @override
  Widget build(BuildContext context) {
    // Calculate the position of the toolbar
    final Offset midpointAnchor = Offset(
      widget.selectionMidpoint.dx - (widget.globalEditableRegion.left + widget.globalEditableRegion.right) / 2,
      widget.selectionMidpoint.dy - widget.globalEditableRegion.top,
    );

    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: Material(
        elevation: 0.0, // No elevation to avoid shadow
        color: Colors.transparent, // Transparent background
        child: Container(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          width: 0,
          height: 0,
          child: CustomMultiChildLayout(
            delegate: _TextSelectionToolbarLayout(
              midpointAnchor,
              widget.textLineHeight,
              widget.globalEditableRegion,
              Directionality.of(context),
            ),
            children: <Widget>[
              LayoutId(
                id: _TextSelectionToolbarSlot.toolbar,
                child: _TextSelectionToolbarContent(
                  handleCut: widget.handleCut,
                  handleCopy: widget.handleCopy,
                  handlePaste: widget.handlePaste,
                  handleSelectAll: widget.handleSelectAll,
                  clipboardStatus: widget.clipboardStatus,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// The enum for the layout slots of the selection toolbar.
enum _TextSelectionToolbarSlot { toolbar }

// Positions the toolbar based on text selection
class _TextSelectionToolbarLayout extends MultiChildLayoutDelegate {
  _TextSelectionToolbarLayout(
    this.midpointAnchor,
    this.textLineHeight,
    this.globalEditableRegion,
    this.direction,
  );

  final Offset midpointAnchor;
  final double textLineHeight;
  final Rect globalEditableRegion;
  final TextDirection direction;

  @override
  void performLayout(Size size) {
    final Size toolbarSize = layoutChild(_TextSelectionToolbarSlot.toolbar, BoxConstraints.loose(size));

    final double y = midpointAnchor.dy - toolbarSize.height - 8.0;
    final double x = switch (direction) {
      TextDirection.rtl => midpointAnchor.dx - toolbarSize.width + 8.0,
      TextDirection.ltr => midpointAnchor.dx - 8.0,
    };

    positionChild(_TextSelectionToolbarSlot.toolbar, Offset(x, y));
  }

  @override
  bool shouldRelayout(_TextSelectionToolbarLayout oldDelegate) {
    return oldDelegate.midpointAnchor != midpointAnchor 
        || oldDelegate.textLineHeight != textLineHeight
        || oldDelegate.direction != direction;
  }
}

// Content of the selection toolbar
class _TextSelectionToolbarContent extends StatelessWidget {
  const _TextSelectionToolbarContent({
    this.handleCut,
    this.handleCopy,
    this.handlePaste,
    this.handleSelectAll,
    this.clipboardStatus,
  });

  final VoidCallback? handleCut;
  final VoidCallback? handleCopy;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final ValueListenable<ClipboardStatus>? clipboardStatus;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[850] : Colors.white;
    final itemColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (handleCut != null)
              _buildToolbarButton(context, 'Cut', Icons.content_cut, handleCut!, itemColor),
            if (handleCopy != null)
              _buildToolbarButton(context, 'Copy', Icons.content_copy, handleCopy!, itemColor),
            if (handlePaste != null)
              _buildToolbarButton(context, 'Paste', Icons.content_paste, handlePaste!, itemColor),
            if (handleSelectAll != null)
              _buildToolbarButton(context, 'Select All', Icons.select_all, handleSelectAll!, itemColor),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
    BuildContext context, 
    String label, 
    IconData icon, 
    VoidCallback onPressed,
    Color color,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom text selection controls with styling to avoid the grey box
class StyledTextSelectionControls extends MaterialTextSelectionControls {
  final Color toolbarColor;
  final Color textColor;
  final Color buttonColor;
  final double elevation;
  final double borderRadius;

  StyledTextSelectionControls({
    required this.toolbarColor,
    required this.textColor,
    required this.buttonColor,
    this.elevation = 4.0,
    this.borderRadius = 8.0,
  });

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    // Use parent's positioning logic but customize the appearance
    return _buildCustomToolbar(
      context, 
      globalEditableRegion, 
      textLineHeight, 
      position, 
      endpoints, 
      delegate, 
      clipboardStatus,
      lastSecondaryTapDownPosition,
    );
  }

  Widget _buildCustomToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    // Calculate position similar to the standard toolbar
    final Offset globalPosition = Offset(
      position.dx + globalEditableRegion.left,
      position.dy + globalEditableRegion.top,
    );

    // Create the buttons
    final List<Widget> items = <Widget>[];

    if (canCut(delegate)) {
      items.add(_buildButton(
        context: context,
        label: 'Cut',
        icon: Icons.content_cut,
        onPressed: () => handleCut(delegate),
      ));
    }

    if (canCopy(delegate)) {
      items.add(_buildButton(
        context: context,
        label: 'Copy',
        icon: Icons.content_copy,
        onPressed: () => handleCopy(delegate),
      ));
    }

    if (canPaste(delegate)) {
      items.add(_buildButton(
        context: context,
        label: 'Paste',
        icon: Icons.content_paste,
        onPressed: () => handlePaste(delegate),
      ));
    }

    if (canSelectAll(delegate)) {
      items.add(_buildButton(
        context: context,
        label: 'Select All',
        icon: Icons.select_all,
        onPressed: () => handleSelectAll(delegate),
      ));
    }

    // Place the menu based on the position
    return Positioned(
      left: globalPosition.dx,
      top: globalPosition.dy - 44.0, // Position above the text
      child: Material(
        elevation: elevation,
        borderRadius: BorderRadius.circular(borderRadius),
        color: toolbarColor,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items,
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: buttonColor),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom text form field that completely eliminates the grey selection overlay
/// by using a stack-based approach with ignored pointer events.
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
  final bool selectionEnabled;

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
    this.selectionEnabled = true,
  }) : super(key: key);

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isSelecting = false;

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

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Prevent scrolling from propagating outside
        return true;
      },
      child: GestureDetector(
        onLongPressStart: (details) {
          setState(() {
            _isSelecting = true;
          });
        },
        onLongPressEnd: (details) {
          // Delay resetting to allow menu to show
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                _isSelecting = false;
              });
            }
          });
        },
        child: Stack(
          children: [
            // The actual text field
            widget.validator != null
                ? _buildFormField(effectiveDecoration)
                : _buildTextField(effectiveDecoration),
                
            // Overlay blocker that only activates during selection
            if (_isSelecting)
              Positioned.fill(
                child: IgnorePointer(
                  // This widget blocks the grey overlay from showing
                  // but allows gestures to pass through to the text field
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
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
      enableInteractiveSelection: widget.selectionEnabled,
      contextMenuBuilder: (context, editableTextState) {
        // Use the default context menu but with no background overlay
        return AdaptiveTextSelectionToolbar(
          anchors: const TextSelectionToolbarAnchors(
            primaryAnchor: Offset(40, 40),
          ),
          children: [
            if (editableTextState.contextMenuButtonItems.isNotEmpty)
              ...editableTextState.contextMenuButtonItems.map((ContextMenuButtonItem buttonItem) {
                return TextSelectionToolbarTextButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  onPressed: buttonItem.onPressed,
                  child: Text(buttonItem.label ?? ''),
                );
              }).toList(),
          ],
        );
      },
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
      // Use AutovalidateMode.disabled by default to prevent yellow underlines when navigating
      autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.disabled,
      // Prevent showing error indicators during page transitions
      showCursor: _focusNode.hasFocus,
      enableInteractiveSelection: widget.selectionEnabled,
      contextMenuBuilder: (context, editableTextState) {
        // Use the default context menu but with no background overlay
        return AdaptiveTextSelectionToolbar(
          anchors: const TextSelectionToolbarAnchors(
            primaryAnchor: Offset(40, 40),
          ),
          children: [
            if (editableTextState.contextMenuButtonItems.isNotEmpty)
              ...editableTextState.contextMenuButtonItems.map((ContextMenuButtonItem buttonItem) {
                return TextSelectionToolbarTextButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  onPressed: buttonItem.onPressed,
                  child: Text(buttonItem.label ?? ''),
                );
              }).toList(),
          ],
        );
      },
      onTapOutside: (PointerDownEvent event) {
        FocusScope.of(context).unfocus();
      },
    );
  }
} 