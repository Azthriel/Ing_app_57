// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:io' show File;
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'dart:io';

final TextEditingController nicknameController = TextEditingController();
final TextEditingController regPointController = TextEditingController();
String? nickname;
int regPoint = 0;
List<String> numbersToCheck = [];
List<String> statusOfDevices = [];
String prevText = '';
late List<String> pikachu;
bool alreadySubReg = false;
bool alreadySubCal = false;
bool alreadySubOta = false;
bool alreadySubDebug = false;
bool alreadySubWork = false;

final flutterBluePlus = FlutterBluePlus();
final dio = Dio();
MyDevice myDevice = MyDevice();
final deviceDiagnosisResults = <String, String>{};

String myDeviceid = '';
String deviceName = '';
String wifiName = '';
String wifiPassword = '';
bool atemp = false;
late bool factoryMode;
List<int> calibrationValues = [];
List<int> regulationValues = [];
List<int> toolsValues = [];
List<int> debugValues = [];
List<int> workValues = [];
List<int> infoValues = [];
bool isWifiConnected = false;
bool wifilogoConnected = false;
String textState = '';
String errorMessage = '';
String errorSintax = '';
String nameOfWifi = '';
var wifiIcon = Icons.wifi_off;
bool connectionFlag = false;
bool checkbleFlag = false;
bool bluetoothOn = false;
double sliderValue = 0.0;

MaterialColor statusColor = Colors.grey;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// FUNCIONES //

String getWifiErrorSintax(int errorCode) {
  switch (errorCode) {
    case 1:
      return "WIFI_REASON_UNSPECIFIED";
    case 2:
      return "WIFI_REASON_AUTH_EXPIRE";
    case 3:
      return "WIFI_REASON_AUTH_LEAVE";
    case 4:
      return "WIFI_REASON_ASSOC_EXPIRE";
    case 5:
      return "WIFI_REASON_ASSOC_TOOMANY";
    case 6:
      return "WIFI_REASON_NOT_AUTHED";
    case 7:
      return "WIFI_REASON_NOT_ASSOCED";
    case 8:
      return "WIFI_REASON_ASSOC_LEAVE";
    case 9:
      return "WIFI_REASON_ASSOC_NOT_AUTHED";
    case 10:
      return "WIFI_REASON_DISASSOC_PWRCAP_BAD";
    case 11:
      return "WIFI_REASON_DISASSOC_SUPCHAN_BAD";
    case 12:
      return "WIFI_REASON_BSS_TRANSITION_DISASSOC";
    case 13:
      return "WIFI_REASON_IE_INVALID";
    case 14:
      return "WIFI_REASON_MIC_FAILURE";
    case 15:
      return "WIFI_REASON_4WAY_HANDSHAKE_TIMEOUT";
    case 16:
      return "WIFI_REASON_GROUP_KEY_UPDATE_TIMEOUT";
    case 17:
      return "WIFI_REASON_IE_IN_4WAY_DIFFERS";
    case 18:
      return "WIFI_REASON_GROUP_CIPHER_INVALID";
    case 19:
      return "WIFI_REASON_PAIRWISE_CIPHER_INVALID";
    case 20:
      return "WIFI_REASON_AKMP_INVALID";
    case 21:
      return "WIFI_REASON_UNSUPP_RSN_IE_VERSION";
    case 22:
      return "WIFI_REASON_INVALID_RSN_IE_CAP";
    case 23:
      return "WIFI_REASON_802_1X_AUTH_FAILED";
    case 24:
      return "WIFI_REASON_CIPHER_SUITE_REJECTED";
    case 25:
      return "WIFI_REASON_TDLS_PEER_UNREACHABLE";
    case 26:
      return "WIFI_REASON_TDLS_UNSPECIFIED";
    case 27:
      return "WIFI_REASON_SSP_REQUESTED_DISASSOC";
    case 28:
      return "WIFI_REASON_NO_SSP_ROAMING_AGREEMENT";
    case 29:
      return "WIFI_REASON_BAD_CIPHER_OR_AKM";
    case 30:
      return "WIFI_REASON_NOT_AUTHORIZED_THIS_LOCATION";
    case 31:
      return "WIFI_REASON_SERVICE_CHANGE_PERCLUDES_TS";
    case 32:
      return "WIFI_REASON_UNSPECIFIED_QOS";
    case 33:
      return "WIFI_REASON_NOT_ENOUGH_BANDWIDTH";
    case 34:
      return "WIFI_REASON_MISSING_ACKS";
    case 35:
      return "WIFI_REASON_EXCEEDED_TXOP";
    case 36:
      return "WIFI_REASON_STA_LEAVING";
    case 37:
      return "WIFI_REASON_END_BA";
    case 38:
      return "WIFI_REASON_UNKNOWN_BA";
    case 39:
      return "WIFI_REASON_TIMEOUT";
    case 46:
      return "WIFI_REASON_PEER_INITIATED";
    case 47:
      return "WIFI_REASON_AP_INITIATED";
    case 48:
      return "WIFI_REASON_INVALID_FT_ACTION_FRAME_COUNT";
    case 49:
      return "WIFI_REASON_INVALID_PMKID";
    case 50:
      return "WIFI_REASON_INVALID_MDE";
    case 51:
      return "WIFI_REASON_INVALID_FTE";
    case 67:
      return "WIFI_REASON_TRANSMISSION_LINK_ESTABLISH_FAILED";
    case 68:
      return "WIFI_REASON_ALTERATIVE_CHANNEL_OCCUPIED";
    case 200:
      return "WIFI_REASON_BEACON_TIMEOUT";
    case 201:
      return "WIFI_REASON_NO_AP_FOUND";
    case 202:
      return "WIFI_REASON_AUTH_FAIL";
    case 203:
      return "WIFI_REASON_ASSOC_FAIL";
    case 204:
      return "WIFI_REASON_HANDSHAKE_TIMEOUT";
    case 205:
      return "WIFI_REASON_CONNECTION_FAIL";
    case 206:
      return "WIFI_REASON_AP_TSF_RESET";
    case 207:
      return "WIFI_REASON_ROAMING";
    default:
      return "Error Desconocido";
  }
}

