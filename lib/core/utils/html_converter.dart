import 'package:flutter_quill/quill_delta.dart';

class QuillToHtmlConverter {
  static String convertDeltaToHtml(Delta delta) {
    // This is a very basic implementation. 
    // In a real scenario, you'd use a package like vsc_quill_delta_to_html.
    // However, to keep the project running without adding dependencies, 
    // we provide this basic conversion.
    
    final StringBuffer html = StringBuffer();
    
    for (final op in delta.toList()) {
      if (op.data is String) {
        String text = op.data as String;
        
        // Handle attributes
        if (op.attributes != null) {
          if (op.attributes!.containsKey('bold')) {
            text = '<b>$text</b>';
          }
          if (op.attributes!.containsKey('italic')) {
            text = '<i>$text</i>';
          }
          if (op.attributes!.containsKey('underline')) {
            text = '<u>$text</u>';
          }
        }
        
        // Convert newlines to <br> if needed
        text = text.replaceAll('\n', '<br>');
        
        html.write(text);
      }
    }
    
    return html.toString();
  }

  /// Strip HTML tags and entities back to plain text for Quill editor
  static String htmlToPlainText(String html) {
    if (html.isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
}
