/// Lightweight inline localisation helper.
///
/// Usage in a widget:
///   final hi = ref.watch(languageProvider);   // true = Hindi
///   Text(tr('Dashboard', 'डैशबोर्ड', hi));
String tr(String en, String hi, bool isHindi) => isHindi ? hi : en;
