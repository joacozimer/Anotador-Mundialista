import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdHelper {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;
  static bool bannerLoaded = false;
  static bool interstitialLoaded = false;
  static String lastError = '';

  static Future<void> setAdInProcess(bool inProcess) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ad_in_process', inProcess);
  }

  static Future<bool> wasAdInProcess() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ad_in_process') ?? false;
  }

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return dotenv.env['ADMOB_BANNER_ID_ANDROID'] ?? 'ca-app-pub-8636403868395324/7693968436';
    return '';
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) return dotenv.env['ADMOB_INTERSTITIAL_ID_ANDROID'] ?? 'ca-app-pub-8636403868395324/4830025584';
    return '';
  }

  static BannerAd? createBannerAd(Function(Ad) onAdLoaded) {
    if (kIsWeb) return null;
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          bannerLoaded = true;
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          bannerLoaded = false;
          lastError = 'Banner: ${error.message}';
          ad.dispose();
        },
      ),
    );
  }

  static void loadInterstitialAd({bool showAfterLoad = false}) {
    if (kIsWeb || _isInterstitialAdLoading) return;
    
    if (_interstitialAd != null) {
      interstitialLoaded = true;
      if (showAfterLoad) _interstitialAd!.show();
      return;
    }

    _isInterstitialAdLoading = true;
    
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          interstitialLoaded = true;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              setAdInProcess(true);
            },
            onAdDismissedFullScreenContent: (ad) {
              setAdInProcess(false);
              ad.dispose();
              _interstitialAd = null;
              interstitialLoaded = false;
              loadInterstitialAd(); 
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              setAdInProcess(false);
              ad.dispose();
              _interstitialAd = null;
              interstitialLoaded = false;
              loadInterstitialAd();
            },
          );
          if (showAfterLoad) {
            _interstitialAd!.show();
          }
        },
        onAdFailedToLoad: (err) {
          _isInterstitialAdLoading = false;
          interstitialLoaded = false;
          lastError = 'Interstitial: ${err.message}';
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      loadInterstitialAd(showAfterLoad: true);
    }
  }
}
