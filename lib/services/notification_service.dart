import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() => _notificationService;
  NotificationService._internal();

  // 1. INISIALISASI
  Future<void> init() async {
    // Minta izin ke user
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // Buat Channel Notifikasi (Menggunakan API lama untuk init)
    await AwesomeNotifications().initialize(
        null, 
        [
          NotificationChannel(
            channelGroupKey: 'arunika_group', 
            channelKey: 'pesanan_channel',
            channelName: 'Notifikasi arunika', 
            channelDescription: 'Channel untuk semua notifikasi aplikasi arunika',
            defaultColor: Colors.purple,
            ledColor: Colors.purple,
            importance: NotificationImportance.High,
            enableLights: true,
            enableVibration: true,
          )
        ],
        channelGroups: [
          NotificationChannelGroup(
              channelGroupKey: 'aromaloca_group',
              channelGroupName: 'Grup Notifikasi arunika'),
        ],
        debug: true);
  }

  // 2. FUNGSI NOTIFIKASI INSTAN (Checkout)
  Future<void> showInstantNotification(
      int id, String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'pesanan_channel', 
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        autoDismissible: true,
      ),
    );
  }

  // 3. FUNGSI JADWAL 10 DETIK (Logout)
  Future<void> scheduleFinalNotification(
      String title, String body, int seconds) async {
    // ID 100 agar unik dan tidak bentrok
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 100, 
        channelKey: 'pesanan_channel', 
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        autoDismissible: true,
      ),
      schedule: NotificationCalendar.fromDate(
        date: DateTime.now().add(Duration(seconds: seconds)),
        preciseAlarm: true,
      ),
    );
  }
}