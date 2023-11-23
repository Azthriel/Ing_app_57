// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ing_config_app/regbank.dart';
import 'package:permission_handler/permission_handler.dart';
import 'master.dart';
import 'package:path_provider/path_provider.dart';

import 'device.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) async {
    String errorReport = generateErrorReport(details);
    final fileName = 'error_report_${DateTime.now().toIso8601String()}.txt';
    final directory = await getExternalStorageDirectory();
    if (directory != null) {
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(errorReport);
      sendReportOnWhatsApp(file.path);
    } else {
      print('Failed to get external storage directory');
    }
  };
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FlutterBluePlus.adapterState.listen((state) {
      if (state != BluetoothAdapterState.on) {
        if (!checkbleFlag){
          checkbleFlag = true;
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: const Text('Bluetooth apagado'),
                content: const Text('No se puede continuar sin Bluetooth'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      if (Platform.isAndroid) {
                        await FlutterBluePlus.turnOn();
                        checkbleFlag = false;
                        navigatorKey.currentState?.pop();
                      } else {
                        checkbleFlag = false;
                        navigatorKey.currentState?.pop();
                      }
                    },
                    child: const Text('Aceptar'),
                  ),
                ],
              );
            },
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Trillo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 1, 18, 28)),
        useMaterial3: true,
      ),
      initialRoute: '/perm',
      routes: {
        '/perm': (context) => const PermissionHandler(),
        '/regbank': (context) => Regbank(),
        '/loading': (context) => const LoadingPage(),
        '/device': (context) => const MyDeviceTabs(),
        '/disconect': (context) => const DisconectPage(),
      },
    );
  }
}

//PERMISOS //PRIMERA PARTE

class PermissionHandler extends StatefulWidget {
  const PermissionHandler({Key? key}) : super(key: key);

  @override
  PermissionHandlerState createState() => PermissionHandlerState();
}

class PermissionHandlerState extends State<PermissionHandler> {
  Future<Widget> permissionCheck() async {
    var permissionStatus1 = await Permission.bluetoothConnect.request();

    if (!permissionStatus1.isGranted) {
      await Permission.bluetoothConnect.request();
    }
    permissionStatus1 = await Permission.bluetoothConnect.status;

    var permissionStatus2 = await Permission.bluetoothScan.request();

    if (!permissionStatus2.isGranted) {
      await Permission.bluetoothScan.request();
    }
    permissionStatus2 = await Permission.bluetoothScan.status;

    var permissionStatus3 = await Permission.location.request();

    if (!permissionStatus3.isGranted) {
      await Permission.location.request();
    }
    permissionStatus3 = await Permission.location.status;

    PermissionStatus permissionStatus4 = await Permission.storage.request();
    if (!permissionStatus4.isGranted) {
      await Permission.storage.request();
    }
    permissionStatus4 = await Permission.storage.status;

    if (permissionStatus1.isGranted &&
        permissionStatus2.isGranted &&
        permissionStatus3.isGranted &&
        permissionStatus4.isGranted) {
      return Regbank();
    } else {
      return AlertDialog(
        title: const Text('Permisos requeridos'),
        content: const Text(
            'No se puede seguir sin los permisos\n Por favor activalos manualmente'),
        actions: [
          TextButton(
            child: const Text('Open App Settings'),
            onPressed: () => openAppSettings(),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${snapshot.error} occured',
                style: const TextStyle(fontSize: 18),
              ),
            );
          } else {
            return snapshot.data as Widget;
          }
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      future: permissionCheck(),
    );
  }
}