void showToast(String message) {
  print('Toast: $message');
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color.fromARGB(255, 4, 76, 77),
      textColor: Colors.white,
      fontSize: 16.0);
}

Future<void> sendWifitoBle() async {
  MyDevice myDevice = MyDevice();
  String value = '$wifiName#$wifiPassword';
  String dataToSend = '57_IOT[2]($value)';
  print(dataToSend);
  try {
    await myDevice.toolsUuid.write(dataToSend.codeUnits);
    print('Se mando el wifi ANASHE');
  } catch (e) {
    print('Error al conectarse a Wifi $e');
  }
  atemp = true;
  wifiName = '';
  wifiPassword = '';
}

Future<void> openQRScanner(BuildContext context) async {
  try {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var qrResult = await navigatorKey.currentState
          ?.push(MaterialPageRoute(builder: (context) => const QRScanPage()));
      if (qrResult != null) {
        var wifiData = parseWifiQR(qrResult);
        wifiName = wifiData['SSID']!;
        wifiPassword = wifiData['password']!;
        sendWifitoBle();
      }
    });
  } catch (e) {
    print("Error during navigation: $e");
  }
}

Map<String, String> parseWifiQR(String qrContent) {
  print(qrContent);
  final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(qrContent);
  final passwordMatch = RegExp(r'P:([^;]+)').firstMatch(qrContent);

  final ssid = ssidMatch?.group(1) ?? '';
  final password = passwordMatch?.group(1) ?? '';
  return {"SSID": ssid, "password": password};
}

String generateErrorReport(FlutterErrorDetails details) {
  return '''
Error: ${details.exception}
Stacktrace: ${details.stack}
  ''';
}

void sendReportOnWhatsApp(String filePath) async {
  const text = 'Attached is the error report';
  final file = File(filePath);
  await Share.shareFiles([file.path], text: text);
}

void handleManualError(dynamic e, StackTrace stackTrace) async {
  String errorReport = """
Error: $e
Stack Trace:
$stackTrace
""";

  final fileName = 'error_report_${DateTime.now().toIso8601String()}.txt';
  final directory = await getExternalStorageDirectory();
  if (directory != null) {
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(errorReport);
    sendReportOnWhatsApp(file.path);
  } else {
    print('Failed to get external storage directory');
  }
}

void updateDiagnosisResult(String key, String result) {
  print('Actualicé la verga esta');
  deviceDiagnosisResults.addAll({key: result});
  print(deviceDiagnosisResults);
}

IconData getDiagnosisIcon(String diagnosisResult) {
  print(diagnosisResult);
  switch (diagnosisResult) {
    case 'ok':
      return Icons.check; // Ícono de tilde verde
    case 'error':
      return Icons.close; // Ícono de X roja
    default:
      return Icons.help_outline; // Ícono de signo de pregunta
  }
}

// CLASES //

class MyDevice {
  static final MyDevice _singleton = MyDevice._internal();

  factory MyDevice() {
    return _singleton;
  }

  MyDevice._internal();

  late BluetoothDevice device;
  late BluetoothCharacteristic toolsUuid;
  late BluetoothCharacteristic calibrationUuid;
  late BluetoothCharacteristic regulationUuid;
  late BluetoothCharacteristic lightUuid;
  late BluetoothCharacteristic otaUuid;
  late BluetoothCharacteristic debugUuid;
  late BluetoothCharacteristic workUuid;
  late BluetoothCharacteristic infoUuid;

