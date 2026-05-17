import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart' hide Badge;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'models.dart';
import 'ad_helper.dart';
import 'data.dart';
import 'badge_manager.dart';
import 'config.dart';
import 'update_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WorldCupProvider with ChangeNotifier {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static const String _storageKey = 'world_cup_stickers_v2';
  
  Map<String, Map<int, int>> _stickerCounts = {};
  bool _initialized = false;
  bool _skipIntro = false;
  User? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String _bgMode = 'Aleatorio'; // Messi, Maradona, Kempes, Aleatorio
  int _tapCount = 0;
  DateTime _lastAdTime = DateTime.now();
  bool _shouldCelebrate = false;
  int _pendingRequestsCount = 0;
  StreamSubscription? _requestsSubscription;
  String? _fcmToken;
  int _friendCount = 0;
  Timer? _cloudSaveTimer;
  final Map<String, Map<String, Map<int, int>>> _friendStickersCache = {};
  final Map<String, DateTime> _friendStickersCacheTime = {};
  final Map<String, UserProfile> _userProfileCache = {};
  String? _lastUploadedDataJson;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool get shouldCelebrate => _shouldCelebrate;
  int get pendingRequestsCount => _pendingRequestsCount;
  int get friendCount => _friendCount;
  
  // Badge global para el menú y botón social
  int _incomingReservationsCount = 0;
  int get incomingReservationsCount => _incomingReservationsCount;
  bool get hasSocialPending => _pendingRequestsCount > 0 || _incomingReservationsCount > 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn(
    serverClientId: '840953604839-hg7ttd07imump2toe88erh9efcvlbpgq.apps.googleusercontent.com',
  );

  bool get initialized => _initialized;
  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String get bgMode => _bgMode;
  bool get skipIntro => _skipIntro;

  String get currentBgPath {
    if (_bgMode == 'Messi') return 'assets/messi.png';
    if (_bgMode == 'Maradona') return 'assets/maradona.png';
    if (_bgMode == 'Kempes') return 'assets/kempes.png';
    // Aleatorio: Cambia cada minuto
    final now = DateTime.now();
    final list = ['assets/messi.png', 'assets/maradona.png', 'assets/kempes.png'];
    return list[(now.hour * 60 + now.minute) % 3];
  }

  static String removeAccents(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  void setBgMode(String mode) {
    _bgMode = mode;
    _saveBgMode();
    notifyListeners();
  }

  void setSkipIntro(bool value) {
    _skipIntro = value;
    _saveSkipIntro();
    notifyListeners();
  }

  void preCacheFlags() async {
    final context = WorldCupProvider.navigatorKey.currentContext;
    if (context == null) return;
    
    for (var group in WorldCupData.groups) {
      for (var country in group.countries) {
        if (country.flagCode.isNotEmpty) {
          final url = 'https://flagcdn.com/w160/${country.flagCode}.png';
          precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    }
    // También banderas extras que no están en grupos pero sí en fixture
    final extraFlags = ['ng']; // Nigeria
    for (var code in extraFlags) {
      final url = 'https://flagcdn.com/w160/$code.png';
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.any((result) => result != ConnectivityResult.none);
  }

  void recordTap() {
    _tapCount++;
    final now = DateTime.now();
    final diffMinutes = now.difference(_lastAdTime).inMinutes;

    // Show interstitial ad either after 50 taps or after 5 minutes of inactivity.
    // When the ad is shown, reset the tap counter and update the last ad timestamp.
    if (_tapCount >= 50 || diffMinutes >= 5) {
      AdHelper.showInterstitialAd();
      _tapCount = 0;
      _lastAdTime = now;
      notifyListeners();
    }
  }

  void triggerCelebration() {
    _shouldCelebrate = true;
    notifyListeners();
  }

  void resetCelebration() {
    _shouldCelebrate = false;
  }

  bool shouldShowInterstitial() {
    // Retorna true si se cumplieron las condiciones pero resetea el flag
    return false; // Implementado via notifyListeners y chequeo en UI
  }

  Future<void> initialize() async {
    // Buscar actualizaciones en Google Play
    UpdateHelper.checkForUpdate();
    
    await _loadFromPrefs();
    await _loadBgMode();
    await _loadSkipIntro();

    // Descargar/Cachear banderas localmente
    preCacheFlags();

    // Penalización: Si cerró la app durante un anuncio, mostrar uno al iniciar
    if (await AdHelper.wasAdInProcess()) {
      debugPrint('Penalización: Mostrando anuncio por cierre previo indebido.');
      AdHelper.showInterstitialAd();
    }

    _auth.authStateChanges().listen((User? user) async {
      _currentUser = user;
      _requestsSubscription?.cancel();
      
      if (user != null) {
        await _fetchUserProfile(user.uid);
        await downloadProgress();
        _startListeningToRequests(user.uid);
        _startListeningToFriends(user.uid);
        _setupNotifications();
      } else {
        _userProfile = null;
        _pendingRequestsCount = 0;
        _friendCount = 0;
      }
      _initialized = true;
      notifyListeners();
    });
  }

  StreamSubscription? _friendsSubscription;
  void _startListeningToFriends(String uid) {
    _friendsSubscription?.cancel();
    _friendsSubscription = _db.collection('users').doc(uid).collection('friends').snapshots().listen((snapshot) {
      _friendCount = snapshot.docs.length;
      notifyListeners();
    });
  }

  Future<void> _setupNotifications() async {
    if (_currentUser == null) return;
    
    try {
      // Configuración de Local Notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotifications.initialize(const InitializationSettings(android: androidInit));

      // Pedir permisos y obtener token con Timeout para evitar bloqueos
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission().timeout(const Duration(seconds: 5));
      _fcmToken = await messaging.getToken().timeout(const Duration(seconds: 5));
      
      if (_fcmToken != null) {
        await _db.collection('users').doc(_currentUser!.uid).update({'fcmToken': _fcmToken});
      }

      // Escuchar mensajes en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message.notification?.title ?? 'Notificación', message.notification?.body ?? '');
      });

      // Escuchar cambios en notificaciones de Firestore (para usuarios sin FCM activo)
      _db.collection('notifications')
        .where('to', isEqualTo: _currentUser!.uid)
        .where('timestamp', isGreaterThan: Timestamp.now())
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              _showLocalNotification(data['title'], data['body']);
            }
          }
        });
    } catch (e) {
      print('Error al configurar notificaciones: $e');
    }
  }

  void _showLocalNotification(String title, String body) {
    const androidDetails = AndroidNotificationDetails(
      'social_channel', 
      'Social', 
      importance: Importance.max, 
      priority: Priority.high,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    _localNotifications.show(0, title, body, const NotificationDetails(android: androidDetails));
  }

  void _startListeningToRequests(String uid) {
    _requestsSubscription?.cancel();
    _requestsSubscription = _db.collection('friend_requests')
      .where('to', isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .listen((snapshot) {
        _pendingRequestsCount = snapshot.docs.length;
        notifyListeners();
      });

    // También escuchamos reservas para el badge global
    _db.collection('reservations')
      .where('turnOf', isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .listen((snapshot) {
        _incomingReservationsCount = snapshot.docs.length;
        notifyListeners();
      });
  }

  // --- STICKER LOGIC ---
  Map<String, Map<int, int>> get stickerCountsForRepetitions => _stickerCounts;
  int getStickerCount(String countryId, int stickerNumber) => _stickerCounts[countryId]?[stickerNumber] ?? 0;
  bool isObtained(String countryId, int stickerNumber) => getStickerCount(countryId, stickerNumber) > 0;

  void addSticker(String countryId, int stickerNumber) {
    if (!_stickerCounts.containsKey(countryId)) _stickerCounts[countryId] = {};
    _stickerCounts[countryId]![stickerNumber] = (_stickerCounts[countryId]![stickerNumber] ?? 0) + 1;
    _saveToPrefs();
    notifyListeners();
  }

  void removeSticker(String countryId, int stickerNumber) {
    if (_stickerCounts.containsKey(countryId) && (_stickerCounts[countryId]![stickerNumber] ?? 0) > 0) {
      _stickerCounts[countryId]![stickerNumber] = _stickerCounts[countryId]![stickerNumber]! - 1;
      _saveToPrefs();
      notifyListeners();
    }
  }

  void resetAll() {
    _stickerCounts = {};
    _saveToPrefs();
    notifyListeners();
  }

  int getObtainedCount(String countryId) {
    if (!_stickerCounts.containsKey(countryId)) return 0;
    final country = getCountryById(countryId);
    if (country == null) return 0;
    int count = 0;
    int start = (country.id == 'fwc') ? 0 : 1;
    int end = (country.id == 'fwc') ? country.totalStickers - 1 : country.totalStickers;
    
    for (int i = start; i <= end; i++) {
      if (isObtained(countryId, i)) count++;
    }
    return count;
  }

  double getCountryProgress(String countryId) {
    final country = getCountryById(countryId);
    if (country == null) return 0;
    return getObtainedCount(countryId) / country.totalStickers;
  }

  double getGroupProgress(String groupId) {
    int obtained = 0;
    int total = 0;
    final group = groups.firstWhere((g) => g.id == groupId);
    for (var country in group.countries) {
      obtained += getObtainedCount(country.id);
      total += country.totalStickers;
    }
    return total == 0 ? 0 : obtained / total;
  }

  int get missingCount {
    int missing = 0;
    for (var group in groups) {
      for (var country in group.countries) {
        if (!country.isCocaCola) {
          int start = (country.id == 'fwc') ? 0 : 1;
          int end = (country.id == 'fwc') ? country.totalStickers - 1 : country.totalStickers;
          for (int i = start; i <= end; i++) {
            if (!isObtained(country.id, i)) missing++;
          }
        }
      }
    }
    return missing;
  }

  int get repeatedCount {
    int repeated = 0;
    for (var group in groups) {
      for (var country in group.countries) {
        for (int i = 1; i <= country.totalStickers; i++) {
          final count = getStickerCount(country.id, i);
          if (count > 1) repeated += (count - 1);
        }
      }
    }
    return repeated;
  }

  int get totalObtainedCount {
    int count = 0;
    for (var group in groups) {
      for (var country in group.countries) {
        if (!country.isCocaCola) {
          count += getObtainedCount(country.id);
        }
      }
    }
    return count;
  }

  double getTotalProgress() {
    int obtained = 0;
    int total = 0;
    for (var group in groups) {
      for (var country in group.countries) {
        if (!country.isCocaCola) {
          obtained += getObtainedCount(country.id);
          total += country.totalStickers;
        }
      }
    }
    return total == 0 ? 0 : obtained / total;
  }

  Country? getCountryById(String id) {
    for (var group in groups) {
      for (var country in group.countries) {
        if (country.id == id) return country;
      }
    }
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final Map<String, dynamic> decoded = json.decode(data);
      _stickerCounts = decoded.map((key, value) {
        final Map<int, int> counts = {};
        (value as Map<String, dynamic>).forEach((stickerNum, count) {
          counts[int.parse(stickerNum)] = count as int;
        });
        return MapEntry(key, counts);
      });
    }
    await BadgeManager().init(prefs.getStringList('celebratedBadges') ?? []);
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, Map<String, int>> dataToSave = _stickerCounts.map((key, value) {
      return MapEntry(key, value.map((stickerNum, count) => MapEntry(stickerNum.toString(), count)));
    });
    await prefs.setString(_storageKey, json.encode(dataToSave));
    
    // Optimización: Debounce para no saturar Firebase
    _cloudSaveTimer?.cancel();
    _cloudSaveTimer = Timer(const Duration(seconds: 3), () {
      if (_currentUser != null) uploadProgress();
    });
  }

  Future<void> _loadBgMode() async {
    final prefs = await SharedPreferences.getInstance();
    _bgMode = prefs.getString('bgMode') ?? 'Aleatorio';
  }

  Future<void> _saveBgMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bgMode', _bgMode);
  }

  Future<void> _loadSkipIntro() async {
    final prefs = await SharedPreferences.getInstance();
    _skipIntro = prefs.getBool('skipIntro') ?? false;
  }

  Future<void> _saveSkipIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skipIntro', _skipIntro);
  }

  // --- GOOGLE & PROFILE ---
  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromFirestore(doc.data()!, uid);
      }
    } catch (e) { print(e); }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final gsi.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final gsi.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) { 
      print('Error en Google Sign-In: $e'); 
      rethrow; 
    } finally { 
      _setLoading(false); 
    }
  }

  Future<void> sendSuggestion(String message) async {
    if (message.trim().isEmpty) return;

    // Control de Spam: Máximo 2 sugerencias cada 24 horas
    final prefs = await SharedPreferences.getInstance();
    List<String> timestamps = prefs.getStringList('suggestion_timestamps') ?? [];
    final now = DateTime.now();
    
    // Filtrar solo las de las últimas 24 horas
    timestamps = timestamps.where((ts) {
      final dt = DateTime.parse(ts);
      return now.difference(dt).inHours < 24;
    }).toList();

    if (timestamps.length >= 2) {
      throw 'Has alcanzado el límite de 2 sugerencias por día. ¡Gracias por tu interés!';
    }
    
    // 1. Guardar en Firestore (Backup)
    final suggestionData = {
      'uid': _currentUser?.uid,
      'userName': _currentUser?.displayName ?? 'Invitado',
      'userEmail': _currentUser?.email ?? 'No disponible',
      'content': message,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _db.collection('suggestions').add(suggestionData);
    } catch (e) {
      debugPrint('Error al guardar en Firestore: $e');
    }

    // 2. Enviar vía EmailJS (Automático)
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': AppConfig.emailjsServiceId,
          'template_id': AppConfig.emailjsTemplateId,
          'user_id': AppConfig.emailjsPublicKey,
          'accessToken': AppConfig.emailjsAccessToken,
          'template_params': {
            'name': _currentUser?.displayName ?? 'Usuario App',
            'email': _currentUser?.email ?? 'Sin correo',
            'title': 'Sugerencia de ${AppConfig.appName}',
            'message': message,
          },
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final error = response.body;
        debugPrint('Error de EmailJS (${response.statusCode}): $error');
        throw 'EmailJS dice: $error';
      }
      debugPrint('¡Éxito! Sugerencia enviada a EmailJS.');

      // Registrar el envío exitoso para el límite de spam
      timestamps.add(now.toIso8601String());
      await prefs.setStringList('suggestion_timestamps', timestamps);
    } on TimeoutException {
      throw 'La conexión tardó demasiado. Revisa tu internet.';
    } catch (e) {
      debugPrint('Error crítico en envío: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<void> uploadProgress() async {
    if (_currentUser == null) return;
    
    // Optimización: Solo guardar países que tienen al menos una figurita
    final Map<String, dynamic> compactData = {};
    _stickerCounts.forEach((countryId, stickers) {
      final countryData = stickers.map((num, count) => MapEntry(num.toString(), count))
                                ..removeWhere((num, count) => count == 0);
      if (countryData.isNotEmpty) {
        compactData[countryId] = countryData;
      }
    });
    
    final currentDataJson = json.encode(compactData);
    if (currentDataJson == _lastUploadedDataJson) return; // No hubo cambios reales
    _lastUploadedDataJson = currentDataJson;

    await _db.collection('users').doc(_currentUser!.uid).set({
      'stickerCounts': compactData,
      'lastSync': FieldValue.serverTimestamp(),
      'stats': {
        'totalObtained': totalObtainedCount,
        'totalRepeated': repeatedCount,
        'totalMissing': missingCount,
      }
    }, SetOptions(merge: true));
  }

  // --- SOCIAL LOGIC ---
  Future<bool> isNicknameAvailable(String nick) async {
    final snapshot = await _db.collection('users').where('nickname', isEqualTo: nick).get();
    return snapshot.docs.isEmpty;
  }

  Future<void> saveNickname(String nick) async {
    if (_currentUser == null) return;
    await _db.collection('users').doc(_currentUser!.uid).set({
      'nickname': nick,
      'searchName': nick.toLowerCase(),
    }, SetOptions(merge: true));
    await _fetchUserProfile(_currentUser!.uid);
    notifyListeners();
  }

  Future<void> sendFriendRequest(String targetNick) async {
    if (_currentUser == null || _userProfile?.nickname == null) return;
    
    final targetSnapshot = await _db.collection('users').where('nickname', isEqualTo: targetNick).get();
    if (targetSnapshot.docs.isEmpty) throw 'Usuario no encontrado';
    
    final targetUid = targetSnapshot.docs.first.id;
    if (targetUid == _currentUser!.uid) throw 'No puedes enviarte una solicitud a ti mismo';

    await _db.collection('friend_requests').add({
      'from': _currentUser!.uid,
      'fromNick': _userProfile!.nickname,
      'to': targetUid,
      'toNick': targetNick,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Notificar al amigo
    await _db.collection('notifications').add({
      'to': targetUid,
      'title': '¡Nueva solicitud de amistad!',
      'body': '${_userProfile?.nickname} quiere ser tu amigo.',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> respondToRequest(String requestId, String status) async {
    await _db.collection('friend_requests').doc(requestId).update({
      'status': status,
    });
    
    if (status == 'accepted') {
      final doc = await _db.collection('friend_requests').doc(requestId).get();
      final fromUid = doc.data()!['from'];
      final toUid = doc.data()!['to'];
      
      // Crear vínculos de amistad
      await _db.collection('users').doc(fromUid).collection('friends').doc(toUid).set({'uid': toUid});
      await _db.collection('users').doc(toUid).collection('friends').doc(fromUid).set({'uid': fromUid});

      // Notificar aceptación
      final otherUid = (_currentUser!.uid == fromUid) ? toUid : fromUid;
      await _db.collection('notifications').add({
        'to': otherUid,
        'title': '¡Solicitud aceptada!',
        'body': '${_userProfile?.nickname} ahora es tu amigo.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot> getFriendRequests() {
    return _db.collection('friend_requests')
      .where('to', isEqualTo: _currentUser?.uid)
      .where('status', isEqualTo: 'pending')
      .snapshots();
  }

  Stream<QuerySnapshot> getFriends() {
    return _db.collection('users').doc(_currentUser?.uid).collection('friends').snapshots();
  }

  Future<void> setFriendAlias(String friendUid, String alias) async {
    if (_currentUser == null) return;
    await _db.collection('users').doc(_currentUser!.uid).collection('friends').doc(friendUid).set({
      'alias': alias,
    }, SetOptions(merge: true));
    notifyListeners();
  }

  Future<UserProfile?> getProfileByUid(String uid) async {
    if (_userProfileCache.containsKey(uid)) return _userProfileCache[uid];
    
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      final profile = UserProfile.fromFirestore(doc.data()!, uid);
      _userProfileCache[uid] = profile;
      return profile;
    }
    return null;
  }

  Future<Map<String, Map<int, int>>> getFriendStickers(String friendUid) async {
    // Optimización: Cache con TTL (5 minutos) para evitar lecturas excesivas
    final now = DateTime.now();
    if (_friendStickersCache.containsKey(friendUid) && 
        _friendStickersCacheTime.containsKey(friendUid) &&
        now.difference(_friendStickersCacheTime[friendUid]!).inMinutes < 5) {
      return _friendStickersCache[friendUid]!;
    }

    final doc = await _db.collection('users').doc(friendUid).get();
    if (doc.exists && doc.data()!['stickerCounts'] != null) {
      final cloudStickers = doc.data()!['stickerCounts'] as Map<String, dynamic>;
      final counts = cloudStickers.map((countryId, value) {
        return MapEntry(countryId, (value as Map<String, dynamic>).map((s, c) => MapEntry(int.parse(s), c as int)));
      });

      // Restar reservas aceptadas que este amigo tiene con otros
      final resSnapshot = await _db.collection('reservations')
          .where('from', isEqualTo: friendUid)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      for (var resDoc in resSnapshot.docs) {
        final stickers = resDoc.data()['wanted'] as List? ?? [];
        for (var s in stickers) {
          final cId = s['countryId'];
          final num = s['number'];
          if (counts[cId] != null && (counts[cId]![num] ?? 0) > 0) {
            counts[cId]![num] = counts[cId]![num]! - 1;
          }
        }
      }
      
      _friendStickersCache[friendUid] = counts;
      _friendStickersCacheTime[friendUid] = now;
      return counts;
    }
    return {};
  }

  // --- RESERVATION LOGIC ---
  int getStickerWeight(String countryId, int number) {
    final country = getCountryById(countryId);
    if (country == null) return 1;
    if (country.isSpecial || country.isCocaCola || number == 1) return 2;
    return 1;
  }

  Future<void> sendReservationRequest({
    required String friendUid,
    required List<Map<String, dynamic>> wantedStickers,
    required List<Map<String, dynamic>> offeredStickers,
  }) async {
    if (_currentUser == null) return;
    await _db.collection('reservations').add({
      'from': friendUid, // Quien da las 'wanted'
      'to': _currentUser!.uid, // Quien da las 'offered'
      'wanted': wantedStickers,
      'offered': offeredStickers,
      'status': 'pending',
      'lastActionBy': _currentUser!.uid,
      'turnOf': friendUid,
      'timestamp': FieldValue.serverTimestamp(),
      'fromNick': _userProfile?.nickname ?? 'Usuario',
      'toNick': 'Yo',
    });
    // Notificar al amigo
    await _db.collection('notifications').add({
      'to': friendUid,
      'title': '¡Nueva solicitud de intercambio!',
      'body': '${_userProfile?.nickname} te ha enviado una propuesta.',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getIncomingReservations() {
    return _db.collection('reservations')
        .where('turnOf', isEqualTo: _currentUser?.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getSentReservations() {
    return _db.collection('reservations')
        .where('lastActionBy', isEqualTo: _currentUser?.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> respondToReservation(String resId, String status, {List? finalWanted, List? finalOffered}) async {
    final doc = await _db.collection('reservations').doc(resId).get();
    if (!doc.exists) return;
    
    final data = doc.data()!;
    final fromUid = data['from'];
    final toUid = data['to'];
    final otherUid = (_currentUser!.uid == fromUid) ? toUid : fromUid;
    
    if (status == 'accepted') {
      await _db.collection('reservations').doc(resId).update({
        'status': 'accepted',
        'wanted': finalWanted ?? data['wanted'],
        'offered': finalOffered ?? data['offered'],
        'completedAt': FieldValue.serverTimestamp(),
        'isDelivered': false,
      });
      // Notificar aceptación
      await _db.collection('notifications').add({
        'to': otherUid,
        'title': '¡Intercambio Aceptado!',
        'body': '${_userProfile?.nickname} ha aceptado el intercambio. ¡Coordinen la entrega!',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _scheduleDeliveryReminders();
    } else if (status == 'modified') {
      await _db.collection('reservations').doc(resId).update({
        'status': 'pending',
        'wanted': finalWanted,
        'offered': finalOffered,
        'lastActionBy': _currentUser!.uid,
        'turnOf': otherUid,
      });
      // Notificar modificación
      await _db.collection('notifications').add({
        'to': otherUid,
        'title': 'Propuesta modificada',
        'body': '${_userProfile?.nickname} ha modificado el intercambio.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await _db.collection('reservations').doc(resId).update({'status': 'rejected'});
    }
    notifyListeners();
  }

  Stream<QuerySnapshot> getHistoryReservations() {
    // Simplificamos la consulta para evitar requerir índices compuestos de Firestore
    return _db.collection('reservations')
        .where('status', isEqualTo: 'accepted')
        .where('isDelivered', isEqualTo: false)
        .snapshots();
  }

  Future<void> markAsDelivered(String resId) async {
    await _db.collection('reservations').doc(resId).update({'isDelivered': true});
    notifyListeners();
  }

  void _scheduleDeliveryReminders() {
    // Recordatorio diario simple al abrir la app o aceptar un cambio
    const androidDetails = AndroidNotificationDetails(
      'delivery_reminders', 
      'Entregas', 
      importance: Importance.high,
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    _localNotifications.show(
      99, 
      '¡Pendientes de entrega!', 
      'Tienes intercambios aceptados que aún no has entregado físicamente.', 
      const NotificationDetails(android: androidDetails)
    );
  }

  Future<void> downloadProgress() async {
    if (_currentUser == null) return;
    final doc = await _db.collection('users').doc(_currentUser!.uid).get();
    if (doc.exists && doc.data()!['stickerCounts'] != null) {
      final cloudStickers = doc.data()!['stickerCounts'] as Map<String, dynamic>;
      _stickerCounts = cloudStickers.map((countryId, value) {
        return MapEntry(countryId, (value as Map<String, dynamic>).map((s, c) => MapEntry(int.parse(s), c as int)));
      });
      notifyListeners();
    }
  }

  void _setLoading(bool value) { _isLoading = value; notifyListeners(); }

  final List<WorldCupGroup> groups = WorldCupData.groups;

  final List<Badge> badges = WorldCupData.badges;

  void checkNewBadges() {
    BadgeManager().checkNewBadges(this);
  }

}
