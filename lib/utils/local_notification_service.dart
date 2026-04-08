// المسار: lib/utils/local_notification_service.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static Future<void> initialize() async {
    // تهيئة الإشعارات مع القناة الخاصة باللعبة
    await AwesomeNotifications().initialize(
      null, // وضع null يخليه يسحب أيقونة اللعبة الأساسية تلقائياً
      [
        NotificationChannel(
          channelKey: 'turf_war_channel',
          channelName: 'إشعارات حرب النفوذ',
          channelDescription: 'تنبيهات وأخبار اللعبة',
          defaultColor: Colors.amber, // لون الإشعار الذهبي
          ledColor: Colors.amber, // لون إضاءة الجوال
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          criticalAlerts: true,
        )
      ],
    );

    // طلب صلاحية الإشعارات من اللاعب (ضرورية لأندرويد 13+)
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> showNotification(String title, String body) async {
    // إنشاء وإرسال الإشعار للجوال
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecond,
        channelKey: 'turf_war_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: Colors.amber,
      ),
    );
  }
}