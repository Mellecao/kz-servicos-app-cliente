class MatchedSubstring {
  final int offset;
  final int length;

  const MatchedSubstring({required this.offset, required this.length});

  factory MatchedSubstring.fromJson(Map<String, dynamic> json) =>
      MatchedSubstring(
        offset: json['offset'] as int,
        length: json['length'] as int,
      );
}

class PlacePrediction {
  final String placeId;
  final String description;
  final List<MatchedSubstring> matchedSubstrings;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.matchedSubstrings,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) =>
      PlacePrediction(
        placeId: json['place_id'] as String? ?? '',
        description: json['description'] as String? ?? '',
        matchedSubstrings:
            ((json['matched_substrings'] as List?) ?? [])
                .map(
                  (e) =>
                      MatchedSubstring.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
      );
}
