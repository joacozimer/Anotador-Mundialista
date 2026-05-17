import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ad_helper.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = AdHelper.createBannerAd((ad) {
      setState(() {});
    })?..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) return const SizedBox.shrink();
    
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        top: false,
        child: Container(
          height: _bannerAd!.size.height.toDouble(),
          width: double.infinity,
          alignment: Alignment.center,
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
