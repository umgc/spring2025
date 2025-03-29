import 'package:flutter_localization/flutter_localization.dart';

const List<MapLocale> LOCALES = [
  MapLocale("en", LocaleData.EN),
  MapLocale("es", LocaleData.ES),
  ];

mixin LocaleData {
  static const String title = 'title';
  static const String body = 'body';

  static const Map<String, dynamic> EN = {
    title: 'Localization',
    body: 'Welcome to this localized Flutter application %a'
  };

  static const Map<String, dynamic> ES = {
    title: 'Localización',
    body: 'Bienvenido a esta aplicación Flutter localizada %a'
  };

}