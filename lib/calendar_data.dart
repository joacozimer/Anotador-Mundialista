import 'models.dart';

class CalendarData {
  static const List<WorldCupMatch> matches = [
    // 11 junio
    WorldCupMatch(id: 1, date: '11 de junio 2026', time: '15:00', team1: 'México', team2: 'Sudáfrica', venue: 'Estadio Ciudad de México', group: 'Grupo A'),
    WorldCupMatch(id: 2, date: '11 de junio 2026', time: '22:00', team1: 'Rep. de Corea', team2: 'Rep. Checa', venue: 'Estadio Guadalajara', group: 'Grupo A'),
    // 12 junio
    WorldCupMatch(id: 3, date: '12 de junio 2026', time: '15:00', team1: 'Canadá', team2: 'Bosnia y Herz.', venue: 'Estadio Toronto', group: 'Grupo B'),
    WorldCupMatch(id: 4, date: '12 de junio 2026', time: '21:00', team1: 'Estados Unidos', team2: 'Paraguay', venue: 'Estadio Los Ángeles', group: 'Grupo D'),
    // 13 junio
    WorldCupMatch(id: 5, date: '13 de junio 2026', time: '15:00', team1: 'Catar', team2: 'Suiza', venue: 'Estadio Bahía de San Francisco', group: 'Grupo B'),
    WorldCupMatch(id: 6, date: '13 de junio 2026', time: '18:00', team1: 'Brasil', team2: 'Marruecos', venue: 'Estadio Nueva York Nueva Jersey', group: 'Grupo C'),
    WorldCupMatch(id: 7, date: '13 de junio 2026', time: '21:00', team1: 'Haití', team2: 'Escocia', venue: 'Estadio Boston', group: 'Grupo C'),
    WorldCupMatch(id: 8, date: '13 de junio 2026', time: '00:00', team1: 'Australia', team2: 'Turquía', venue: 'Estadio BC Place Vancouver', group: 'Grupo D'),
    // 14 junio
    WorldCupMatch(id: 9, date: '14 de junio 2026', time: '13:00', team1: 'Alemania', team2: 'Curazao', venue: 'Estadio Houston', group: 'Grupo E'),
    WorldCupMatch(id: 10, date: '14 de junio 2026', time: '16:00', team1: 'Países Bajos', team2: 'Japón', venue: 'Estadio Dallas', group: 'Grupo F'),
    WorldCupMatch(id: 11, date: '14 de junio 2026', time: '19:00', team1: 'Costa de Marfil', team2: 'Ecuador', venue: 'Estadio Filadelfia', group: 'Grupo E'),
    WorldCupMatch(id: 12, date: '14 de junio 2026', time: '22:00', team1: 'Suecia', team2: 'Túnez', venue: 'Estadio Monterrey', group: 'Grupo F'),
    // 15 junio
    WorldCupMatch(id: 13, date: '15 de junio 2026', time: '12:00', team1: 'España', team2: 'Cabo Verde', venue: 'Estadio Atlanta', group: 'Grupo H'),
    WorldCupMatch(id: 14, date: '15 de junio 2026', time: '15:00', team1: 'Bélgica', team2: 'Egipto', venue: 'Estadio Seattle', group: 'Grupo G'),
    WorldCupMatch(id: 15, date: '15 de junio 2026', time: '18:00', team1: 'Arabia Saudí', team2: 'Uruguay', venue: 'Estadio Miami', group: 'Grupo H'),
    WorldCupMatch(id: 16, date: '15 de junio 2026', time: '21:00', team1: 'Irán', team2: 'Nueva Zelanda', venue: 'Estadio Los Ángeles', group: 'Grupo G'),
    // 16 junio
    WorldCupMatch(id: 17, date: '16 de junio 2026', time: '15:00', team1: 'Francia', team2: 'Senegal', venue: 'Estadio Nueva York Nueva Jersey', group: 'Grupo I'),
    WorldCupMatch(id: 18, date: '16 de junio 2026', time: '18:00', team1: 'Irak', team2: 'Noruega', venue: 'Estadio Boston', group: 'Grupo I'),
    WorldCupMatch(id: 19, date: '16 de junio 2026', time: '21:00', team1: 'Argentina', team2: 'Argelia', venue: 'Estadio Kansas City', group: 'Grupo J'),
    WorldCupMatch(id: 20, date: '16 de junio 2026', time: '00:00', team1: 'Austria', team2: 'Jordania', venue: 'Estadio Bahía de San Francisco', group: 'Grupo J'),
    // 17 junio
    WorldCupMatch(id: 21, date: '17 de junio 2026', time: '13:00', team1: 'Portugal', team2: 'RD Congo', venue: 'Estadio Houston', group: 'Grupo K'),
    WorldCupMatch(id: 22, date: '17 de junio 2026', time: '16:00', team1: 'Inglaterra', team2: 'Croacia', venue: 'Estadio Dallas', group: 'Grupo L'),
    WorldCupMatch(id: 23, date: '17 de junio 2026', time: '19:00', team1: 'Ghana', team2: 'Panamá', venue: 'Estadio Toronto', group: 'Grupo L'),
    WorldCupMatch(id: 24, date: '17 de junio 2026', time: '22:00', team1: 'Uzbekistán', team2: 'Colombia', venue: 'Estadio Ciudad de México', group: 'Grupo K'),
    // 18 junio
    WorldCupMatch(id: 25, date: '18 de junio 2026', time: '12:00', team1: 'Rep. Checa', team2: 'Sudáfrica', venue: 'Estadio Atlanta', group: 'Grupo A'),
    WorldCupMatch(id: 26, date: '18 de junio 2026', time: '15:00', team1: 'Suiza', team2: 'Bosnia y Herz.', venue: 'Estadio Los Ángeles', group: 'Grupo B'),
    WorldCupMatch(id: 27, date: '18 de junio 2026', time: '18:00', team1: 'Canadá', team2: 'Catar', venue: 'Estadio BC Place Vancouver', group: 'Grupo B'),
    WorldCupMatch(id: 28, date: '18 de junio 2026', time: '21:00', team1: 'México', team2: 'Rep. de Corea', venue: 'Estadio Guadalajara', group: 'Grupo A'),
    // 19 junio
    WorldCupMatch(id: 29, date: '19 de junio 2026', time: '15:00', team1: 'Estados Unidos', team2: 'Australia', venue: 'Estadio Seattle', group: 'Grupo D'),
    WorldCupMatch(id: 30, date: '19 de junio 2026', time: '18:00', team1: 'Escocia', team2: 'Marruecos', venue: 'Estadio Boston', group: 'Grupo C'),
    WorldCupMatch(id: 31, date: '19 de junio 2026', time: '21:00', team1: 'Brasil', team2: 'Haití', venue: 'Estadio Filadelfia', group: 'Grupo C'),
    WorldCupMatch(id: 32, date: '19 de junio 2026', time: '00:00', team1: 'Turquía', team2: 'Paraguay', venue: 'Estadio Bahía de San Francisco', group: 'Grupo D'),
    // 20 junio
    WorldCupMatch(id: 33, date: '20 de junio 2026', time: '13:00', team1: 'Países Bajos', team2: 'Suecia', venue: 'Estadio Houston', group: 'Grupo F'),
    WorldCupMatch(id: 34, date: '20 de junio 2026', time: '16:00', team1: 'Alemania', team2: 'Costa de Marfil', venue: 'Estadio Toronto', group: 'Grupo E'),
    WorldCupMatch(id: 35, date: '20 de junio 2026', time: '22:00', team1: 'Ecuador', team2: 'Curazao', venue: 'Estadio Kansas City', group: 'Grupo E'),
    WorldCupMatch(id: 36, date: '20 de junio 2026', time: '00:00', team1: 'Túnez', team2: 'Japón', venue: 'Estadio Monterrey', group: 'Grupo F'),
    // 21 junio
    WorldCupMatch(id: 37, date: '21 de junio 2026', time: '12:00', team1: 'España', team2: 'Arabia Saudí', venue: 'Estadio Atlanta', group: 'Grupo H'),
    WorldCupMatch(id: 38, date: '21 de junio 2026', time: '15:00', team1: 'Bélgica', team2: 'Irán', venue: 'Estadio Los Ángeles', group: 'Grupo G'),
    WorldCupMatch(id: 39, date: '21 de junio 2026', time: '18:00', team1: 'Uruguay', team2: 'Cabo Verde', venue: 'Estadio Miami', group: 'Grupo H'),
    WorldCupMatch(id: 40, date: '21 de junio 2026', time: '21:00', team1: 'Nueva Zelanda', team2: 'Egipto', venue: 'Estadio BC Place Vancouver', group: 'Grupo G'),
    // 22 junio
    WorldCupMatch(id: 41, date: '22 de junio 2026', time: '13:00', team1: 'Argentina', team2: 'Austria', venue: 'Estadio Dallas', group: 'Grupo J'),
    WorldCupMatch(id: 42, date: '22 de junio 2026', time: '17:00', team1: 'Francia', team2: 'Irak', venue: 'Estadio Filadelfia', group: 'Grupo I'),
    WorldCupMatch(id: 43, date: '22 de junio 2026', time: '20:00', team1: 'Noruega', team2: 'Senegal', venue: 'Estadio Nueva York Nueva Jersey', group: 'Grupo I'),
    WorldCupMatch(id: 44, date: '22 de junio 2026', time: '23:00', team1: 'Jordania', team2: 'Argelia', venue: 'Estadio Bahía de San Francisco', group: 'Grupo J'),
    // 23 junio
    WorldCupMatch(id: 45, date: '23 de junio 2026', time: '13:00', team1: 'Portugal', team2: 'Uzbekistán', venue: 'Estadio Houston', group: 'Grupo K'),
    WorldCupMatch(id: 46, date: '23 de junio 2026', time: '16:00', team1: 'Inglaterra', team2: 'Ghana', venue: 'Estadio Boston', group: 'Grupo L'),
    WorldCupMatch(id: 47, date: '23 de junio 2026', time: '19:00', team1: 'Panamá', team2: 'Croacia', venue: 'Estadio Toronto', group: 'Grupo L'),
    WorldCupMatch(id: 48, date: '23 de junio 2026', time: '22:00', team1: 'Colombia', team2: 'RD Congo', venue: 'Estadio Guadalajara', group: 'Grupo K'),
    // 24 junio
    WorldCupMatch(id: 49, date: '24 de junio 2026', time: '15:00', team1: 'Suiza', team2: 'Canadá', venue: 'Estadio BC Place Vancouver', group: 'Grupo B'),
    WorldCupMatch(id: 50, date: '24 de junio 2026', time: '15:00', team1: 'Bosnia y Herz.', team2: 'Catar', venue: 'Estadio Seattle', group: 'Grupo B'),
    WorldCupMatch(id: 51, date: '24 de junio 2026', time: '18:00', team1: 'Escocia', team2: 'Brasil', venue: 'Estadio Miami', group: 'Grupo C'),
    WorldCupMatch(id: 52, date: '24 de junio 2026', time: '18:00', team1: 'Marruecos', team2: 'Haití', venue: 'Estadio Atlanta', group: 'Grupo C'),
    WorldCupMatch(id: 53, date: '24 de junio 2026', time: '21:00', team1: 'Rep. Checa', team2: 'México', venue: 'Estadio Ciudad de México', group: 'Grupo A'),
    WorldCupMatch(id: 54, date: '24 de junio 2026', time: '21:00', team1: 'Sudáfrica', team2: 'Rep. de Corea', venue: 'Estadio Monterrey', group: 'Grupo A'),
    // 25 junio
    WorldCupMatch(id: 55, date: '25 de junio 2026', time: '16:00', team1: 'Curazao', team2: 'Costa de Marfil', venue: 'Estadio Filadelfia', group: 'Grupo E'),
    WorldCupMatch(id: 56, date: '25 de junio 2026', time: '16:00', team1: 'Ecuador', team2: 'Alemania', venue: 'Estadio Nueva York Nueva Jersey', group: 'Grupo E'),
    WorldCupMatch(id: 57, date: '25 de junio 2026', time: '19:00', team1: 'Japón', team2: 'Suecia', venue: 'Estadio Dallas', group: 'Grupo F'),
    WorldCupMatch(id: 58, date: '25 de junio 2026', time: '19:00', team1: 'Túnez', team2: 'Países Bajos', venue: 'Estadio Kansas City', group: 'Grupo F'),
    WorldCupMatch(id: 59, date: '25 de junio 2026', time: '22:00', team1: 'Turquía', team2: 'Estados Unidos', venue: 'Estadio Los Ángeles', group: 'Grupo D'),
    WorldCupMatch(id: 60, date: '25 de junio 2026', time: '22:00', team1: 'Paraguay', team2: 'Australia', venue: 'Estadio Bahía de San Francisco', group: 'Grupo D'),
    // 26 junio
    WorldCupMatch(id: 61, date: '26 de junio 2026', time: '15:00', team1: 'Noruega', team2: 'Francia', venue: 'Estadio Boston', group: 'Grupo I'),
    WorldCupMatch(id: 62, date: '26 de junio 2026', time: '15:00', team1: 'Senegal', team2: 'Irak', venue: 'Estadio Toronto', group: 'Grupo I'),
    WorldCupMatch(id: 63, date: '26 de junio 2026', time: '20:00', team1: 'Cabo Verde', team2: 'Arabia Saudí', venue: 'Estadio Houston', group: 'Grupo H'),
    WorldCupMatch(id: 64, date: '26 de junio 2026', time: '20:00', team1: 'Uruguay', team2: 'España', venue: 'Estadio Guadalajara', group: 'Grupo H'),
    WorldCupMatch(id: 65, date: '26 de junio 2026', time: '23:00', team1: 'Egipto', team2: 'Irán', venue: 'Estadio Seattle', group: 'Grupo G'),
    WorldCupMatch(id: 66, date: '26 de junio 2026', time: '23:00', team1: 'Nueva Zelanda', team2: 'Bélgica', venue: 'Estadio BC Place Vancouver', group: 'Grupo G'),
    // 27 junio
    WorldCupMatch(id: 67, date: '27 de junio 2026', time: '17:00', team1: 'Panamá', team2: 'Inglaterra', venue: 'Estadio Nueva York Nueva Jersey', group: 'Grupo L'),
    WorldCupMatch(id: 68, date: '27 de junio 2026', time: '17:00', team1: 'Croacia', team2: 'Ghana', venue: 'Estadio Filadelfia', group: 'Grupo L'),
    WorldCupMatch(id: 69, date: '27 de junio 2026', time: '19:30', team1: 'Colombia', team2: 'Portugal', venue: 'Estadio Miami', group: 'Grupo K'),
    WorldCupMatch(id: 70, date: '27 de junio 2026', time: '19:30', team1: 'RD Congo', team2: 'Uzbekistán', venue: 'Estadio Atlanta', group: 'Grupo K'),
    WorldCupMatch(id: 71, date: '27 de junio 2026', time: '22:00', team1: 'Argelia', team2: 'Austria', venue: 'Estadio Kansas City', group: 'Grupo J'),
    WorldCupMatch(id: 72, date: '27 de junio 2026', time: '22:00', team1: 'Jordania', team2: 'Argentina', venue: 'Estadio Dallas', group: 'Grupo J'),
  ];
}
