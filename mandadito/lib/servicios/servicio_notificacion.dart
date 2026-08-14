import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:mandadito/modelos/articulo.dart';
import 'package:mandadito/modelos/compra.dart';

//La alarma empieza a avisar 30 días antes de la fecha de caducidad
//A partir de esto se manda una notificación diaria hasta que
//el usuario elimine el producto consumido o se echado a perder
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _expirationHour = 9; //hora del día para el aviso diario

  Future<void> init() async {
    tz_data.initializeTimeZones();//zona horaria

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  //Programa el aviso de caducidad para un producto de la despensa
  Future<void> scheduleExpirationAlert(Articulo item) async {
    if (item.id == null) return;

    //30 días antes de caducar
    DateTime start = DateTime(
      item.expirationDate.year,
      item.expirationDate.month,
      item.expirationDate.day,
    ).subtract(const Duration(days: 30)).add(
          const Duration(hours: _expirationHour),
        );


    final now = DateTime.now();
    if (start.isBefore(now)) {
      start = DateTime(now.year, now.month, now.day, _expirationHour);
      if (start.isBefore(now)) {
        start = start.add(const Duration(days: 1));
      }
    }

    final scheduledDate = tz.TZDateTime.from(start, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'expiracion_channel',
      'Caducidad de alimentos',
      channelDescription:
          'Avisos de productos próximos a caducar en tu despensa',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _expirationNotificationId(item.id!),
      'Tu ${item.name} está por caducar',
      _buildBody(item),
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'pantry_item_${item.id}',
    );
  }

  String _buildBody(Articulo item) {
    final days = item.daysUntilExpiration;
    if (days < 0) {
      return 'Ya caducó (hace ${-days} días). Revisa si aún se puede consumir o tíralo de tu despensa';
    } else if (days == 0) {
      return '¡Caduca hoy! Cantidad: ${item.quantity} - ${item.contentSize}.';
    }
    return 'Caduca en $days días. Cantidad: ${item.quantity} - ${item.contentSize}.';
  }

  //Elimina el aviso recurrente porque el producto se eliminó
  Future<void> cancelExpirationAlert(int itemId) async {
    await _plugin.cancel(_expirationNotificationId(itemId));
  }

  int _expirationNotificationId(int itemId) => 100000 + itemId;


  //STOCK BAJO

  ///Notificación que avisa si se acabará un artículo
  Future<void> notifyLowStock(Articulo item) async {
    if (item.id == null) return;

    const androidDetails = AndroidNotificationDetails(
      'low_stock_channel',
      'Insumos por acabarse',
      channelDescription:
          'Avisa cuando un producto está por acabar',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      _lowStockNotificationId(item.id!),
      'Se está acabando: ${item.name}',
      'Ya solo queda 1 pieza. Quizás quieras agregarlo a tu lista de compras.',
      details,
      payload: 'low_stock_${item.id}',
    );
  }

  int _lowStockNotificationId(int itemId) => 200000 + itemId;

  Future<void> cancelLowStock(int itemId) async {
    await _plugin.cancel(_lowStockNotificationId(itemId));
  }

  //LISTA DE COMPRAS

  //Programa una alarma avisando qué productos siguen pendientes de comprar
  Future<void> scheduleShoppingReminder({
    required DateTime plannedDate,
    required List<Compra> pendingItems,
  }) async {
    if (pendingItems.isEmpty) return;

    final scheduled = tz.TZDateTime.from(
      DateTime(
        plannedDate.year,
        plannedDate.month,
        plannedDate.day,
        _expirationHour,
      ),
      tz.local,
    );

    const androidDetails = AndroidNotificationDetails(
      'shopping_channel',
      'Lista de compras',
      channelDescription: 'Recordatorios de productos pendientes por comprar',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final names = pendingItems.map((e) => e.name).join(', ');

    await _plugin.zonedSchedule(
      999999,
      'Te faltan ${pendingItems.length} productos por comprar',
      names,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'shopping_list',
    );
  }

  Future<void> cancelShoppingReminder() async {
    await _plugin.cancel(999999);
  }
}