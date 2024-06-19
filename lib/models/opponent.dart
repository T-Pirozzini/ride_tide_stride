class Opponent {
  final List<String> name;
  final List<String> image;
  final Map<String, String> bestTimes;
  final String teamName;
  final Map<String, String> slogan;
  final List<String> activity;
  final double distanceMax;

  Opponent({
    required this.name,
    required this.image,
    required this.bestTimes,
    required this.teamName,
    required this.slogan,
    required this.activity,
    required this.distanceMax,
  });

  factory Opponent.fromMap(Map<String, dynamic> map) {
    return Opponent(
      name: List<String>.from(map['name']),
      activity: List<String>.from(map['activity']),
      image: List<String>.from(map['image']),
      bestTimes: Map<String, String>.from(map['bestTimes']),
      teamName: map['teamName'],
      slogan: Map<String, String>.from(map['slogan']),
      distanceMax: map['distanceMax'].toDouble(),
    );
  }
}
