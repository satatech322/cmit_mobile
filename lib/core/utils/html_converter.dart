import 'package:flutter_quill/flutter_quill.dart' as quill;
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
}
