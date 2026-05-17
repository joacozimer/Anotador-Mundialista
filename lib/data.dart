import 'models.dart';

class WorldCupData {
  static const List<WorldCupGroup> groups = [
    WorldCupGroup(id: '★', name: 'ESPECIAL', countries: [
      Country(id: 'fwc', name: 'ESPECIAL', flagCode: '', code3: 'FWC', isSpecial: true, totalStickers: 20),
    ]),
    WorldCupGroup(id: 'A', name: 'GRUPO A', countries: [
      Country(id: 'mx', name: 'MÉXICO', flagCode: 'mx', code3: 'MEX'),
      Country(id: 'kr', name: 'COREA DEL SUR', flagCode: 'kr', code3: 'KOR'),
      Country(id: 'za', name: 'SUDAFRICA', flagCode: 'za', code3: 'RSA'),
      Country(id: 'cz', name: 'CHECOSLOVAQUIA', flagCode: 'cz', code3: 'TCH'),
    ]),
    WorldCupGroup(id: 'B', name: 'GRUPO B', countries: [
      Country(id: 'ca', name: 'CANADÁ', flagCode: 'ca', code3: 'CAN'),
      Country(id: 'ba', name: 'BOSNIA', flagCode: 'ba', code3: 'BIH'),
      Country(id: 'qa', name: 'QATAR', flagCode: 'qa', code3: 'QAT'),
      Country(id: 'ch', name: 'SUIZA', flagCode: 'ch', code3: 'SUI'),
    ]),
    WorldCupGroup(id: 'C', name: 'GRUPO C', countries: [
      Country(id: 'br', name: 'BRASIL', flagCode: 'br', code3: 'BRA'),
      Country(id: 'ma', name: 'MARRUECOS', flagCode: 'ma', code3: 'MAR'),
      Country(id: 'ht', name: 'HAITÍ', flagCode: 'ht', code3: 'HAI'),
      Country(id: 'gb-sct', name: 'ESCOCIA', flagCode: 'gb-sct', code3: 'SCO'),
    ]),
    WorldCupGroup(id: 'D', name: 'GRUPO D', countries: [
      Country(id: 'us', name: 'ESTADOS UNIDOS', flagCode: 'us', code3: 'USA'),
      Country(id: 'py', name: 'PARAGUAY', flagCode: 'py', code3: 'PAR'),
      Country(id: 'au', name: 'AUSTRALIA', flagCode: 'au', code3: 'AUS'),
      Country(id: 'tr', name: 'TURQUÍA', flagCode: 'tr', code3: 'TUR'),
    ]),
    WorldCupGroup(id: 'E', name: 'GRUPO E', countries: [
      Country(id: 'de', name: 'ALEMANIA', flagCode: 'de', code3: 'GER'),
      Country(id: 'cw', name: 'CURAZAO', flagCode: 'cw', code3: 'CUW'),
      Country(id: 'ci', name: 'COSTA DE MARFIL', flagCode: 'ci', code3: 'CIV'),
      Country(id: 'ec', name: 'ECUADOR', flagCode: 'ec', code3: 'ECU'),
    ]),
    WorldCupGroup(id: 'F', name: 'GRUPO F', countries: [
      Country(id: 'nl', name: 'PAISES BAJOS', flagCode: 'nl', code3: 'NED'),
      Country(id: 'jp', name: 'JAPÓN', flagCode: 'jp', code3: 'JPN'),
      Country(id: 'se', name: 'SUECIA', flagCode: 'se', code3: 'SWE'),
      Country(id: 'tn', name: 'TÚNEZ', flagCode: 'tn', code3: 'TUN'),
    ]),
    WorldCupGroup(id: 'G', name: 'GRUPO G', countries: [
      Country(id: 'be', name: 'BÉLGICA', flagCode: 'be', code3: 'BEL'),
      Country(id: 'eg', name: 'EGIPTO', flagCode: 'eg', code3: 'EGY'),
      Country(id: 'ir', name: 'IRÁN', flagCode: 'ir', code3: 'IRN'),
      Country(id: 'nz', name: 'NUEVA ZELANDA', flagCode: 'nz', code3: 'NZL'),
    ]),
    WorldCupGroup(id: 'H', name: 'GRUPO H', countries: [
      Country(id: 'es', name: 'ESPAÑA', flagCode: 'es', code3: 'ESP'),
      Country(id: 'cv', name: 'CABO VERDE', flagCode: 'cv', code3: 'CPV'),
      Country(id: 'sa', name: 'ARABIA S.', flagCode: 'sa', code3: 'KSA'),
      Country(id: 'uy', name: 'URUGUAY', flagCode: 'uy', code3: 'URU'),
    ]),
    WorldCupGroup(id: 'I', name: 'GRUPO I', countries: [
      Country(id: 'fr', name: 'FRANCIA', flagCode: 'fr', code3: 'FRA'),
      Country(id: 'sn', name: 'SENEGAL', flagCode: 'sn', code3: 'SEN'),
      Country(id: 'iq', name: 'IRAQ', flagCode: 'iq', code3: 'IRQ'),
      Country(id: 'no', name: 'NORUEGA', flagCode: 'no', code3: 'NOR'),
    ]),
    WorldCupGroup(id: 'J', name: 'GRUPO J', countries: [
      Country(id: 'ar', name: 'ARGENTINA', flagCode: 'ar', code3: 'ARG'),
      Country(id: 'dz', name: 'ARGELIA', flagCode: 'dz', code3: 'ALG'),
      Country(id: 'at', name: 'AUSTRIA', flagCode: 'at', code3: 'AUT'),
      Country(id: 'jo', name: 'JORDANIA', flagCode: 'jo', code3: 'JOR'),
    ]),
    WorldCupGroup(id: 'K', name: 'GRUPO K', countries: [
      Country(id: 'pt', name: 'PORTUGAL', flagCode: 'pt', code3: 'POR'),
      Country(id: 'cd', name: 'CONGO', flagCode: 'cd', code3: 'COD'),
      Country(id: 'uz', name: 'UZBEKISTÁN', flagCode: 'uz', code3: 'UZB'),
      Country(id: 'co', name: 'COLOMBIA', flagCode: 'co', code3: 'COL'),
    ]),
    WorldCupGroup(id: 'L', name: 'GRUPO L', countries: [
      Country(id: 'gb-eng', name: 'INGLATERRA', flagCode: 'gb-eng', code3: 'ENG'),
      Country(id: 'hr', name: 'CROACIA', flagCode: 'hr', code3: 'CRO'),
      Country(id: 'gh', name: 'GHANA', flagCode: 'gh', code3: 'GHA'),
      Country(id: 'pa', name: 'PANAMÁ', flagCode: 'pa', code3: 'PAN'),
    ]),
    WorldCupGroup(id: 'CC', name: 'COCA COLA', countries: [
      Country(id: 'coca', name: 'COCA COLA', flagCode: '', code3: 'CC', isCocaCola: true, totalStickers: 14),
    ]),
  ];

