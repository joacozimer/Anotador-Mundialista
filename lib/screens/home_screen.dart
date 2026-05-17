import 'dart:async';
import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models.dart';
import '../app_state.dart';
import '../share_helper.dart';
import '../ad_helper.dart';
import '../config.dart';
import 'group_screen.dart';
import 'country_screen.dart';
import 'badges_screen.dart';
import 'social_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _intentDataStreamSubscription;
  String _activeFilter = 'Todos';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late ConfettiController _confettiController;
  
  // Memoización para optimizar memoria y CPU
  List<Country>? _memoizedFilteredCountries;
  String? _lastFilter;
  String? _lastQuery;
  int? _lastDataVersion;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && mounted) {
        ShareHelper.handleSharedFile(context, value.first.path);
      }
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && mounted) {
        ShareHelper.handleSharedFile(context, value.first.path);
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context);

    if (provider.shouldCelebrate) {
      _confettiController.play();
      provider.resetCelebration();
    }



    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => _showResetDialog(context, provider),
          child: Text(
            'ANOTADOR MUNDIALISTA',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        leading: Builder(
          builder: (context) => Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFFD4AF37)),
                onPressed: () {
                  provider.recordTap();
                  Scaffold.of(context).openDrawer();
                },
              ),
              if (provider.hasSocialPending)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
      drawer: _buildDrawer(context, provider),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => provider.recordTap(),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(provider.currentBgPath, fit: BoxFit.cover)),
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.65))),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildStatsDashboard(provider)),
                SliverToBoxAdapter(child: _buildFilterRow()),
                
                _activeFilter == 'Todos' && _searchQuery.isEmpty
                  ? _buildGroupsGrid(provider)
                  : _buildCountriesList(provider),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow, Colors.cyan],
                numberOfParticles: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsGrid(WorldCupProvider provider) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final group = provider.groups[index];
            final progress = provider.getGroupProgress(group.id);
            return _buildGroupCard(context, group, progress, provider, index);
          },
          childCount: provider.groups.length,
        ),
      ),
    );
  }

  Widget _buildCountriesList(WorldCupProvider provider) {
    final filteredCountries = _getFilteredCountries(provider);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final country = filteredCountries[index];
          return _buildCountryListTile(context, country, provider);
        },
        childCount: filteredCountries.length,
      ),
    );
  }

  List<Country> _getFilteredCountries(WorldCupProvider provider) {
    // Si nada ha cambiado, devolver la lista cacheada
    if (_memoizedFilteredCountries != null && 
        _lastFilter == _activeFilter && 
        _lastQuery == _searchQuery) {
      return _memoizedFilteredCountries!;
    }

    List<Country> allCountries = [];
    for (var g in provider.groups) {
      allCountries.addAll(g.countries);
    }

    if (_searchQuery.isNotEmpty) {
      final query = WorldCupProvider.removeAccents(_searchQuery.toLowerCase());
      allCountries = allCountries.where((c) {
        final nameMatch = WorldCupProvider.removeAccents(c.name.toLowerCase()).contains(query);
        final codeMatch = c.code3.toLowerCase().contains(query);
        return nameMatch || codeMatch;
      }).toList();
    }

    List<Country> result;
    if (_activeFilter == 'Todos') {
      result = allCountries;
    } else {
      result = allCountries.where((c) {
        final progress = provider.getCountryProgress(c.id);
        if (_activeFilter == 'Faltantes') return progress < 1.0;
        if (_activeFilter == 'Completadas') return progress == 1.0;
        if (_activeFilter == 'Repetidas') {
          for (int i = 1; i <= c.totalStickers; i++) {
            if (provider.getStickerCount(c.id, i) > 1) return true;
          }
          return false;
        }
        return true;
      }).toList();
    }

    _memoizedFilteredCountries = result;
    _lastFilter = _activeFilter;
    _lastQuery = _searchQuery;
    return result;
  }

  Widget _buildCountryListTile(BuildContext context, Country country, WorldCupProvider provider) {
    final progress = provider.getCountryProgress(country.id);
    return Card(
      color: const Color(0xFF1E293B).withOpacity(0.8),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: country.flagCode.isNotEmpty 
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4), 
              child: CachedNetworkImage(
                imageUrl: 'https://flagcdn.com/w80/${country.flagCode}.png', 
                width: 40,
                memCacheWidth: 80, // Optimización de RAM
              )
            )
          : const Icon(Icons.star, color: Color(0xFFD4AF37)),
        title: Text(country.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('Llevas ${provider.getObtainedCount(country.id)}/${country.totalStickers}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: CircularProgressIndicator(value: progress, color: const Color(0xFFD4AF37), backgroundColor: Colors.white10),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CountryScreen(country: country))),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onTapOutside: (event) => _searchFocusNode.unfocus(),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar país...',
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear, color: Colors.white54), onPressed: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
                setState(() => _searchQuery = '');
              })
            : null,
          filled: true,
          fillColor: const Color(0xFF1E293B).withOpacity(0.8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = ['Todos', 'Faltantes', 'Repetidas', 'Completadas'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (val) => setState(() => _activeFilter = f),
              backgroundColor: const Color(0xFF1E293B),
              selectedColor: const Color(0xFFD4AF37),
              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WorldCupProvider provider) {
    final user = provider.currentUser;
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          _buildDrawerHeader(user),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.emoji_events, 'Mis Insignias', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BadgesScreen()));
                }),
                _buildDrawerItem(
                  Icons.people, 
                  'Amigos', 
                  () async {
                    Navigator.pop(context);
                    if (!await provider.isOnline()) {
                      if (context.mounted) _showOfflineWarning(context);
                      return;
                    }
                    if (provider.currentUser == null) {
                      if (context.mounted) _showSocialLoginPrompt(context, provider);
                    } else {
                      if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => const SocialScreen()));
                    }
                  },
                  trailing: provider.hasSocialPending
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '${provider.pendingRequestsCount + provider.incomingReservationsCount}', 
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      )
                    : null,
                ),
                _buildDrawerItem(Icons.calendar_month, 'Calendario', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarScreen()));
                }),
                _buildDrawerItem(Icons.share, 'Compartir rápido', () {
                  Navigator.pop(context);
                  _quickShare(context, provider);
                }),
                const Divider(color: Colors.white10),
                _buildDrawerItem(Icons.settings, 'Configuración', () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _quickShare(BuildContext context, WorldCupProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Qué querés compartir?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_box_outline_blank, color: Color(0xFFD4AF37)),
              title: const Text('Solo Faltantes', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _executeShare(provider, shareMissing: true, shareRepeated: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Color(0xFFD4AF37)),
              title: const Text('Solo Repetidas', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _executeShare(provider, shareMissing: false, shareRepeated: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive, color: Color(0xFFD4AF37)),
              title: const Text('Ambas', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _executeShare(provider, shareMissing: true, shareRepeated: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getEmojiFlag(String flagCode) {
    if (flagCode.isEmpty) return '⭐';
    if (flagCode == 'coca') return '🥤';
    return flagCode.toUpperCase().split('').map((char) => String.fromCharCode(char.codeUnitAt(0) + 127397)).join();
  }

  void _executeShare(WorldCupProvider provider, {required bool shareMissing, required bool shareRepeated}) {
    String text = "Comparto mis figuritas del mundial:\n\n";
    
    if (shareMissing) {
      text += "*FALTANTES:*\n";
      for (var group in provider.groups) {
        for (var country in group.countries) {
          List<int> missing = [];
          for (int i = 1; i <= country.totalStickers; i++) {
            if (country.code3 == 'FWC' && i == 20) continue;
            if (provider.getStickerCount(country.id, i) == 0) missing.add(i);
          }
          if (missing.isNotEmpty) {
            text += "${_getEmojiFlag(country.flagCode)}(${country.code3}): ${missing.join(', ')}\n";
          }
        }
      }
    }

    if (shareRepeated) {
      if (shareMissing) text += "\n";
      text += "*REPETIDAS:*\n";
      for (var group in provider.groups) {
        for (var country in group.countries) {
          List<int> repeated = [];
          for (int i = 1; i <= country.totalStickers; i++) {
            if (country.code3 == 'FWC' && i == 20) continue;
            int count = provider.getStickerCount(country.id, i);
            if (count > 1) repeated.add(i);
          }
          if (repeated.isNotEmpty) {
            text += "${_getEmojiFlag(country.flagCode)}(${country.code3}): ${repeated.join(', ')}\n";
          }
        }
      }
    }
    
    Share.share(text);
  }

  Widget _buildDrawerHeader(User? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFD4AF37),
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName ?? 'Invitado', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user?.email ?? 'Modo offline', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color color = const Color(0xFFD4AF37), Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    );
  }

  Widget _buildBgSelector(WorldCupProvider provider) {
    final bgs = [
      {'id': 'Messi', 'path': 'assets/messi.png'},
      {'id': 'Maradona', 'path': 'assets/maradona.png'},
      {'id': 'Kempes', 'path': 'assets/kempes.png'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('FONDO DE PANTALLA', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                // Opción Aleatorio
                _buildBgThumbnail('Aleatorio', null, provider),
                // Opciones de Imagen
                ...bgs.map((bg) => _buildBgThumbnail(bg['id']!, bg['path']!, provider)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBgThumbnail(String id, String? path, WorldCupProvider provider) {
    final isSelected = provider.bgMode == id;
    return GestureDetector(
      onTap: () {
        provider.recordTap();
        provider.setBgMode(id);
      },
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.white10, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              path != null
                ? Image.asset(path, fit: BoxFit.cover)
                : Container(
                    color: Colors.white10,
                    child: const Icon(Icons.shuffle, color: Color(0xFFD4AF37), size: 30),
                  ),
              if (isSelected)
                Container(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(id, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsDashboard(WorldCupProvider provider) {
    final totalProgress = provider.getTotalProgress();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Faltantes', '${provider.missingCount}', Colors.redAccent),
              _buildStatItem('Repetidas', '${provider.repeatedCount}', Colors.orangeAccent),
              _buildStatItem('Total', '${provider.totalObtainedCount}', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: totalProgress,
                  backgroundColor: Colors.white10,
                  color: const Color(0xFFD4AF37),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                '${(totalProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGroupCard(BuildContext context, WorldCupGroup group, double progress, WorldCupProvider provider, int index) {
    final isComplete = progress == 1.0;
    final isSpecial = group.id == '★' || group.id == 'CC';
    
    return Card(
      color: isComplete ? const Color(0xFFD4AF37) : const Color(0xFF1E293B).withOpacity(0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          provider.recordTap();
          // Ir a la pantalla de grupo con navegación circular para todos los grupos
          Navigator.push(context, MaterialPageRoute(builder: (context) => GroupScreen(initialIndex: index)));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(group.name, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: isComplete ? Colors.black : Colors.white))),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white10,
                    color: isComplete ? Colors.black : const Color(0xFFD4AF37),
                  ),
                  Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isComplete ? Colors.black : Colors.white)),
                ],
              ),
              if (!isSpecial) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: group.countries.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: 'https://flagcdn.com/w160/${c.flagCode}.png',
                        width: 30, height: 20, fit: BoxFit.cover,
                        memCacheWidth: 60, // Optimización de RAM
                        placeholder: (context, url) => Container(width: 30, height: 20, color: Colors.white10),
                        errorWidget: (context, url, error) => const SizedBox(width: 30, height: 20),
                      ),
                    ),
                  )).toList(),
                ),
              ] else ...[
                const SizedBox(height: 12),
                group.id == 'CC'
                  ? Image.asset('assets/coca.png', width: 40, height: 26)
                  : Icon(Icons.star, size: 30, color: isComplete ? Colors.black : const Color(0xFFD4AF37)),
              ],
            ],
          ),
        ),
      ),
    );
  }



  void _showOfflineWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Text('Sin conexión', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Esta función requiere una conexión a internet activa para funcionar correctamente.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  void _showSocialLoginPrompt(BuildContext context, WorldCupProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Se requiere sesión', style: TextStyle(color: Colors.white)),
        content: const Text('Para usar las funciones de amigos e intercambios necesitas iniciar sesión con Google.', 
          style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () {
              Navigator.pop(context);
              _handleSignIn(context, provider).then((_) {
                if (provider.currentUser != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SocialScreen()));
                }
              });
            },
            child: const Text('INICIAR SESIÓN', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn(BuildContext context, WorldCupProvider provider) async {
    // Mostrar diálogo de carga y guardar referencia para cerrarlo
    bool loadingOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF1E293B),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFD4AF37)),
            const SizedBox(width: 20),
            const Text('Iniciando sesión...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ).then((_) => loadingOpen = false);

    bool success = false;
    try {
      await provider.signInWithGoogle();
      // Delay un poco más largo para asegurar sincronización en dispositivos lentos
      await Future.delayed(const Duration(milliseconds: 800));
      success = provider.currentUser != null;
    } catch (e) {
      print('Error en login: $e');
      // CERRAR CARGA ANTES DE MOSTRAR ERROR
      if (loadingOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingOpen = false;
      }
      
      // SI ES EL ERROR DE PIGEON, IGNORARLO (no mostrar cartel al usuario)
      final errorStr = e.toString();
      if (errorStr.contains('PigeonUserDetails') || errorStr.contains('List<Object?>')) {
        print('Ignorando error conocido de Pigeon casting...');
      } else if (context.mounted) {
        _showErrorDialog(context, 'Error: $e');
      }
      // No retornamos aquí para permitir que chequee si el login funcionó de todas formas
    }

    // CERRAR CARGA AL TERMINAR EXITOSAMENTE
    if (loadingOpen && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      loadingOpen = false;
    }

    // PROCESAR RESULTADO
    if (provider.currentUser != null) {
      provider.checkNewBadges();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Inicio de sesión exitoso!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Error', style: TextStyle(color: Colors.redAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CERRAR')),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WorldCupProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Eliminar todo?', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Esta acción borrará todas tus figuritas marcadas. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              provider.resetAll();
              Navigator.pop(context);
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showShareOptionsDialog(BuildContext context, WorldCupProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Qué deseas compartir?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todo el progreso', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ShareHelper.shareData(context, {'type': 'all', 'data': 'FULL_DATA_PLACEHOLDER'});
              },
            ),
            ListTile(
              title: const Text('Solo las que me faltan', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ShareHelper.shareData(context, {'type': 'missing', 'data': 'MISSING_DATA_PLACEHOLDER'});
              },
            ),
            ListTile(
              title: const Text('Solo las repetidas', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ShareHelper.shareData(context, {'type': 'repeated', 'data': 'REPEATED_DATA_PLACEHOLDER'});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuggestionDialog(BuildContext context, WorldCupProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 40,
          top: 15,
          left: 25,
          right: 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFD4AF37), size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sugerencias', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text('Tu opinión nos ayuda a crecer', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _SuggestionForm(provider: provider),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WorldCupProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async { await provider.signOut(); if (context.mounted) Navigator.pop(context); }, child: const Text('Salir')),
        ],
      ),
    );
  }
}

