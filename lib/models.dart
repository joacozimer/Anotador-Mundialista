class Country {
  final String id;
  final String name;
  final String flagCode;
  final String code3; // Código de 3 letras (ej: ARG, BRA)
  final bool isRepechaje;
  final bool isSpecial;
  final bool isCocaCola;
  final int totalStickers;

  const Country({
    required this.id,
    required this.name,
    required this.flagCode,
    this.code3 = '',
    this.isRepechaje = false,
    this.isSpecial = false,
    this.isCocaCola = false,
    this.totalStickers = 20,
  });
}

class WorldCupGroup {
  final String id;
  final String name;
  final List<Country> countries;

  const WorldCupGroup({
    required this.id,
    required this.name,
    required this.countries,
  });
}

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? nickname;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.nickname,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      nickname: data['nickname'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'nickname': nickname,
      'lastLogin': DateTime.now().toIso8601String(),
    };
  }
}

class Badge {
  final String id;
  final String title;
  final String description;
  final String category;
  final String icon;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
  });
}

class WorldCupMatch {
  final int id;
  final String date;
  final String team1;
  final String team2;
  final String venue;
  final String group;
  final String stage;
  final String? result;

  const WorldCupMatch({
    required this.id,
    required this.date,
    required this.team1,
    required this.team2,
    required this.venue,
    this.group = '',
    this.stage = 'Fase de Grupos',
    this.result,
  });
}
