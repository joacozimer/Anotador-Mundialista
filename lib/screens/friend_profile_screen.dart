import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app_state.dart';
import '../models.dart';

class FriendProfileScreen extends StatefulWidget {
  final UserProfile profile;
  const FriendProfileScreen({super.key, required this.profile});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, Map<int, int>>? _friendStickers;
  bool _loading = true;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Stickers seleccionados: "countryId_number"
  final Set<String> _wantedStickers = {};
  final Set<String> _offeredStickers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriendData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriendData() async {
    final provider = Provider.of<WorldCupProvider>(context, listen: false);
    final stickers = await provider.getFriendStickers(widget.profile.uid);
    if (mounted) {
      setState(() {
        _friendStickers = stickers;
        _loading = false;
      });
    }
  }

  int _calculateWeight(Set<String> stickerKeys, WorldCupProvider provider) {
    int total = 0;
    for (var key in stickerKeys) {
      final parts = key.split('_');
      total += provider.getStickerWeight(parts[0], int.parse(parts[1]));
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context);
    final weightWanted = _calculateWeight(_wantedStickers, provider);
    final weightOffered = _calculateWeight(_offeredStickers, provider);
    final isBalanced = weightWanted == weightOffered && weightWanted > 0;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Text(widget.profile.nickname ?? 'Amigo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'TIENE PARA MÍ'),
            Tab(text: 'TENGO PARA ÉL'),
          ],
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
        : Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(provider.currentBgPath, fit: BoxFit.cover),
                ),
              ),
              Column(
                children: [
                  _buildSearchBar(),
                  _buildWeightInfo(weightWanted, weightOffered),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExchangesList(provider, isForMe: true),
                        _buildExchangesList(provider, isForMe: false),
                      ],
                    ),
                  ),
                ],
              ),
              if (_wantedStickers.isNotEmpty || _offeredStickers.isNotEmpty)
                _buildReservationButton(provider, isBalanced, weightWanted, weightOffered),
            ],
          ),
    );
  }

  Widget _buildWeightInfo(int wanted, int offered) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      color: Colors.black45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _weightChip('Pide: $wanted', Colors.orangeAccent),
          const Icon(Icons.compare_arrows, color: Colors.white24),
          _weightChip('Ofrece: $offered', Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _weightChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar país...',
          hintStyle: const TextStyle(color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
          filled: true,
          fillColor: const Color(0xFF1E293B).withOpacity(0.8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildExchangesList(WorldCupProvider provider, {required bool isForMe}) {
    final exchanges = _getExchanges(provider, isForMe: isForMe);
    
    if (exchanges.isEmpty) {
      return const Center(child: Text('No hay coincidencias', style: TextStyle(color: Colors.white24)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: exchanges.length,
      itemBuilder: (context, index) {
        final countryId = exchanges.keys.elementAt(index);
        final stickers = exchanges[countryId]!;
        final country = provider.getCountryById(countryId);

        return _buildCountryGroup(provider, country!, stickers, isForMe);
      },
    );
  }

  Map<String, List<int>> _getExchanges(WorldCupProvider provider, {required bool isForMe}) {
    Map<String, List<int>> results = {};

    for (var group in provider.groups) {
      for (var country in group.countries) {
        if (_searchQuery.isNotEmpty && !country.name.toLowerCase().contains(_searchQuery)) continue;

        List<int> stickersInCountry = [];
        for (int i = 1; i <= country.totalStickers; i++) {
          final myCount = provider.getStickerCount(country.id, i);
          final hisCount = _friendStickers?[country.id]?[i] ?? 0;

          if (isForMe) {
            if (hisCount > 1 && myCount == 0) stickersInCountry.add(i);
          } else {
            if (myCount > 1 && hisCount == 0) stickersInCountry.add(i);
          }
        }

        if (stickersInCountry.isNotEmpty) results[country.id] = stickersInCountry;
      }
    }
    return results;
  }

  Widget _buildCountryGroup(WorldCupProvider provider, Country country, List<int> stickerNumbers, bool isForMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              if (country.flagCode.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(imageUrl: 'https://flagcdn.com/w80/${country.flagCode}.png', width: 30, memCacheWidth: 60),
                )
              else
                const Icon(Icons.star, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 10),
              Text(country.name, style: GoogleFonts.outfit(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: stickerNumbers.length,
          itemBuilder: (context, index) {
            final num = stickerNumbers[index];
            final key = '${country.id}_$num';
            final isSelected = isForMe ? _wantedStickers.contains(key) : _offeredStickers.contains(key);
            final weight = provider.getStickerWeight(country.id, num);

            return GestureDetector(
              onTap: () {
                setState(() {
                  final set = isForMe ? _wantedStickers : _offeredStickers;
                  if (isSelected) set.remove(key); else set.add(key);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF1E293B).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? Colors.white : Colors.white10),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text('#$num', style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (weight > 1)
                      Positioned(
                        top: 2, right: 2,
                        child: Icon(Icons.star, size: 10, color: isSelected ? Colors.black45 : const Color(0xFFD4AF37)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildReservationButton(WorldCupProvider provider, bool isBalanced, int wanted, int offered) {
    final hasSelection = _wantedStickers.isNotEmpty || _offeredStickers.isNotEmpty;
    
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isBalanced && hasSelection)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.8), borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    'Atención: Los pesos no son iguales',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSelection ? const Color(0xFFD4AF37) : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 10,
                ),
                onPressed: hasSelection ? () => _handleReservationRequest(provider) : null,
                child: Text(
                  'ENVIAR INTERCAMBIO (PESO: $wanted)',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleReservationRequest(WorldCupProvider provider) async {
    List<Map<String, dynamic>> wanted = _wantedStickers.map((s) {
      final parts = s.split('_');
      return {'countryId': parts[0], 'number': int.parse(parts[1])};
    }).toList();

    List<Map<String, dynamic>> offered = _offeredStickers.map((s) {
      final parts = s.split('_');
      return {'countryId': parts[0], 'number': int.parse(parts[1])};
    }).toList();

    try {
      await provider.sendReservationRequest(
        friendUid: widget.profile.uid,
        wantedStickers: wanted,
        offeredStickers: offered,
      );
      setState(() { _wantedStickers.clear(); _offeredStickers.clear(); });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intercambio enviado'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
  }
}
