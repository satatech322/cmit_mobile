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
    this.minHeight = 300,
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
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });

      if (_isFocused) {
        // Wait longer for keyboard to fully animate up
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutQuart,
              alignment: 0.0, // Force align to top
              alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isFocused ? const Color(0xFF014323) : const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toolbar
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _isFocused
                ? Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: QuillToolbar.simple(
                          configurations: QuillSimpleToolbarConfigurations(
                            controller: widget.controller,
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
                      const Divider(height: 1),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          // Editor
          Container(
            constraints: BoxConstraints(minHeight: widget.minHeight),
            child: QuillEditor.basic(
              configurations: QuillEditorConfigurations(
                controller: widget.controller,
                placeholder: widget.placeholder,
                padding: const EdgeInsets.all(16),
                autoFocus: false,
                expands: false,
                scrollable: true,
              ),
              focusNode: widget.focusNode,
            ),
          ),
        ],
      ),
    );
  }
}
