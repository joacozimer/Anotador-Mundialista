import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../app_state.dart';
import '../widgets/country_view.dart';

class CountryScreen extends StatelessWidget {
  final Country country;

  const CountryScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(country.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(provider.currentBgPath, fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.8))),
          CountryView(country: country),
        ],
      ),
    );
  }
}
