import 'package:flutter_local_notifications/flutter_local_notifications.dart';



@pragma('vm:entry-point')
void _handleBackgroundNotificationClick(NotificationResponse notificationResponse) {
  // checking the notification response is not null
  if (notificationResponse.payload != null) {
    print('Notification Payload: ${notificationResponse.payload}');
    // initially check wheather the notification is empty or not
    // if (notificationData.isNotEmpty){
    //   if (navigatorKey.currentState != null){
    //     // Navigate based on the payload
    //     navigate(message: notificationData);
    //   }else{
    //     print("navigatorKey?.currentState == null");
    //   }
    // }
  }
}

class LocalNotificationServiceV {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool? _isInitialized = false;

  bool get isInitialised => _isInitialized!;

  // INITIALIZATION
  Future<void> initNotifications() async {
    if (_isInitialized!) return; // prevent re-initialization

    // prepare android init settings
    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    // prepare ios init settings
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // register the settings
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS
    );

    // finally initialise the local notifications
    _isInitialized = await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // _handleLocalNotificationClick(response);
      },
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationClick, // Background response
    );
  }

  // NOTIFICATION DETAILS SETUP
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        "Daily Notifications",
        channelDescription: 'Daily Notification Channel',
        importance: Importance.high,
        priority: Priority.high
      ),
      iOS: DarwinNotificationDetails()
    );
  }

  // SHOW NOTIFICATIONS METHOD
  Future<void> showDownloadNotificationProgress(String url, double progress) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'download_channel',
      'File Downloads',
      importance: Importance.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: (progress * 100).toInt(),
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      url.hashCode,
      "Downloading...",
      "${(progress * 100).toStringAsFixed(1)}% completed",
      details,
    );
  }



  Future<void> showDownloadCompleteNotification(String filePath) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'download_channel',
      'File Downloads',
      importance: Importance.high,
      priority: Priority.high,
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      filePath.hashCode,
      "Download Complete",
      "Tap to open file",
      details,
      payload: filePath,
    );
  }
}