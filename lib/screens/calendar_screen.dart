import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app_state.dart';
import '../models.dart';
import '../calendar_data.dart';
import '../data.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String selectedGroup = 'Todos';
  final List<String> groups = [
    'Todos', 'Grupo A', 'Grupo B', 'Grupo C', 'Grupo D', 'Grupo E', 'Grupo F',
    'Grupo G', 'Grupo H', 'Grupo I', 'Grupo J', 'Grupo K', 'Grupo L'
  ];

  String? _getFlagCode(String teamName) {
    // Normalizar nombres para la búsqueda (quitar acentos si es necesario, etc)
    final normalized = WorldCupProvider.removeAccents(teamName.toUpperCase());
    for (var group in WorldCupData.groups) {
      for (var country in group.countries) {
        if (WorldCupProvider.removeAccents(country.name.toUpperCase()) == normalized || 
            country.id.toUpperCase() == normalized ||
            country.code3.toUpperCase() == normalized) {
          return country.flagCode;
        }
      }
    }
    // Casos especiales manuales si el nombre en calendar_data no coincide exacto
    if (normalized.contains('EE.UU.')) return 'us';
    if (normalized.contains('ESTADOS UNIDOS')) return 'us';
    if (normalized.contains('REP. DE COREA')) return 'kr';
    if (normalized.contains('REP. CHECA')) return 'cz';
    if (normalized.contains('BOSNIA')) return 'ba';
    if (normalized.contains('CATAR')) return 'qa';
    if (normalized.contains('IRAN')) return 'ir';
    if (normalized.contains('ARABIA')) return 'sa';
    if (normalized.contains('NIGERIA')) return 'ng';
    if (normalized.contains('CONGO')) return 'cd';
    if (normalized.contains('IRAK') || normalized.contains('IRAQ')) return 'iq';
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context);
    final filteredMatches = selectedGroup == 'Todos'
        ? CalendarData.matches
        : CalendarData.matches.where((m) => m.group == selectedGroup).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('CALENDARIO 2026', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(provider.currentBgPath, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.9)],
                ),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 100),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('Todos los horarios son del Este de Estados Unidos (EST)', style: TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
              ),
              _buildGroupFilter(),
              Expanded(
                child: filteredMatches.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                        itemCount: filteredMatches.length,
                        itemBuilder: (context, index) {
                          return _buildMatchCard(filteredMatches[index]);
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final isSelected = selectedGroup == group;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(group, style: TextStyle(color: isSelected ? Colors.black : Colors.white70)),
              selected: isSelected,
              onSelected: (val) => setState(() => selectedGroup = group),
              selectedColor: const Color(0xFFD4AF37),
              backgroundColor: const Color(0xFF1E293B),
              checkmarkColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(WorldCupMatch match) {
    return Card(
      color: const Color(0xFF1E293B).withOpacity(0.8),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(match.date.toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                    if (match.time != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text('${match.time} EST', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                  child: Text(match.group, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTeam(match.team1, true)),
                const SizedBox(width: 8),
                _buildScoreBox(match.result?.split('-')[0].trim() ?? '-'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                _buildScoreBox(match.result?.split('-').last.trim() ?? '-'),
                const SizedBox(width: 8),
                Expanded(child: _buildTeam(match.team2, false)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 14),
                const SizedBox(width: 4),
                Flexible(child: Text(match.venue, style: const TextStyle(color: Colors.white38, fontSize: 11), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBox(String score) {
    return Container(
      width: 35,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      alignment: Alignment.center,
      child: Text(
        score,
        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
      ),
    );
  }

  Widget _buildTeam(String name, bool isLeft) {
    final flagCode = _getFlagCode(name);
    return Column(
      children: [
        if (flagCode != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: 'https://flagcdn.com/w160/$flagCode.png',
              width: 50, height: 35, fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.white10, width: 50, height: 35),
              errorWidget: (context, url, error) => const Icon(Icons.sports_soccer, color: Colors.white24, size: 30),
            ),
          )
        else
          const Icon(Icons.sports_soccer, color: Colors.white24, size: 35),
        const SizedBox(height: 10),
        Text(
          name.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, color: Colors.white10, size: 60),
          const SizedBox(height: 16),
          Text(
            'No hay partidos para este grupo todavía.',
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
