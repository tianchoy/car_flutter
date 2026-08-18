import 'package:flutter_dotenv/flutter_dotenv.dart';

String baseUrl = dotenv.get('API_URL');
String mapUrl =
    'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=2&style=8&x={x}&y={y}&z={z}';
String loginUrl = '/sys/login';
String logoutUrl = '/sys/logout';
String userInfoUrl = '/sys/user/info';
String userDeviceList = '/userDevice/list';
String messagesListUrl = '/usermessage/listForUser';
String trackPos = '/gps/trackPos?';