class _SuggestionForm extends StatefulWidget {
  final WorldCupProvider provider;
  const _SuggestionForm({required this.provider});

  @override
  State<_SuggestionForm> createState() => _SuggestionFormState();
}

class _SuggestionFormState extends State<_SuggestionForm> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Cuéntanos qué te gustaría mejorar...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            shadowColor: const Color(0xFFD4AF37).withOpacity(0.4),
          ),
          onPressed: _isSending ? null : () => _sendViaGmail(context),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_rounded, size: 20),
              SizedBox(width: 10),
              Text('ENVIAR POR GMAIL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
            foregroundColor: const Color(0xFFD4AF37),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: _isSending ? null : () => _sendViaApp(context),
          child: _isSending 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 10),
                  Text('ENVIAR DESDE LA APP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 13)),
                ],
              ),
        ),
      ],
    );
  }

  Future<void> _sendViaGmail(BuildContext context) async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      _showSnack(context, 'Por favor escribe algo primero', Colors.orange);
      return;
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Sugerencia Anotador Mundialista',
        'body': message,
      }),
    );

    try {
      final success = await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      if (success) {
        if (context.mounted) Navigator.pop(context);
      } else {
        throw 'No se pudo lanzar la URL';
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'No se pudo abrir Gmail. Intenta usar "Enviar desde la App"', Colors.redAccent);
      }
    }
  }

  Future<void> _sendViaApp(BuildContext context) async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      _showSnack(context, 'Por favor escribe algo primero', Colors.orange);
      return;
    }

    setState(() => _isSending = true);
    try {
      await widget.provider.sendSuggestion(message);
      if (context.mounted) {
        Navigator.pop(context);
        _showSnack(context, '¡Sugerencia enviada! Muchas gracias 🙌', Colors.green);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnack(context, 'Error al enviar: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color),
    );
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
