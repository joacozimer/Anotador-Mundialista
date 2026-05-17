import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models.dart';
import '../app_state.dart';

class CountryView extends StatefulWidget {
  final Country country;
  final bool showHeader;

  const CountryView({super.key, required this.country, this.showHeader = true});

  @override
  State<CountryView> createState() => _CountryViewState();
}

class _CountryViewState extends State<CountryView> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context, listen: false);
    final total = widget.country.totalStickers;

    return Stack(
      children: [
        Column(
          children: [
            if (widget.showHeader) ...[
              const SizedBox(height: 110),
              Selector<WorldCupProvider, int>(
                selector: (_, p) => p.getObtainedCount(widget.country.id),
                builder: (context, obtained, child) => _buildCountryHeader(obtained, total, provider),
              ),
            ],
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: widget.country.totalStickers,
                itemBuilder: (context, index) {
                  final stickerNum = widget.country.id == 'fwc' ? index : index + 1;
                  return _buildStickerTile(context, stickerNum, provider);
                },
              ),
            ),
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
            gravity: 0.1,
            emissionFrequency: 0.05,
          ),
        ),
      ],
    );
  }

  Widget _buildCountryHeader(int obtained, int total, WorldCupProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (widget.country.isCocaCola)
            Image.asset('assets/coca.png', width: 60, height: 40)
          else if (widget.country.flagCode.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: 'https://flagcdn.com/w160/${widget.country.flagCode}.png',
                width: 60, height: 40, fit: BoxFit.cover,
              ),
            )
          else
            const Icon(Icons.star, color: Color(0xFFD4AF37), size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progreso del país', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text('$obtained de $total completadas', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : obtained / total,
                  backgroundColor: Colors.white10,
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerTile(BuildContext context, int stickerNum, WorldCupProvider provider) {
    return Selector<WorldCupProvider, int>(
      selector: (_, p) => p.getStickerCount(widget.country.id, stickerNum),
      builder: (context, count, child) {
        final isObtained = count > 0;

        return GestureDetector(
          onTap: () {
            final wasComplete = provider.getCountryProgress(widget.country.id) == 1.0;
            provider.addSticker(widget.country.id, stickerNum);
            provider.checkNewBadges();
            if (!wasComplete && provider.getCountryProgress(widget.country.id) == 1.0) {
              _confettiController.play();
              provider.triggerCelebration();
            }
          },
          onLongPress: () {
            if (count > 1) {
              _showRemoveRepeatedDialog(context, stickerNum, count, provider);
            } else if (count == 1) {
              provider.removeSticker(widget.country.id, stickerNum);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isObtained ? const Color(0xFFD4AF37) : const Color(0xFF1E293B).withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isObtained ? Colors.white : Colors.white10, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '#$stickerNum',
                  style: TextStyle(
                    color: isObtained ? Colors.black : Colors.white24,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (count > 1)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: Text(
                        'x${count - 1}', 
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemoveRepeatedDialog(BuildContext context, int stickerNum, int currentCount, WorldCupProvider provider) {
    int toRemove = 1;
    final maxToRemove = currentCount - 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Quitar repetidas (#$stickerNum)', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tienes $maxToRemove repetidas. ¿Cuántas quieres quitar?', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    onPressed: toRemove > 1 ? () => setDialogState(() => toRemove--) : null,
                  ),
                  Text('$toRemove', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                    onPressed: toRemove < maxToRemove ? () => setDialogState(() => toRemove++) : null,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                for (int i = 0; i < toRemove; i++) {
                  provider.removeSticker(widget.country.id, stickerNum);
                }
                Navigator.pop(context);
              },
              child: const Text('QUITAR'),
            ),
          ],
        ),
      ),
    );
  }
}
