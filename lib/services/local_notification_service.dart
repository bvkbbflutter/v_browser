import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

typedef NotificationActionCallback = void Function(String actionId);

@pragma('vm:entry-point')
void _handleBackgroundNotificationClick(NotificationResponse notificationResponse) {
  LocalNotificationServiceV.handleNotificationResponse(notificationResponse);
}

class LocalNotificationServiceV {
  static final LocalNotificationServiceV _instance = LocalNotificationServiceV._internal();
  factory LocalNotificationServiceV() => _instance;
  LocalNotificationServiceV._internal();

  static const String downloadChannelId = 'vortex_downloads_v3';
  static const String downloadChannelName = 'Downloads';
  static const String downloadChannelDesc = 'Download progress and active transfers';

  static final List<NotificationActionCallback> _actionListeners = [];

  static void addActionListener(NotificationActionCallback listener) {
    if (!_actionListeners.contains(listener)) {
      _actionListeners.add(listener);
    }
  }

  static void removeActionListener(NotificationActionCallback listener) {
    _actionListeners.remove(listener);
  }

  static void dispatchAction(String actionId) {
    debugPrint('Dispatching notification action: $actionId');
    for (final listener in List.of(_actionListeners)) {
      try {
        listener(actionId);
      } catch (e) {
        debugPrint('Error in notification action listener: $e');
      }
    }
  }

  static void handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId != null && actionId.isNotEmpty) {
      debugPrint('Notification action clicked: $actionId');

      if (actionId.startsWith('action_dl_open_')) {
        final path = actionId.replaceFirst('action_dl_open_', '');
        OpenFile.open(path);
      } else if (actionId.startsWith('action_dl_share_')) {
        final path = actionId.replaceFirst('action_dl_share_', '');
        Share.shareXFiles([XFile(path)]);
      }

      dispatchAction(actionId);
      return;
    }

    if (payload != null && payload.isNotEmpty) {
      debugPrint('Notification payload clicked: $payload');
      try {
        OpenFile.open(payload);
      } catch (_) {}
    }
  }

  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  final Map<int, int> _lastNotificationTime = {};

  bool get isInitialised => _isInitialized;

  Future<void> initNotifications() async {
    if (_isInitialized) return;

    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    _isInitialized = (await notificationsPlugin.initialize(
          initSettings,
          onDidReceiveNotificationResponse: handleNotificationResponse,
          onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationClick,
        )) ??
        false;

    // Explicitly create Notification Channels on Android
    final android = notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          downloadChannelId,
          downloadChannelName,
          description: downloadChannelDesc,
          importance: Importance.high,
          playSound: false,
          enableVibration: false,
          showBadge: true,
        ),
      );
    }
  }

  Future<bool> requestPermission() async {
    try {
      final android = notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        if (granted == true) return true;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission via local notifications: $e');
    }

    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting notification permission via permission_handler: $e');
    }
    return false;
  }

  // DOWNLOAD NOTIFICATIONS WITH ACTIONS
  Future<void> showDownloadNotificationProgress({
    required int notificationId,
    required String id,
    required String fileName,
    required double progress,
    required String speed,
    required String downloadedFormatted,
    required String totalFormatted,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastNotificationTime[notificationId] ?? 0;
    if (now - last < 400 && progress < 0.99 && progress > 0.01) {
      return;
    }
    _lastNotificationTime[notificationId] = now;

    final progressInt = (progress * 100).clamp(0, 100).toInt();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      downloadChannelId,
      downloadChannelName,
      channelDescription: downloadChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progressInt,
      ongoing: true,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_dl_pause_$id',
          'Pause',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'action_dl_cancel_$id',
          'Cancel',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      notificationId,
      'Downloading $fileName',
      '$progressInt% · $downloadedFormatted of $totalFormatted ($speed)',
      details,
    );
  }

  Future<void> showDownloadPausedNotification({
    required int notificationId,
    required String id,
    required String fileName,
    required double progress,
    required String downloadedFormatted,
    required String totalFormatted,
  }) async {
    _lastNotificationTime.remove(notificationId);
    final progressInt = (progress * 100).clamp(0, 100).toInt();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      downloadChannelId,
      downloadChannelName,
      channelDescription: downloadChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progressInt,
      ongoing: false,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_dl_resume_$id',
          'Resume',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'action_dl_cancel_$id',
          'Cancel',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      notificationId,
      'Paused: $fileName',
      'Download paused at $progressInt% ($downloadedFormatted of $totalFormatted)',
      details,
    );
  }

  Future<void> showDownloadCompleteNotification({
    required int notificationId,
    required String fileName,
    required String filePath,
  }) async {
    _lastNotificationTime.remove(notificationId);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      downloadChannelId,
      downloadChannelName,
      channelDescription: downloadChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_dl_open_$filePath',
          'Open',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'action_dl_share_$filePath',
          'Share',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      notificationId,
      'Download Complete',
      '$fileName has finished downloading. Tap to open.',
      details,
      payload: filePath,
    );
  }

  Future<void> showDownloadFailedNotification({
    required int notificationId,
    required String id,
    required String fileName,
    String? reason,
  }) async {
    _lastNotificationTime.remove(notificationId);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      downloadChannelId,
      downloadChannelName,
      channelDescription: downloadChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_dl_retry_$id',
          'Retry',
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      notificationId,
      'Download Failed',
      'Failed to download $fileName: ${reason ?? 'Network error'}',
      details,
    );
  }

  Future<void> cancelNotification(int notificationId) async {
    _lastNotificationTime.remove(notificationId);
    await notificationsPlugin.cancel(notificationId);
  }
}
