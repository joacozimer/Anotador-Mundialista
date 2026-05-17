import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../app_state.dart';
import '../badge_manager.dart';
import '../models.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context);
    final badges = provider.badges;

    // Agrupar insignias por categoría
    final groupedBadges = <String, List<Badge>>{
      'Bronce': badges.where((b) => b.category == 'Bronce').toList(),
      'Plata': badges.where((b) => b.category == 'Plata').toList(),
      'Oro': badges.where((b) => b.category == 'Oro').toList(),
      'Diamante': badges.where((b) => b.category == 'Diamante').toList(),
    };

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('MIS INSIGNIAS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(provider.currentBgPath, fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.85))),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ...groupedBadges.entries.map((entry) {
                if (entry.value.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: _buildCategoryHeader(entry.key),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final badge = entry.value[index];
                            final isUnlocked = BadgeManager().isBadgeUnlocked(badge.id, provider);
                            return FlipBadgeCard(badge: badge, isUnlocked: isUnlocked);
                          },
                          childCount: entry.value.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                );
              }),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String category) {
    Color color;
    switch (category) {
      case 'Bronce': color = Colors.brown[300]!; break;
      case 'Plata': color = Colors.grey[400]!; break;
      case 'Oro': color = const Color(0xFFD4AF37); break;
      case 'Diamante': color = Colors.cyanAccent; break;
      default: color = Colors.white;
    }

    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          category.toUpperCase(),
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class FlipBadgeCard extends StatefulWidget {
  final Badge badge;
  final bool isUnlocked;

  const FlipBadgeCard({super.key, required this.badge, required this.isUnlocked});

  @override
  State<FlipBadgeCard> createState() => _FlipBadgeCardState();
}

class _FlipBadgeCardState extends State<FlipBadgeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_controller.isAnimating) return;
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: angle < pi / 2
                ? _buildFront()
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isUnlocked ? const Color(0xFF1E293B) : Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isUnlocked ? const Color(0xFFD4AF37) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: widget.isUnlocked ? [
          BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
        ] : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'badge_icon_${widget.badge.id}',
            child: Text(
              widget.badge.icon,
              style: TextStyle(
                fontSize: 44,
                color: widget.isUnlocked ? null : Colors.white10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.badge.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.isUnlocked ? Colors.white : Colors.white30,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          if (!widget.isUnlocked)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Icon(Icons.lock_outline, size: 16, color: Colors.white.withOpacity(0.1)),
            ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.help_outline, color: Colors.black, size: 24),
          const SizedBox(height: 8),
          Text(
            '¿CÓMO OBTENERLA?',
            style: GoogleFonts.outfit(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.badge.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
