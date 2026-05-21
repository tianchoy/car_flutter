import 'package:flutter_dotenv/flutter_dotenv.dart';

String baseUrl = dotenv.get('API_URL');
String mapUrl =
    'https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=7';
String loginUrl = '/sys/login';
String logoutUrl = '/sys/logout';
String userInfoUrl = '/sys/user/info';
String userDeviceList = '/userDevice/list';
String messagesListUrl = '/usermessage/listForUser';