  Future<bool> setup(BluetoothDevice connectedDevice) async {
    try {
      device = connectedDevice;

      List<BluetoothService> services =
          await device.discoverServices(timeout: 30);
      print('Los servicios: $services');

      BluetoothService infoService = services.firstWhere(
          (s) => s.uuid == Guid('6a3253b4-48bc-4e97-bacd-325a1d142038'));
      infoUuid = infoService.characteristics.firstWhere((c) =>
          c.uuid ==
          Guid(
              'fc5c01f9-18de-4a75-848b-d99a198da9be')); //ProductType:SerialNumber:SoftVer:HardVer:Owner
      toolsUuid = infoService.characteristics.firstWhere((c) =>
          c.uuid ==
          Guid(
              '3565a918-f830-4fa1-b743-18d618fc5269')); //WifiStatus:WifiSSID/WifiError:BleStatus(users)

      BluetoothService espService = services.firstWhere(
          (s) => s.uuid == Guid('33e3a05a-c397-4bed-81b0-30deb11495c7'));
      otaUuid = espService.characteristics.firstWhere(
          (c) => c.uuid == Guid('6e364bda-5f52-4d58-979d-44693840d271'));

      infoValues = await infoUuid.read();
      String str = utf8.decode(infoValues);
      var partes = str.split(':');
      factoryMode = partes[2].contains('_F');

      BluetoothService service = services.firstWhere(
          (s) => s.uuid == Guid('dd249079-0ce8-4d11-8aa9-53de4040aec6'));

      if (factoryMode) {
        calibrationUuid = service.characteristics.firstWhere(
            (c) => c.uuid == Guid('0147ab2a-3987-4bb8-802b-315a664eadd6'));
        regulationUuid = service.characteristics.firstWhere(
            (c) => c.uuid == Guid('961d1cdd-028f-47d0-aa2a-e0095e387f55'));
        debugUuid = service.characteristics.firstWhere(
            (c) => c.uuid == Guid('838335a1-ff5a-4344-bfdf-38bf6730de26'));
        workUuid = service.characteristics.firstWhere(
            (c) => c.uuid == Guid('6869fe94-c4a2-422a-ac41-b2a7a82803e9'));
      }
      lightUuid = service.characteristics.firstWhere(
          (c) => c.uuid == Guid('12d3c6a1-f86e-4d5b-89b5-22dc3f5c831f'));

      return Future.value(true);
    } catch (e, stackTrace) {
      print('Lcdtmbe $e $stackTrace');
      // handleManualError(e, stackTrace);

      return Future.value(false);
    }
  }
}

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});
  @override
  QRScanPageState createState() => QRScanPageState();
}

class QRScanPageState extends State<QRScanPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  AnimationController? animationController;
  bool flashOn = false;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    animation = Tween<double>(begin: 10, end: 350).animate(animationController!)
      ..addListener(() {
        setState(() {});
      });

    animationController!.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
          ),
          // Arriba
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Text('Escanea el QR',
                      style:
                          TextStyle(color: Color.fromARGB(255, 29, 163, 169))),
                )),
          ),
          // Abajo
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              color: Colors.black54,
            ),
          ),
          // Izquierda
          Positioned(
            top: 250,
            bottom: 250,
            left: 0,
            width: 50,
            child: Container(
              color: Colors.black54,
            ),
          ),
          // Derecha
          Positioned(
            top: 250,
            bottom: 250,
            right: 0,
            width: 50,
            child: Container(
              color: Colors.black54,
            ),
          ),
          // Área transparente con bordes redondeados
          Positioned(
            top: 250,
            left: 50,
            right: 50,
            bottom: 250,
            child: Stack(
              children: [
                Positioned(
                  top: animation.value,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    color: const Color.fromARGB(255, 29, 163, 169),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    color: const Color.fromARGB(255, 1, 18, 28),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    color: const Color.fromARGB(255, 1, 18, 28),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 3,
                    color: const Color.fromARGB(255, 1, 18, 28),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 3,
                    color: const Color.fromARGB(255, 1, 18, 28),
                  ),
                ),
              ],
            ),
          ),
          // Botón de Flash
          Positioned(
            bottom: 20,
            right: 20,
            child: IconButton(
              icon: Icon(
                flashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: () {
                controller?.toggleFlash();
                setState(() {
                  flashOn = !flashOn;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      Future.delayed(const Duration(milliseconds: 800), () {
        try {
          if (navigatorKey.currentState != null &&
              navigatorKey.currentState!.canPop()) {
            navigatorKey.currentState!.pop(scanData.code);
          }
        } catch (e, stackTrace) {
          print("Error: $e $stackTrace");
          showToast('Error al leer QR');
          // handleManualError(e, stackTrace);
        }
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    animationController?.dispose();
    super.dispose();
  }
}
