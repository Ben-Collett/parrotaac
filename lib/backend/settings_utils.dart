import 'package:parrotaac/backend/quick_store.dart';

QuickStore _settingsQuickstore = QuickStore('settings');
Future<void> initializeSettings() {
  return _settingsQuickstore.initialize();
}
