import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app_state.dart';
import '../models.dart';
import 'friend_profile_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nickController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  bool _isCheckingNick = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WorldCupProvider>(context, listen: false);
      if (provider.userProfile?.nickname == null) {
        _showCreateNickDialog();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nickController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  void _showCreateNickDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Crea tu Nick Único', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Necesitas un Nick para buscar amigos e intercambiar figuritas.', 
                style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: _nickController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ej: Messi10',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  errorText: _isCheckingNick ? 'Verificando...' : null,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
              onPressed: () async {
                final nick = _nickController.text.trim();
                if (nick.length < 3) return;
                
                setDialogState(() => _isCheckingNick = true);
                final provider = Provider.of<WorldCupProvider>(context, listen: false);
                final available = await provider.isNicknameAvailable(nick);
                
                if (available) {
                  await provider.saveNickname(nick);
                  if (context.mounted) Navigator.pop(context);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Este Nick ya está en uso. Elige otro.'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
                setDialogState(() => _isCheckingNick = false);
              },
              child: const Text('CREAR NICK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('AMIGOS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black54,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          indicatorWeight: 3,
          isScrollable: false,
          labelPadding: EdgeInsets.zero,
          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          tabs: [
            const Tab(text: 'AMIGOS'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('SOLICITUDES'),
                  if (provider.pendingRequestsCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('RESERVAS'),
                  if (provider.incomingReservationsCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
            const Tab(text: 'ENTREGAS'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(provider.currentBgPath, fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.black.withOpacity(0.5), Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsTab(provider),
              _buildRequestsTab(provider),
              _buildReservationsTab(provider),
              _buildHistoryTab(provider),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        onPressed: () => _showAddFriendOptions(provider),
        child: const Icon(Icons.person_add, color: Colors.black),
      ),
    );
  }

  Widget _buildFriendsTab(WorldCupProvider provider) {
    return StreamBuilder<QuerySnapshot>(
      stream: provider.getFriends(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tienes amigos aún', style: TextStyle(color: Colors.white54)));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120, top: 10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final friendDoc = snapshot.data!.docs[index];
            final friendUid = friendDoc.id;
            final alias = (friendDoc.data() as Map<String, dynamic>).containsKey('alias') ? friendDoc['alias'] as String : null;

            return FutureBuilder<UserProfile?>(
              future: provider.getProfileByUid(friendUid),
              builder: (context, profileSnapshot) {
                if (!profileSnapshot.hasData) return const SizedBox.shrink();
                final profile = profileSnapshot.data!;
                return _buildGlassCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFD4AF37).withOpacity(0.2),
                      backgroundImage: profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
                      child: profile.photoUrl == null ? const Icon(Icons.person, color: Color(0xFFD4AF37)) : null,
                    ),
                    title: Text(alias ?? profile.nickname ?? 'Sin Nick', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(alias != null ? '@${profile.nickname}' : profile.displayName ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAliasButton(provider, friendUid, alias ?? ''),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.white24),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FriendProfileScreen(profile: profile)));
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAliasButton(WorldCupProvider provider, String friendUid, String currentAlias) {
    return InkWell(
      onTap: () => _showAliasDialog(provider, friendUid, currentAlias),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFD4AF37).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.edit, color: Color(0xFFD4AF37), size: 18),
      ),
    );
  }

  void _showAliasDialog(WorldCupProvider provider, String friendUid, String currentAlias) {
    _aliasController.text = currentAlias;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Asignar Apodo', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: _aliasController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ej: Juan del Trabajo',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              await provider.setFriendAlias(friendUid, _aliasController.text.trim());
              if (mounted) Navigator.pop(context);
            },
            child: const Text('GUARDAR', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(WorldCupProvider provider) {
    return StreamBuilder<QuerySnapshot>(
      stream: provider.getFriendRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay solicitudes pendientes', style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120, top: 10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildGlassCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  child: const Icon(Icons.person_add, color: Colors.blueAccent),
                ),
                title: Text(doc['fromNick'], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('Quiere ser tu amigo', style: TextStyle(color: Colors.white54)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                        onPressed: () => provider.respondToRequest(doc.id, 'accepted'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                        onPressed: () => provider.respondToRequest(doc.id, 'rejected'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReservationsTab(WorldCupProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _sectionHeader('TU TURNO', Icons.pending_actions, Colors.orangeAccent),
          StreamBuilder<QuerySnapshot>(
            stream: provider.getIncomingReservations(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              if (snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('No tienes acciones pendientes', style: TextStyle(color: Colors.white24, fontSize: 12)));
              return _buildResList(snapshot.data!.docs, provider, isMyTurn: true);
            },
          ),
          _sectionHeader('ENVIADOS', Icons.send, Colors.blueAccent),
          StreamBuilder<QuerySnapshot>(
            stream: provider.getSentReservations(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              if (snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('No hay propuestas enviadas', style: TextStyle(color: Colors.white24, fontSize: 12)));
              return _buildResList(snapshot.data!.docs, provider, isMyTurn: false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(WorldCupProvider provider) {
    return StreamBuilder<QuerySnapshot>(
      stream: provider.getHistoryReservations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay entregas pendientes', style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120, top: 10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final completedAt = (doc['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final weekAgo = DateTime.now().subtract(const Duration(days: 7));
            
            if (completedAt.isBefore(weekAgo)) return const SizedBox.shrink();

            final expiresAt = completedAt.add(const Duration(days: 7));
            final diff = expiresAt.difference(DateTime.now());
            final daysLeft = diff.inDays;
            
            final otherUid = (provider.currentUser!.uid == doc['from']) ? doc['to'] : doc['from'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(provider.currentUser!.uid).collection('friends').doc(otherUid).get(),
              builder: (context, friendDocSnapshot) {
                String displayName = doc['fromNick'];
                String? originalNick;
                
                if (friendDocSnapshot.hasData && friendDocSnapshot.data!.exists) {
                  final fData = friendDocSnapshot.data!.data() as Map<String, dynamic>;
                  if (fData.containsKey('alias')) {
                    displayName = fData['alias'];
                    originalNick = doc['fromNick'];
                  }
                }

                return _buildGlassCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: daysLeft < 2 ? Colors.redAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2),
                      child: Icon(Icons.access_time, color: daysLeft < 2 ? Colors.redAccent : Colors.orangeAccent),
                    ),
                    title: Text('Entrega con $displayName', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (originalNick != null) Text('@$originalNick', style: const TextStyle(color: Colors.white24, fontSize: 11)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.timer, size: 14, color: daysLeft < 2 ? Colors.redAccent : Colors.orangeAccent),
                            const SizedBox(width: 4),
                            Text('Vence en $daysLeft días', style: TextStyle(color: daysLeft < 2 ? Colors.redAccent : Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('No olvides entregar físicamente.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () => provider.markAsDelivered(doc.id),
                      child: const Text('ENTREGADO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? margin, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(0),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildResList(List<DocumentSnapshot> docs, WorldCupProvider provider, {required bool isMyTurn}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final wanted = doc['wanted'] as List;
        final offered = doc['offered'] as List;
        final fromNick = doc['fromNick'];
        final otherUid = (provider.currentUser!.uid == doc['from']) ? doc['to'] : doc['from'];
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(provider.currentUser!.uid).collection('friends').doc(otherUid).get(),
          builder: (context, friendDocSnapshot) {
            String displayName = fromNick;
            String? subNick;
            
            if (friendDocSnapshot.hasData && friendDocSnapshot.data!.exists) {
              final fData = friendDocSnapshot.data!.data() as Map<String, dynamic>;
              if (fData.containsKey('alias')) {
                displayName = fData['alias'];
                subNick = fromNick;
              }
            }

            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) => Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              ),
              child: _buildGlassCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text('Intercambio con $displayName', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(subNick != null ? '@$subNick | ${wanted.length}↔${offered.length}' : '${wanted.length} figuritas ↔ ${offered.length} figuritas', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: isMyTurn 
                      ? const Icon(Icons.arrow_forward_ios, color: Colors.orangeAccent, size: 14)
                      : const Text('Pendiente', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                  onTap: isMyTurn ? () => _showReservationReviewDialog(context, provider, doc, wanted, offered) : null,
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showReservationReviewDialog(BuildContext context, WorldCupProvider provider, DocumentSnapshot resDoc, List originalWanted, List originalOffered) {
    List selectedWanted = List.from(originalWanted);
    List selectedOffered = List.from(originalOffered);
    final resId = resDoc.id;
    final otherUid = (provider.currentUser!.uid == resDoc['from']) ? resDoc['to'] : resDoc['from'];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setState) {
            int weightW = 0;
            for (var s in selectedWanted) weightW += provider.getStickerWeight(s['countryId'], s['number']);
            int weightO = 0;
            for (var s in selectedOffered) weightO += provider.getStickerWeight(s['countryId'], s['number']);
            bool isBalanced = weightW == weightO && weightW > 0;
            
            // Comprobar si hay cambios respecto al original
            bool wasModified = selectedWanted.length != originalWanted.length || selectedOffered.length != originalOffered.length;
            if (!wasModified) {
              // También chequear contenido por si acaso
              for (var s in selectedWanted) {
                if (!originalWanted.any((ow) => ow['countryId'] == s['countryId'] && ow['number'] == s['number'])) wasModified = true;
              }
              for (var s in selectedOffered) {
                if (!originalOffered.any((oo) => oo['countryId'] == s['countryId'] && oo['number'] == s['number'])) wasModified = true;
              }
            }

            return Scaffold(
              backgroundColor: Colors.black.withOpacity(0.9),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: Text('REVISAR INTERCAMBIO', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                centerTitle: true,
                leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _reviewSectionWithAdd(
                            context, provider, 'LO QUE DAS', selectedWanted, Colors.orangeAccent, true,
                            (s, val) {
                              setState(() {
                                if (val!) selectedWanted.add(s);
                                else selectedWanted.removeWhere((sw) => sw['countryId'] == s['countryId'] && sw['number'] == s['number']);
                              });
                            },
                            () => _showStickerPicker(context, provider, provider.currentUser!.uid, (s) {
                              if (!selectedWanted.any((sw) => sw['countryId'] == s['countryId'] && sw['number'] == s['number'])) {
                                setState(() => selectedWanted.add(s));
                              }
                            })
                          ),
                          const SizedBox(height: 30),
                          _reviewSectionWithAdd(
                            context, provider, 'LO QUE RECIBES', selectedOffered, Colors.blueAccent, false,
                            (s, val) {
                              setState(() {
                                if (val!) selectedOffered.add(s);
                                else selectedOffered.removeWhere((so) => so['countryId'] == s['countryId'] && so['number'] == s['number']);
                              });
                            },
                            () => _showStickerPicker(context, provider, otherUid, (s) {
                              if (!selectedOffered.any((so) => so['countryId'] == s['countryId'] && so['number'] == s['number'])) {
                                setState(() => selectedOffered.add(s));
                              }
                            })
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildReviewFooter(provider, resId, isBalanced, wasModified, selectedWanted, selectedOffered, weightW, weightO),
                ],
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutQuart)), child: child);
      },
    );
  }

  Widget _reviewSectionWithAdd(BuildContext context, WorldCupProvider provider, String title, List selected, Color color, bool isMine, Function(dynamic, bool?) onToggle, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
            TextButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add_circle_outline, color: color, size: 16),
              label: Text('Añadir', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (selected.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('Ninguna seleccionada', style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic)),
          ),
        ...selected.map((s) {
          final country = provider.getCountryById(s['countryId']);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
            child: CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              activeColor: color,
              checkColor: Colors.black,
              title: Row(
                children: [
                  if (country?.flagCode != null && country!.flagCode.isNotEmpty)
                    ClipRRect(borderRadius: BorderRadius.circular(2), child: CachedNetworkImage(imageUrl: 'https://flagcdn.com/w40/${country.flagCode}.png', width: 25, memCacheWidth: 50))
                  else
                    const Icon(Icons.star, color: Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 12),
                  Text('#${s['number']} - ${country?.name ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              subtitle: Text('Peso: ${provider.getStickerWeight(s['countryId'], s['number'])}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              value: true,
              onChanged: (val) => onToggle(s, val),
            ),
          );
        }),
      ],
    );
  }

  void _showStickerPicker(BuildContext context, WorldCupProvider provider, String targetUid, Function(Map<String, dynamic>) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('SELECCIONAR FIGURITA', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<Map<String, Map<int, int>>>(
                future: targetUid == provider.currentUser!.uid 
                  ? Future.value(provider.stickerCountsForRepetitions) 
                  : provider.getFriendStickers(targetUid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final repeats = snapshot.data!;
                  
                  // Solo países con repetidas
                  final countriesWithRepeats = provider.groups.expand((g) => g.countries).where((c) {
                    return repeats[c.id]?.values.any((count) => count > 1 || (targetUid != provider.currentUser!.uid && count > 0)) ?? false;
                  }).toList();

                  if (countriesWithRepeats.isEmpty) return const Center(child: Text('No hay figuritas disponibles para añadir', style: TextStyle(color: Colors.white24)));

                  return ListView.builder(
                    itemCount: countriesWithRepeats.length,
                    itemBuilder: (context, idx) {
                      final country = countriesWithRepeats[idx];
                      final stickers = repeats[country.id] ?? {};
                      
                      return ExpansionTile(
                        title: Text(country.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        children: stickers.entries.where((e) => targetUid == provider.currentUser!.uid ? e.value > 1 : e.value > 0).map((e) {
                          return ListTile(
                            title: Text('#${e.key}', style: const TextStyle(color: Colors.white70)),
                            trailing: Text('Repes: ${targetUid == provider.currentUser!.uid ? e.value - 1 : e.value}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                            onTap: () {
                              onSelected({'countryId': country.id, 'number': e.key});
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewFooter(WorldCupProvider provider, String resId, bool isBalanced, bool wasModified, List wanted, List offered, int weightW, int weightO) {
    bool hasSelection = wanted.isNotEmpty || offered.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _weightIndicator('DAS: $weightW', Colors.orangeAccent),
              if (!isBalanced && hasSelection) const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              _weightIndicator('RECIBES: $weightO', Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () { provider.respondToReservation(resId, 'rejected'); Navigator.pop(context); },
                  child: const Text('RECHAZAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSelection ? (wasModified ? Colors.blueAccent : const Color(0xFFD4AF37)) : Colors.grey,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: hasSelection ? () async {
                    await provider.respondToReservation(resId, wasModified ? 'modified' : 'accepted', finalWanted: wanted, finalOffered: offered);
                    if (mounted) Navigator.pop(context);
                  } : null,
                  child: Text(wasModified ? 'CONTRAOFERTA' : 'ACEPTAR TODO', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weightIndicator(String label, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Container(height: 2, width: 40, color: color.withOpacity(0.3), margin: const EdgeInsets.only(top: 4)),
      ],
    );
  }

  void _showSearchDialog(WorldCupProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Buscar Amigo', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ingresa el Nick exacto',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              final targetNick = _searchController.text.trim();
              if (targetNick.isEmpty) return;
              
              try {
                await provider.sendFriendRequest(targetNick);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Solicitud enviada correctamente'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('ENVIAR', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
  void _showAddFriendOptions(WorldCupProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                title: const Text('Buscar por Nick', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showSearchDialog(provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code, color: Color(0xFFD4AF37)),
                title: const Text('Mostrar mi QR', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showMyQR(provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: Color(0xFFD4AF37)),
                title: const Text('Escanear QR', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _scanQR(provider);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showMyQR(WorldCupProvider provider) {
    final nick = provider.userProfile?.nickname ?? '';
    if (nick.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Mi Código QR', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: nick,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('CERRAR', style: TextStyle(color: Color(0xFFD4AF37)))
          ),
        ],
      ),
    );
  }

  void _scanQR(WorldCupProvider provider) {
    bool hasScanned = false;
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      appBar: AppBar(title: const Text('Escanear QR')),
      body: MobileScanner(
        onDetect: (capture) {
          if (hasScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String code = barcodes.first.rawValue ?? '';
            if (code.isNotEmpty) {
              hasScanned = true;
              Navigator.pop(context);
              _addFriendByNick(provider, code);
            }
          }
        },
      ),
    )));
  }

  void _addFriendByNick(WorldCupProvider provider, String targetNick) async {
    try {
      await provider.sendFriendRequest(targetNick);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Solicitud enviada a $targetNick'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
