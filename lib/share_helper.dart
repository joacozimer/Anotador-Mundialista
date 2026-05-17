import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class ShareHelper {
  static Future<void> shareData(BuildContext context, Map<String, dynamic> options) async {
    try {
      final provider = Provider.of<WorldCupProvider>(context, listen: false);
      final String type = options['type'] ?? 'all';
      
      Map<String, dynamic> dataToShare = {};
      
      if (type == 'all') {
        dataToShare = {
          'type': 'full_progress',
          'stickerCounts': _serializeStickers(provider),
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else if (type == 'missing') {
        dataToShare = {
          'type': 'missing_list',
          'missing': _getMissingList(provider),
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else if (type == 'repeated') {
        dataToShare = {
          'type': 'repeated_list',
          'repeated': _getRepeatedList(provider),
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/datos_anotador.zam');
      await file.writeAsString(jsonEncode(dataToShare));
      
      final XFile xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Mis datos de figuritas (.zam)');
    } catch (e) {
      print('Error sharing: $e');
    }
  }

  static Map<String, dynamic> _serializeStickers(WorldCupProvider provider) {
    // Implementar serialización real basada en app_state si es necesario
    return {}; 
  }

  static List<String> _getMissingList(WorldCupProvider provider) {
    List<String> list = [];
    for (var group in provider.groups) {
      for (var country in group.countries) {
        for (int i = 1; i <= country.totalStickers; i++) {
          if (!provider.isObtained(country.id, i)) {
            list.add('${country.name} #$i');
          }
        }
      }
    }
    return list;
  }

  static List<String> _getRepeatedList(WorldCupProvider provider) {
    List<String> list = [];
    for (var group in provider.groups) {
      for (var country in group.countries) {
        for (int i = 1; i <= country.totalStickers; i++) {
          final count = provider.getStickerCount(country.id, i);
          if (count > 1) {
            list.add('${country.name} #$i (x${count - 1})');
          }
        }
      }
    }
    return list;
  }

  static Future<void> handleSharedFile(BuildContext context, String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final data = jsonDecode(content);
      _showImportDialog(context, data);
    } catch (e) { print(e); }
  }

  static void _showImportDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Archivo .zam recibido', style: TextStyle(color: Colors.white)),
        content: Text('Se ha detectado un archivo de tipo: ${data['type']}. ¿Deseas procesar los datos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Lógica de importación
            },
            child: const Text('IMPORTAR'),
          ),
        ],
      ),
    );
  }
}
