import 'package:flutter/material.dart';

import '../models/search_result.dart';

/// Renders a search-result excerpt with the matched run highlighted.
///
/// `fragments` alternate plain/match (even index = plain, odd = match).
/// The match gets the app's primary colour + bold so it stands out
/// without needing the server''s CSS.
class SearchExcerptText extends StatelessWidget {
  final SearchExcerpt excerpt;
  final int maxLines;
  final TextStyle? style;

  const SearchExcerptText(
    this.excerpt, {
    super.key,
    this.maxLines = 2,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = style ?? Theme.of(context).textTheme.bodySmall;
    final matchStyle = base?.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
    );
    final spans = <TextSpan>[];
    for (var i = 0; i < excerpt.fragments.length; i++) {
      final f = excerpt.fragments[i];
      if (f.isEmpty) continue;
      spans.add(TextSpan(
        text: f,
        style: i.isOdd ? matchStyle : base,
      ));
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
