class SearchResultGroup {
  final String notePath;
  final String displayPath;
  final List<String> matches;
  final bool isFileNameMatch;

  /// Structured form of `matches` for highlighted rendering. One-to-one
  /// with `matches` when present; empty for filename-only matches.
  final List<SearchExcerpt> excerpts;

  const SearchResultGroup({
    required this.notePath,
    required this.displayPath,
    required this.matches,
    this.isFileNameMatch = false,
    this.excerpts = const [],
  });
}

/// A content-match excerpt with the server-emitted highlight split into
/// alternating non-matched / matched fragments.
///
/// `SearchResultGroup.matches` keeps a plain-text preview for backward
/// compatibility; `excerpts` carries the structured form so the UI can
/// render the matched run in `colorScheme.primary` + bold.
class SearchExcerpt {
  /// Ordered text fragments. Even indices are plain text; odd indices
  /// are the matched term.
  final List<String> fragments;

  const SearchExcerpt(this.fragments);

  String get plain => fragments.join();
}
