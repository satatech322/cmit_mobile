import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class WordpadWidget extends StatefulWidget {
  final QuillController controller;
  final FocusNode focusNode;
  final String placeholder;
  final double minHeight;

  const WordpadWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    this.placeholder = 'Enter details...',
    this.minHeight = 250,
  });

  @override
  State<WordpadWidget> createState() => _WordpadWidgetState();
}

class _WordpadWidgetState extends State<WordpadWidget> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isFocused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted && _isFocused != widget.focusNode.hasFocus) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  void _requestFocusAndMoveCursor() {
    if (!widget.focusNode.hasFocus) {
      widget.focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? const Color(0xFF014323) : const Color(0xFFE0E0E0),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar - Always visible and accessible without layout shifts
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: QuillSimpleToolbar(
              controller: widget.controller,
              config: const QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showColorButton: false,
                showSubscript: false,
                showSuperscript: false,
                showSearchButton: false,
                showSmallButton: false,
                showInlineCode: false,
                showStrikeThrough: false,
                showDirection: false,
                showDividers: false,
                showCodeBlock: false,
                showQuote: false,
                showLink: false,
                showAlignmentButtons: true,
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showListBullets: true,
                showListNumbers: true,
                showUndo: true,
                showRedo: true,
                showClearFormat: false,
                showHeaderStyle: false,
                showIndent: true,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          // Editor Area - Fully clickable anywhere in the box
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _requestFocusAndMoveCursor,
            child: Container(
              constraints: BoxConstraints(minHeight: widget.minHeight),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: QuillEditor.basic(
                controller: widget.controller,
                focusNode: widget.focusNode,
                config: QuillEditorConfig(
                  placeholder: widget.placeholder,
                  padding: EdgeInsets.zero,
                  autoFocus: false,
                  expands: false,
                  scrollable: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
