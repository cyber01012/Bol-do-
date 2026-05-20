class RankedProvider {
  final String providerId;
  final String name;
  final double score;
  final String reasoning;

  RankedProvider({
    required this.providerId,
    required this.name,
    required this.score,
    required this.reasoning,
  });

  factory RankedProvider.fromJson(Map<String, dynamic> json) {
    return RankedProvider(
      providerId: json['provider_id'] ?? '',
      name: json['name'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      reasoning: json['reasoning'] ?? '',
    );
  }
}

class RankingOutput {
  final List<RankedProvider> rankedProviders;
  final RankedProvider? topChoice;

  RankingOutput({
    required this.rankedProviders,
    this.topChoice,
  });

  factory RankingOutput.fromJson(Map<String, dynamic> json) {
    var rankedList = (json['ranked_providers'] as List?)
        ?.map((item) => RankedProvider.fromJson(item))
        .toList() ?? [];
    
    RankedProvider? top;
    if (json['top_choice'] != null) {
      top = RankedProvider.fromJson(json['top_choice']);
    } else if (rankedList.isNotEmpty) {
      top = rankedList.first;
    }

    return RankingOutput(
      rankedProviders: rankedList,
      topChoice: top,
    );
  }
}
