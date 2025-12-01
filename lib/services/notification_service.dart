import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/token.dart';
import '../models/token_type.dart';
import '../models/token_status.dart';
import '../services/token_service.dart';

class NotificationService {
  final TokenService tokenService;
  final List<String> _notifiedTokens = [];
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  NotificationService(this.tokenService) {
    tokenService.addListener(_checkForNotifications);
    _init();
  }

  Future<void> _init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'token_updates',
      'Token Updates',
      description: 'Notifications for token status changes',
      importance: Importance.high,
    );
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  void _checkForNotifications() {
    for (var token in tokenService.activeTokens) {
      if (token.status == TokenStatus.nearTurn &&
          !_notifiedTokens.contains(token.id)) {
        _showNotification(token);
        _notifiedTokens.add(token.id);
      } else if (token.status == TokenStatus.active &&
          !_notifiedTokens.contains('${token.id}_active')) {
        _showActiveNotification(token);
        _notifiedTokens.add('${token.id}_active');
      }
    }
  }

  void _showNotification(Token token) {
    _plugin.show(
      token.hashCode,
      'Your turn is near',
      '${token.type.displayName} • Position: ${token.queuePosition}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'token_updates',
          'Token Updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _showActiveNotification(Token token) {
    _plugin.show(
      '${token.hashCode}_active'.hashCode,
      'It\'s your turn!',
      '${token.type.displayName} token is now active. Please proceed.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'token_updates',
          'Token Updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void dispose() {
    tokenService.removeListener(_checkForNotifications);
  }
}
