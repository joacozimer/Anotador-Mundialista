import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../app_state.dart';
import '../config.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorldCupProvider>(context);
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('CONFIGURACIÓN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black54,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
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
              color: Colors.black.withOpacity(0.65),
            ),
          ),
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              SwitchListTile(
                title: const Text('Saltear video inicial', style: TextStyle(color: Colors.white, fontSize: 16)),
                value: provider.skipIntro,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (val) => provider.setSkipIntro(val),
                secondary: const Icon(Icons.movie_filter, color: Color(0xFFD4AF37)),
              ),
              const Divider(color: Colors.white10, height: 30),
              _buildBgSelector(provider),
              const Divider(color: Colors.white10, height: 30),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline, color: Color(0xFFD4AF37)),
                title: const Text('Enviar Sugerencia', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () async {
                  if (!await provider.isOnline()) {
                    if (context.mounted) _showOfflineWarning(context);
                    return;
                  }
                  if (context.mounted) _showSuggestionDialog(context, provider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_rate, color: Color(0xFFD4AF37)),
                title: const Text('Calificar aplicación', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () async {
                  final url = Uri.parse(AppConfig.playStoreUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No se pudo abrir la Play Store'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
              ),
              if (user == null)
                ListTile(
                  leading: const Icon(Icons.login, color: Color(0xFFD4AF37)),
                  title: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white, fontSize: 16)),
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        backgroundColor: Color(0xFF1E293B),
                        content: Row(
                          children: [
                            CircularProgressIndicator(color: Color(0xFFD4AF37)),
                            SizedBox(width: 20),
                            Text('Iniciando sesión...', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                    try {
                      await provider.signInWithGoogle();
                    } catch (e) {}
                    if (context.mounted) Navigator.pop(context);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontSize: 16)),
                  onTap: () => _showLogoutDialog(context, provider),
                ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Versión de aplicación v${dotenv.env['APP_VERSION'] ?? '1.0.1(34)'}', 
                  style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBgSelector(WorldCupProvider provider) {
    final bgs = [
      {'id': 'Messi', 'path': 'assets/messi.png'},
      {'id': 'Maradona', 'path': 'assets/maradona.png'},
      {'id': 'Kempes', 'path': 'assets/kempes.png'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('FONDO DE PANTALLA', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildBgThumbnail('Aleatorio', null, provider),
                ...bgs.map((bg) => _buildBgThumbnail(bg['id']!, bg['path']!, provider)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBgThumbnail(String id, String? path, WorldCupProvider provider) {
    final isSelected = provider.bgMode == id;
    return GestureDetector(
      onTap: () {
        provider.recordTap();
        provider.setBgMode(id);
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.white10, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              path != null
                ? Image.asset(path, fit: BoxFit.cover)
                : Container(
                    color: Colors.white10,
                    child: const Icon(Icons.shuffle, color: Color(0xFFD4AF37), size: 30),
                  ),
              if (isSelected)
                Container(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(id, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfflineWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Text('Sin conexión', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Esta función requiere una conexión a internet activa para funcionar correctamente.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  void _showSuggestionDialog(BuildContext context, WorldCupProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 40,
          top: 15,
          left: 25,
          right: 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFD4AF37), size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sugerencias', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text('Tu opinión nos ayuda a crecer', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _SuggestionForm(provider: provider),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WorldCupProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async { 
              await provider.signOut(); 
              if (context.mounted) Navigator.pop(context); 
            }, 
            child: const Text('Salir')
          ),
        ],
      ),
    );
  }
}

class _SuggestionForm extends StatefulWidget {
  final WorldCupProvider provider;
  const _SuggestionForm({required this.provider});

  @override
  State<_SuggestionForm> createState() => _SuggestionFormState();
}

class _SuggestionFormState extends State<_SuggestionForm> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Cuéntanos qué te gustaría mejorar...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            shadowColor: const Color(0xFFD4AF37).withOpacity(0.4),
          ),
          onPressed: _isSending ? null : () => _sendViaGmail(context),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_rounded, size: 20),
              SizedBox(width: 10),
              Text('ENVIAR POR GMAIL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendViaGmail(BuildContext context) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: 'subject=Sugerencia Anotador Mundialista&body=$text',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la app de correo'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
