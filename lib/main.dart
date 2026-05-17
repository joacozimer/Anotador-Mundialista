import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_state.dart';
import 'ad_helper.dart';
import 'screens/home_screen.dart';
import 'screens/video_intro_screen.dart';
import 'widgets/ad_banner_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await Firebase.initializeApp();
  
  if (!kIsWeb) {
    MobileAds.instance.initialize();
    AdHelper.loadInterstitialAd();
  }
  
  final provider = WorldCupProvider();
  await provider.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => provider,
      child: const AnotadorMundialApp(),
    ),
  );
}

class AnotadorMundialApp extends StatelessWidget {
  const AnotadorMundialApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context, listen: false);
    
    return MaterialApp(
      title: 'Anotador Mundialista',
      scaffoldMessengerKey: WorldCupProvider.scaffoldMessengerKey,
      navigatorKey: WorldCupProvider.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.dark,
          secondary: const Color(0xFFD4AF37),
        ),
        useMaterial3: true,
      ),
      home: provider.skipIntro ? const HomeScreen() : const VideoIntroScreen(),
      builder: (context, child) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(child: child!),
              const AdBannerWidget(),
            ],
          ),
        );
      },
    );
  }
}
