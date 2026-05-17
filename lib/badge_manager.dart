import 'package:flutter/material.dart' hide Badge;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';
import 'models.dart';
import 'data.dart';

class BadgeManager {
  static final BadgeManager _instance = BadgeManager._internal();
  factory BadgeManager() => _instance;
  BadgeManager._internal();

  final List<String> _celebratedBadges = [];
  final List<Badge> _badgeQueue = [];
  bool _isShowingBadge = false;

  Future<void> init(List<String> loadedCelebrated) async {
    _celebratedBadges.clear();
    _celebratedBadges.addAll(loadedCelebrated);
  }

  void checkNewBadges(WorldCupProvider provider) {
    for (var badge in WorldCupData.badges) {
      if (isBadgeUnlocked(badge.id, provider) && !_celebratedBadges.contains(badge.id)) {
        _celebratedBadges.add(badge.id);
        _badgeQueue.add(badge);
        _saveCelebratedBadges();
      }
    }
    _processBadgeQueue();
  }

  bool isBadgeUnlocked(String badgeId, WorldCupProvider provider) {
    if (badgeId == 'first') return provider.totalObtainedCount > 0;
    if (badgeId == 'auth') return provider.currentUser != null;
    if (badgeId == 'friends') return provider.friendCount > 0;
    if (badgeId == 'friends_2') return provider.friendCount >= 2;
    if (badgeId == 'group_a') return provider.getGroupProgress('A') == 1.0;
    if (badgeId == 'mexico') return provider.getCountryProgress('mx') == 1.0;
    if (badgeId == 'half') return provider.getTotalProgress() >= 0.5;
    if (badgeId == 'argentina') return provider.getCountryProgress('ar') == 1.0;
    if (badgeId == 'brazil') return provider.getCountryProgress('br') == 1.0;
    if (badgeId == 'special') return provider.getGroupProgress('★') == 1.0;
    if (badgeId == 'coca_cola') return provider.getGroupProgress('CC') == 1.0;
    if (badgeId == 'repeated_master') return provider.repeatedCount >= 50;
    if (badgeId == 'full') return provider.getTotalProgress() == 1.0;
    if (badgeId == 'collector') {
      for (var b in WorldCupData.badges) {
        if (b.id != 'collector' && !isBadgeUnlocked(b.id, provider)) return false;
      }
      return true;
    }
    return false;
  }

  void _processBadgeQueue() {
    if (_isShowingBadge || _badgeQueue.isEmpty) return;
    
    final context = WorldCupProvider.navigatorKey.currentContext;
    if (context == null) return;

    _isShowingBadge = true;
    final badge = _badgeQueue.removeAt(0);
    
    _showBadgeSpectacle(context, badge);
  }

  void _showBadgeSpectacle(BuildContext context, Badge badge) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Text(badge.icon, style: const TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 20),
            const Text('¡INSIGNIA DESBLOQUEADA!', 
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 10),
            Text(badge.title, 
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(badge.description, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _isShowingBadge = false;
                Future.delayed(const Duration(milliseconds: 500), () {
                  _processBadgeQueue();
                });
              },
              child: const Text('¡GENIAL!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCelebratedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('celebratedBadges', _celebratedBadges);
  }
}
