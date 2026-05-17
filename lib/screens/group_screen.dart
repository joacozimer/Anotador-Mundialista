import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../app_state.dart';
import 'country_screen.dart';
import '../widgets/country_view.dart';

class GroupScreen extends StatefulWidget {
  final int initialIndex;

  const GroupScreen({super.key, required this.initialIndex});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late PageController _pageController;
  late int _currentIndex;
  static const int _virtualItemCount = 10000;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Iniciamos en un múltiplo del total de grupos cerca del centro para permitir scroll infinito hacia ambos lados
    _pageController = PageController(initialPage: _calculateInitialPage());
  }

  int _calculateInitialPage() {
    final totalGroups = Provider.of<WorldCupProvider>(context, listen: false).groups.length;
    final middle = _virtualItemCount ~/ 2;
    return middle - (middle % totalGroups) + _currentIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context);
    final groups = provider.groups;
    final totalGroups = groups.length;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(groups[_currentIndex % totalGroups].name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _virtualItemCount,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          provider.recordTap();
        },
        itemBuilder: (context, index) {
          final groupIndex = index % totalGroups;
          final group = groups[groupIndex];
          
          return _GroupView(group: group);
        },
      ),
    );
  }
}

class _GroupView extends StatelessWidget {
  final WorldCupGroup group;

  const _GroupView({required this.group});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context);

    if (group.countries.length == 1) {
      return Stack(
        children: [
          Positioned.fill(child: Image.asset(provider.currentBgPath, fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7))),
          CountryView(country: group.countries.first, showHeader: true),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => provider.recordTap(),
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(provider.currentBgPath, fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7))),
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 110, 16, 100),
            itemCount: group.countries.length,
            itemBuilder: (context, index) {
              final country = group.countries[index];
              final progress = provider.getCountryProgress(country.id);
              final isComplete = progress == 1.0;
              final repeatedCount = _getRepeatedCount(provider, country);

              return Card(
                color: const Color(0xFF1E293B).withOpacity(0.8),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: country.flagCode.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            'https://flagcdn.com/w160/${country.flagCode}.png',
                            width: 60, height: 40, fit: BoxFit.cover,
                          ),
                        )
                      : (group.id == 'CC' 
                          ? Image.asset('assets/coca.png', width: 60, height: 40)
                          : const Icon(Icons.star, color: Color(0xFFD4AF37), size: 40)),
                  title: Text(country.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Llevas ${provider.getObtainedCount(country.id)}/${country.totalStickers}',
                            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                          ),
                          if (repeatedCount > 0)
                            Text(
                              'Repetidas: $repeatedCount',
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                        color: isComplete ? Colors.greenAccent : const Color(0xFFD4AF37),
                      ),
                    ],
                  ),
                  onTap: () {
                    provider.recordTap();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CountryScreen(country: country)));
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int _getRepeatedCount(WorldCupProvider provider, Country country) {
    int total = 0;
    for (int i = 1; i <= country.totalStickers; i++) {
      final count = provider.getStickerCount(country.id, i);
      if (count > 1) {
        total += (count - 1);
      }
    }
    return total;
  }
}
