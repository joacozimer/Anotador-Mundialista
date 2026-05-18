import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supportEmail => dotenv.env['SUPPORT_EMAIL'] ?? 'zimlabs26@gmail.com';
  static String get appName => dotenv.env['APP_NAME'] ?? 'Anotador Mundialista';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.1';
  static String get playStoreUrl => dotenv.env['PLAY_STORE_URL'] ?? 'https://play.google.com/store/apps/details?id=anotador.mundialista.com';

  // Configuración de EmailJS (Plan gratuito: 200 mails/mes)
  static String get emailjsServiceId => dotenv.env['EMAILJS_SERVICE_ID'] ?? 'anotador_mundialista'; 
  static String get emailjsTemplateId => dotenv.env['EMAILJS_TEMPLATE_ID'] ?? 'template_of9vulk'; 
  static String get emailjsPublicKey => dotenv.env['EMAILJS_PUBLIC_KEY'] ?? 'K14oNKVLveylP9gmI'; 
  static String get emailjsAccessToken => dotenv.env['EMAILJS_ACCESS_TOKEN'] ?? 'R52070ioPCSKEbm5uS0re';
}