  static const List<Badge> badges = [
    Badge(id: 'first', title: 'Primer Paso', description: 'Consigue tu primera figurita', category: 'Bronce', icon: '⚽'),
    Badge(id: 'auth', title: 'Usuario Oficial', description: 'Inicia sesión con Google', category: 'Bronce', icon: '👤'),
    Badge(id: 'friends', title: 'Socio de Canje', description: 'Consigue tu primer amigo', category: 'Bronce', icon: '🤝'),
    Badge(id: 'friends_2', title: 'Dúo Dinámico', description: 'Ten 2 amigos agregados', category: 'Bronce', icon: '👥'),
    Badge(id: 'mexico', title: 'Viva México', description: 'Completa la colección de México', category: 'Plata', icon: '🇲🇽'),
    Badge(id: 'group_a', title: 'Dueño del Grupo A', description: 'Completa el Grupo A', category: 'Plata', icon: '🏆'),
    Badge(id: 'repeated_master', title: 'Rey de los Repes', description: 'Ten más de 50 repetidas', category: 'Plata', icon: '🔄'),
    Badge(id: 'half', title: 'A Mitad de Camino', description: 'Llega al 50% del álbum', category: 'Oro', icon: '📈'),
    Badge(id: 'argentina', title: 'Coronados de Gloria', description: 'Completa la colección de Argentina', category: 'Oro', icon: '🇦🇷'),
    Badge(id: 'brazil', title: 'O Mais Grande', description: 'Completa la colección de Brasil', category: 'Oro', icon: '🇧🇷'),
    Badge(id: 'special', title: 'Brillo Dorado', description: 'Completa todas las Especiales', category: 'Oro', icon: '✨'),
    Badge(id: 'coca_cola', title: 'Sabor Mundialista', description: 'Completa la colección Coca-Cola', category: 'Oro', icon: '🥤'),
    Badge(id: 'full', title: 'Coleccionista Legendario', description: 'Completa todo el álbum', category: 'Diamante', icon: '👑'),
    Badge(id: 'collector', title: 'Gran Coleccionista', description: 'Consigue todas las demás insignias', category: 'Diamante', icon: '💎'),
  ];
}
