import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MathTextWidget({
    Key? key,
    required this.text,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if text contains LaTeX math (surrounded by $ or $$)
    if (!text.contains(r'$')) {
      return Text(text, style: style);
    }

    return _buildMixedContent(context);
  }

  Widget _buildMixedContent(BuildContext context) {
    final List<InlineSpan> spans = [];
    final RegExp mathRegex = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$');
    int lastIndex = 0;

    for (final match in mathRegex.allMatches(text)) {
      // Add text before math
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: style,
        ));
      }

      // Add math equation
      final mathText = match.group(1) ?? match.group(2) ?? '';
      final isDisplayMode = match.group(1) != null; // $$ for display mode

      try {
        spans.add(WidgetSpan(
          child: Math.tex(
            mathText,
            mathStyle: isDisplayMode ? MathStyle.display : MathStyle.text,
            textStyle: style,
          ),
        ));
      } catch (e) {
        // If LaTeX parsing fails, show the raw text
        spans.add(TextSpan(
          text: match.group(0),
          style: style?.copyWith(color: Colors.red),
        ));
      }

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

// Helper to detect if text contains math
bool containsMath(String text) {
  return text.contains(r'$');
}
