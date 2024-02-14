// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'master.dart';

class MyDeviceTabs extends StatefulWidget {
  const MyDeviceTabs({super.key});
  @override
  MyDeviceTabsState createState() => MyDeviceTabsState();
}

class MyDeviceTabsState extends State<MyDeviceTabs> {
  @override
  initState() {
    super.initState();
    updateWifiValues(toolsValues);
    subscribeToWifiStatus();
  }

  void updateWifiValues(List<int> data) {
    var fun =
        utf8.decode(data); //Wifi status | wifi ssid | ble status | nickname
    fun = fun.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    print(fun);
    var parts = fun.split(':');
    if (parts[0] == 'WCS_CONNECTED' || parts[0] == '1') {
      nameOfWifi = parts[1];
      isWifiConnected = true;
      print('sis $isWifiConnected');
      setState(() {
        textState = 'CONECTADO';
        statusColor = Colors.green;
        wifiIcon = Icons.wifi;
      });
    } else if (parts[0] == 'WCS_DISCONNECTED' || parts[0] == '0') {
      isWifiConnected = false;
      print('non $isWifiConnected');

      setState(() {
        textState = 'DESCONECTADO';
        statusColor = Colors.red;
        wifiIcon = Icons.wifi_off;
      });

      if (parts[0] == 'WCS_DISCONNECTED' && atemp == true) {
        //If comes from subscription, parts[1] = reason of error.
        setState(() {
          wifiIcon = Icons.warning_amber_rounded;
        });

        if (parts[1] == '202' || parts[1] == '15') {
          errorMessage = 'Contraseña incorrecta';
        } else if (parts[1] == '201') {
          errorMessage = 'La red especificada no existe';
        } else if (parts[1] == '1') {
          errorMessage = 'Error desconocido';
        } else {
          errorMessage = parts[1];
        }

        errorSintax = getWifiErrorSintax(int.parse(parts[1]));
      }
    }

    setState(() {});
  }

  void subscribeToWifiStatus() async {
    print('Se subscribio a wifi');
    await myDevice.toolsUuid.setNotifyValue(true);

    final wifiSub =
        myDevice.toolsUuid.onValueReceived.listen((List<int> status) {
      updateWifiValues(status);
    });

    myDevice.device.cancelWhenDisconnected(wifiSub);
  }

//!Visual

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 29, 163, 169)),
        useMaterial3: true,
      ),
      home: DefaultTabController(
        length: factoryMode ? 6 : 3,
        child: Scaffold(
          appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 29, 163, 169),
              foregroundColor: const Color.fromARGB(255, 255, 255, 255),
              title: Text(deviceName),
              bottom: TabBar(
                tabs: [
                  const Tab(icon: Icon(Icons.numbers)),
                  if (factoryMode) ...[
                    const Tab(icon: Icon(Icons.settings)),
                    const Tab(icon: Icon(Icons.tune)),
                    const Tab(icon: Icon(Icons.stars_rounded)),
                  ],
                  const Tab(icon: Icon(Icons.lightbulb_sharp)),
                  const Tab(icon: Icon(Icons.send)),
                ],
                labelColor: Colors.white,
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(
                    wifiIcon,
                    size: 24.0,
                    semanticLabel: 'Icono de wifi',
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Row(children: [
                            const Text.rich(TextSpan(
                                text: 'Estado de conexión:',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ))),
                            Text.rich(TextSpan(
                                text: textState,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)))
                          ]),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text.rich(TextSpan(
                                    text: 'Error: $errorMessage',
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ))),
                                const SizedBox(height: 10),
                                Text.rich(TextSpan(
                                    text: 'Sintax: $errorSintax',
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ))),
                                const SizedBox(height: 10),
                                Row(children: [
                                  const Text.rich(TextSpan(
                                      text: 'Red actual: ',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold))),
                                  Text.rich(TextSpan(
                                      text: nameOfWifi,
                                      style: const TextStyle(
                                          color:
                                              Color.fromARGB(255, 29, 163, 169),
                                          fontSize: 20))),
                                ]),
                                const SizedBox(height: 10),
                                const Text.rich(TextSpan(
                                    text: 'Ingrese los datos de WiFi',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold))),
                                IconButton(
                                  icon: const Icon(Icons.qr_code,
                                      color: Color.fromARGB(255, 29, 163, 169)),
                                  iconSize: 50,
                                  onPressed: () async {
                                    PermissionStatus permissionStatusC =
                                        await Permission.camera.request();
                                    if (!permissionStatusC.isGranted) {
                                      await Permission.camera.request();
                                    }
                                    permissionStatusC =
                                        await Permission.camera.status;
                                    if (permissionStatusC.isGranted) {
                                      openQRScanner(
                                          navigatorKey.currentContext!);
                                    }
                                  },
                                ),
                                TextField(
                                  decoration: const InputDecoration(
                                      hintText: 'Nombre de la red'),
                                  onChanged: (value) {
                                    wifiName = value;
                                  },
                                ),
                                TextField(
                                  decoration: const InputDecoration(
                                      hintText: 'Contraseña'),
                                  obscureText: true,
                                  onChanged: (value) {
                                    wifiPassword = value;
                                  },
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Cancelar'),
                              onPressed: () {
                                navigatorKey.currentState?.pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Aceptar'),
                              onPressed: () {
                                sendWifitoBle();
                                navigatorKey.currentState?.pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
              leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                              content: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                  onPressed: () {
                                    var data = '57_IOT[4](1)';
                                    try {
                                      myDevice.toolsUuid.write(data.codeUnits,
                                          withoutResponse: false);
                                      print('a');
                                    } catch (e, stackTrace) {
                                      print('Fatal error 1 $e $stackTrace');
                                      showToast('Error al borrar NVS');
                                      // handleManualError(e, stackTrace);
                                    }
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Borrar NVS ESP')),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pushReplacementNamed(
                                        context, '/disconect');
                                  },
                                  child: const Text(
                                      'Desconectar todos los dispositivos')),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                  onPressed: () {
                                    pikachu.contains('Pika');
                                  },
                                  child: const Text('Crashear app')),
                            ],
                          ));
                        });
                  })),
          body: TabBarView(
            children: [
              const CharPage(),
              if (factoryMode) ...[
                const CalibrationPage(),
                const RegulationPage(),
                const DebugPage(),
              ],
              const ControlPage(),
              const OTAPage(),
            ],
          ),
        ),
      ),
    );
  }
}

// CARACTERISTICAS //ANOTHER PAGE

class CharPage extends StatefulWidget {
  const CharPage({super.key});
  @override
  CharState createState() => CharState();
}

class CharState extends State<CharPage> {
  String dataToshow = '';
  var parts = utf8.decode(infoValues).split(':');
  late String serialNumber;
  late String versionNumber;
  late String hardNumber;
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    serialNumber = parts[1]; // Serial Number
    versionNumber = parts[2]; // Soft Version Number
    hardNumber = parts[3]; // Hard Version Number
  }

  void sendDataToDevice() async {
    String dataToSend = textController.text;
    try {
      String data = '57_IOT[5]($dataToSend)';
      await myDevice.toolsUuid.write(data.codeUnits);
    } //57_IOT[5]($dataToSend)
    catch (e, stackTrace) {
      print('Error al enviar el numero de serie $e $stackTrace');
      showToast('Error al cambiar el número de serie');
      // handleManualError(e, stackTrace);
    }
    navigatorKey.currentState?.pushReplacementNamed('/regbank');
  }

//! Visual
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          print('POPIE');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    Container(
                        margin: const EdgeInsets.only(left: 15),
                        child: const Text("Desconectando...")),
                  ],
                ),
              );
            },
          );
          Future.delayed(const Duration(seconds: 2), () async {
            print('aca estoy');
            await myDevice.device.disconnect();
            navigatorKey.currentState?.pop();
            navigatorKey.currentState?.pushReplacementNamed('/regbank');
          });

          return; // Retorna según la lógica de tu app
        },
        child: Scaffold(
          backgroundColor: const Color.fromARGB(255, 1, 18, 28),
          body: SingleChildScrollView(
              child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Text.rich(
                  TextSpan(
                      text: 'Número de serie:',
                      style: (TextStyle(
                          fontSize: 20.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold))),
                ),
                Text.rich(
                  TextSpan(
                      text: serialNumber,
                      style: (const TextStyle(
                          fontSize: 30.0,
                          color: Color.fromARGB(255, 29, 163, 169),
                          fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 100),
                if (factoryMode) ...[
                  SizedBox(
                      width: 300,
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        controller: textController,
                        decoration: const InputDecoration(
                          labelText: 'Introducir nuevo numero de serie',
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      )),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => sendDataToDevice(),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 29, 163, 169)),
                      foregroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 255, 255, 255)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                    ),
                    child: const Text('Enviar'),
                  ),
                ],
                const SizedBox(height: 50),
                const Text.rich(
                  TextSpan(
                      text: 'Version de software del modulo IOT:',
                      style: (TextStyle(
                          fontSize: 20.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold))),
                ),
                Text.rich(
                  TextSpan(
                      text: versionNumber,
                      style: (const TextStyle(
                          fontSize: 20.0,
                          color: Color.fromARGB(255, 29, 163, 169),
                          fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 15),
                                const Text.rich(
                  TextSpan(
                      text: 'Version de hardware del modulo IOT:',
                      style: (TextStyle(
                          fontSize: 20.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold))),
                ),
                Text.rich(
                  TextSpan(
                      text: hardNumber,
                      style: (const TextStyle(
                          fontSize: 20.0,
                          color: Color.fromARGB(255, 29, 163, 169),
                          fontWeight: FontWeight.bold))),
                ),
                const SizedBox(height: 30),
                if (factoryMode) ...{
                  const Text.rich(
                    TextSpan(
                        text: 'Seleccionar el tipo de gas:',
                        style: (TextStyle(
                            fontSize: 20.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildButton(
                        onPressed: () =>
                            showToast('En un futuro lo agregaremos'),
                        text: 'Dual Gas',
                      ),
                      const SizedBox(width: 16),
                      buildButton(
                        onPressed: () =>
                            showToast('En un futuro lo agregaremos'),
                        text: 'CH4',
                      ),
                      const SizedBox(width: 16),
                      buildButton(
                        onPressed: () =>
                            showToast('En un futuro lo agregaremos'),
                        text: 'CO',
                      )
                    ],
                  )
                }
              ],
            ),
          )),
        ));
  }

  Widget buildButton({required VoidCallback onPressed, required String text}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
            const Color.fromARGB(255, 29, 163, 169)),
        foregroundColor: MaterialStateProperty.all<Color>(
            const Color.fromARGB(255, 255, 255, 255)),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      child: Text(text),
    );
  }
}

//CALIBRACION //ANOTHER PAGE

class CalibrationPage extends StatefulWidget {
  const CalibrationPage({super.key});
  @override
  CalibrationState createState() => CalibrationState();
}

class CalibrationState extends State<CalibrationPage> {
  final TextEditingController _setVccInputController = TextEditingController();
  final TextEditingController _setVrmsInputController = TextEditingController();
  final TextEditingController _setVrms02InputController =
      TextEditingController();

  Color _vrmsColor = const Color.fromARGB(255, 29, 163, 169);
  Color _vccColor = const Color.fromARGB(255, 29, 163, 169);
  Color rsColor = const Color.fromARGB(255, 29, 163, 169);
  Color rrcoColor = const Color.fromARGB(255, 29, 163, 169);

  List<int> _calValues = List<int>.filled(11, 0);
  int _vrms = 0;
  int _vcc = 0;
  int _vrmsOffset = 0;
  int _vrms02Offset = 0;
  int _vccOffset = 0;
  int tempMicro = 0;
  String rs = '';
  String rrco = '';
  int rsValue = 0;
  int rrcoValue = 0;
  bool rsInvalid = false;
  bool rrcoInvalid = false;
  bool rsOver35k = false;
  int ppmCO = 0;
  int ppmCH4 = 0;

  @override
  void initState() {
    super.initState();
    _calValues = calibrationValues;
    ppmCO = workValues[5] + workValues[6] << 8;
    ppmCH4 = workValues[7] + workValues[8] << 8;
    updateValues(_calValues);
    _subscribeToCalCharacteristic();
    _subscribeToWorkCharacteristic();
  }

  @override
  void dispose() {
    _setVccInputController.dispose();
    _setVrmsInputController.dispose();
    _setVrms02InputController.dispose();
    super.dispose();
  }

  void _setVcc(String newValue) {
    if (newValue.isEmpty) {
      print('STRING EMPTY');
      return;
    }

    print('changing VCC!');

    List<int> vccNewOffset = List<int>.filled(3, 0);
    vccNewOffset[0] = int.parse(newValue);
    vccNewOffset[1] = 0; // only 8 bytes value
    vccNewOffset[2] = 0; // calibration point: vcc

    try {
      myDevice.calibrationUuid.write(vccNewOffset);
    } catch (e, stackTrace) {
      print('Error al escribir vcc offset $e $stackTrace');
      showToast('Error al escribir vcc offset');
      // handleManualError(e, stackTrace);
    }

    setState(() {});
  }

  void _setVrms(String newValue) {
    if (newValue.isEmpty) {
      return;
    }

    List<int> vrmsNewOffset = List<int>.filled(3, 0);
    vrmsNewOffset[0] = int.parse(newValue);
    vrmsNewOffset[1] = 0; // only 8 bytes value
    vrmsNewOffset[2] = 1; // calibration point: vrms

    try {
      myDevice.calibrationUuid.write(vrmsNewOffset);
    } catch (e, stackTrace) {
      print('Error al setear vrms offset $e $stackTrace');
      showToast('Error al setear vrms offset');
      // handleManualError(e, stackTrace);
    }

    setState(() {});
  }

  void _setVrms02(String newValue) {
    if (newValue.isEmpty) {
      return;
    }

    List<int> vrms02NewOffset = List<int>.filled(3, 0);
    vrms02NewOffset[0] = int.parse(newValue);
    vrms02NewOffset[1] = 0; // only 8 bytes value
    vrms02NewOffset[2] = 2; // calibration point: vrms02

    try {
      myDevice.calibrationUuid.write(vrms02NewOffset);
    } catch (e, stackTrace) {
      print('Error al setear vrms offset $e $stackTrace');
      showToast('Error al setear vrms02 offset');
      // handleManualError(e, stackTrace);
    }

    setState(() {});
  }

  void updateValues(List<int> newValues) async {
    _calValues = newValues;
    print('Valores actualizados: $_calValues');

    if (_calValues.isNotEmpty) {
      _vccOffset = _calValues[0];
      _vrmsOffset = _calValues[1];
      _vrms02Offset = _calValues[2];

      _vcc = _calValues[3];
      _vcc += _calValues[4] << 8;
      print(_vcc);

      double adcPwm = _calValues[5].toDouble();
      adcPwm += _calValues[6] << 8;
      adcPwm *= 2.001955034213099;
      _vrms = adcPwm.toInt();
      print(_vrms);

      //

      if (_vcc >= 8000 || _vrms >= 2000) {
        _vcc = 0;
        _vrms = 0;
      }

      //

      if (_vcc > 5000) {
        _vccColor = Colors.red;
      } else {
        _vccColor = const Color.fromARGB(255, 29, 163, 169);
      }

      if (_vrms > 900) {
        _vrmsColor = Colors.red;
      } else {
        _vrmsColor = const Color.fromARGB(255, 29, 163, 169);
      }

      tempMicro = _calValues[7];
      rsValue = _calValues[8];
      rsValue += _calValues[9] << 8;

      rrcoValue = _calValues[10];
      rrcoValue = _calValues[11] << 8;

      if (rsValue >= 35000) {
        rsInvalid = true;
        rsOver35k = true;
        rsValue = 35000;
      } else {
        rsInvalid = false;
      }
      if (rsValue < 3500) {
        rsInvalid = true;
      } else {
        rsInvalid = false;
      }
      if (rrcoValue > 28000) {
        rrcoInvalid = false;
      } else {
        rrcoValue = 0;
        rrcoInvalid = true;
      }

      if (rsInvalid == true) {
        if (rsOver35k == true) {
          rs = '>35kΩ';
          rsColor = Colors.red;
        } else {
          rs = '<3.5kΩ';
          rsColor = Colors.red;
        }
      } else {
        var fun = rsValue / 1000;
        rs = '${fun}KΩ';
      }
      if (rrcoInvalid == true) {
        rrco = '<28kΩ';
        rrcoColor = Colors.red;
      } else {
        var fun = rrcoValue / 1000;
        rrco = '${fun}KΩ';
      }
    }

    setState(() {}); //reload the screen in each notification
  }

  void _subscribeToCalCharacteristic() async {
    if (!alreadySubCal) {
      await myDevice.calibrationUuid.setNotifyValue(true);
      alreadySubCal = true;
    }
    final calSub =
        myDevice.calibrationUuid.onValueReceived.listen((List<int> status) {
      updateValues(status);
    });

    myDevice.device.cancelWhenDisconnected(calSub);
  }

  void _subscribeToWorkCharacteristic() async {
    if (!alreadySubWork) {
      await myDevice.workUuid.setNotifyValue(true);
      alreadySubWork = true;
    }
    final workSub =
        myDevice.workUuid.onValueReceived.listen((List<int> status) {
      setState(() {
        ppmCO = status[5] + status[6] << 8;
        ppmCH4 = status[7] + status[8] << 8;
      });
    });

    myDevice.device.cancelWhenDisconnected(workSub);
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    Container(
                        margin: const EdgeInsets.only(left: 15),
                        child: const Text("Desconectando...")),
                  ],
                ),
              );
            },
          );
          Future.delayed(const Duration(seconds: 2), () async {
            print('aca estoy');
            await myDevice.device.disconnect();
            navigatorKey.currentState?.pop();
            navigatorKey.currentState?.pushReplacementNamed('/regbank');
          });

          return;
        },
        child: Scaffold(
          backgroundColor: const Color.fromARGB(255, 1, 18, 28),
          body: ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              Text('Valores de calibracion: $_calValues',
                  textScaler: const TextScaler.linear(1.2),
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 40),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '(C21) VCC:                          ',
                      style: TextStyle(
                        fontSize: 22.0,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: '$_vcc',
                      style: TextStyle(
                        fontSize: 24.0,
                        color: _vccColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' mV',
                      style: TextStyle(
                        fontSize: 22.0,
                        color: _vccColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    disabledActiveTrackColor: _vccColor,
                    disabledInactiveTrackColor:
                        const Color.fromARGB(255, 68, 89, 99),
                    trackHeight: 12,
                    thumbShape: SliderComponentShape.noThumb),
                child: Slider(
                  value: _vcc.toDouble(),
                  min: 0,
                  max: 8000,
                  onChanged: null,
                  onChangeStart: null,
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '(C21) VRMS:                          ',
                      style: TextStyle(
                        fontSize: 22.0,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: '$_vrms',
                      style: TextStyle(
                        fontSize: 24.0,
                        color: _vrmsColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' mV',
                      style: TextStyle(
                        fontSize: 22.0,
                        color: _vrmsColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    disabledActiveTrackColor: _vrmsColor,
                    disabledInactiveTrackColor:
                        const Color.fromARGB(255, 68, 89, 99),
                    trackHeight: 12,
                    thumbShape: SliderComponentShape.noThumb),
                child: Slider(
                  value: _vrms.toDouble(),
                  min: 0,
                  max: 2000,
                  onChanged: null,
                  onChangeStart: null,
                ),
              ),
              const SizedBox(height: 50),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '(C20) VCC Offset:                  ',
                      style: TextStyle(fontSize: 22.0, color: Colors.white),
                    ),
                    TextSpan(
                      text: '$_vccOffset ',
                      style: const TextStyle(
                          fontSize: 22.0,
                          color: Color.fromARGB(255, 29, 163, 169),
                          fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                        text: 'ADCU',
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Color.fromARGB(255, 29, 163, 169))),
                  ],
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.550,
                alignment: Alignment.bottomLeft,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  controller: _setVccInputController,
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      prefixText: '(0 - 255)  ',
                      prefixStyle: TextStyle(color: Colors.white),
                      hintText: 'Modificar VCC',
                      hintStyle: TextStyle(color: Colors.white)),
                  onSubmitted: (value) {
                    if (int.parse(value) <= 255 && int.parse(value) >= 0) {
                      _setVcc(value);
                    } else {
                      showToast('Valor ingresado invalido');
                    }
                    _setVccInputController.clear();
                  },
                ),
              ),
              const SizedBox(height: 40),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '(C21) VRMS Offset:            ',
                      style: TextStyle(fontSize: 22.0, color: Colors.white),
                    ),
                    TextSpan(
                      text: '$_vrmsOffset ',
                      style: const TextStyle(
                          fontSize: 22.0,
                          color: Color.fromARGB(255, 29, 163, 169),
                          fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                        text: 'ADCU',
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Color.fromARGB(255, 29, 163, 169))),
                  ],
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.550,
                alignment: Alignment.bottomLeft,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  controller: _setVrmsInputController,
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      prefixText: '(0 - 255)  ',
                      prefixStyle: TextStyle(color: Colors.white),
                      hintText: 'Modificar VRMS',
                      hintStyle: TextStyle(color: Colors.white)),
                  onSubmitted: (value) {
                    if (int.parse(value) <= 255 && int.parse(value) >= 0) {
                      _setVrms(value);
                    } else {
                      showToast('Valor ingresado invalido');
                    }
                    _setVrmsInputController.clear();
                  },
                ),
              ),
              const SizedBox(height: 40),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '(C97) VRMS02 Offset:            ',
                      style: TextStyle(fontSize: 22.0, color: Colors.white),
                    ),
                    TextSpan(
                      text: '$_vrms02Offset ',
                      style: const TextStyle(
                          fontSize: 22.0,
                          color: Color.fromARGB(255, 29, 163, 169),
                          fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                        text: 'ADCU',
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Color.fromARGB(255, 29, 163, 169))),
                  ],
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.550,
                alignment: Alignment.bottomLeft,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  controller: _setVrms02InputController,
                  decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      prefixText: '(0 - 255)  ',
                      prefixStyle: TextStyle(color: Colors.white),
                      hintText: 'Modificar VRMS',
                      hintStyle: TextStyle(color: Colors.white)),
                  onSubmitted: (value) {
                    if (int.parse(value) <= 255 && int.parse(value) >= 0) {
                      _setVrms02(value);
                    } else {
                      showToast('Valor ingresado invalido');
                    }
                    _setVrms02InputController.clear();
                  },
                ),
              ),
              const SizedBox(height: 70),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Resistencia del sensor en GAS: ',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: rs,
                      style: TextStyle(
                        fontSize: 24.0,
                        color: rsColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    disabledActiveTrackColor: rsColor,
                    disabledInactiveTrackColor:
                        const Color.fromARGB(255, 68, 89, 99),
                    trackHeight: 12,
                    thumbShape: SliderComponentShape.noThumb),
                child: Slider(
                  value: rsValue.toDouble(),
                  min: 0,
                  max: 35000,
                  onChanged: null,
                  onChangeStart: null,
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Resistencia de sensor en monoxido: ',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: rrco,
                      style: TextStyle(
                        fontSize: 24.0,
                        color: rrcoColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    disabledActiveTrackColor: rrcoColor,
                    disabledInactiveTrackColor:
                        const Color.fromARGB(255, 68, 89, 99),
                    trackHeight: 12,
                    thumbShape: SliderComponentShape.noThumb),
                child: Slider(
                  value: rrcoValue.toDouble(),
                  min: 0,
                  max: 100000,
                  onChanged: null,
                  onChangeStart: null,
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Temperatura del micro: ',
                      style: TextStyle(
                        fontSize: 22.0,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: tempMicro.toString(),
                      style: const TextStyle(
                        fontSize: 24.0,
                        color: Color.fromARGB(255, 29, 163, 169),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: '°C',
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Color.fromARGB(255, 29, 163, 169),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text.rich(TextSpan(children: [
                const TextSpan(
                  text: 'PPM CO: ',
                  style: TextStyle(
                    fontSize: 22.0,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: '$ppmCO',
                  style: const TextStyle(
                    fontSize: 24.0,
                    color: Color.fromARGB(255, 29, 163, 169),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ])),
              const SizedBox(height: 20),
              Text.rich(TextSpan(children: [
                const TextSpan(
                  text: 'PPM CH4: ',
                  style: TextStyle(
                    fontSize: 22.0,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: '$ppmCH4',
                  style: const TextStyle(
                    fontSize: 24.0,
                    color: Color.fromARGB(255, 29, 163, 169),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ])),
              const SizedBox(height: 50),
            ],
          ),
        ));
  }
}

//REGULATION //ANOTHER PAGE

class RegulationPage extends StatefulWidget {
  const RegulationPage({super.key});
  @override
  RegulationState createState() => RegulationState();
}

class RegulationState extends State<RegulationPage> {
  List<String> valores = [];
  final ScrollController _scrollController = ScrollController();
  late List<int> value;
  bool regulationDone = false;

  @override
  void initState() {
    super.initState();
    value = regulationValues;
    _readValues();
    _subscribeValue();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _readValues() {
    setState(() {
      for (int i = 0; i < 10; i += 2) {
        print('i = $i');
        int datas = value[i] + (value[i + 1] << 8);
        valores.add(datas.toString());
      }
      for (int j = 10; j < 15; j++) {
        print('j = $j');
        valores.add(value[j].toString());
      }
      for (int k = 15; k < 29; k += 2) {
        print('k = $k');
        int dataj = value[k] + (value[k + 1] << 8);
        valores.add(dataj.toString());
      }

      if (value[29] == 0) {
        regulationDone = false;
      } else if (value[29] == 1) {
        regulationDone = true;
      }
    });
  }

  void _subscribeValue() async {
    if (!alreadySubReg) {
      await myDevice.regulationUuid.setNotifyValue(true);
      alreadySubReg = true;
    }
    print('Me turbosuscribi a regulacion');
    final regSub =
        myDevice.regulationUuid.onValueReceived.listen((List<int> status) {
      updateValues(status);
    });

    myDevice.device.cancelWhenDisconnected(regSub);
  }

  void updateValues(List<int> data) {
    valores.clear();
    print('Entro: $data');
    setState(() {
      for (int i = 0; i < 10; i += 2) {
        int datas = value[i] + (value[i + 1] << 8);
        valores.add(datas.toString());
      }
      for (int j = 10; j < 15; j++) {
        valores.add(value[j].toString());
      }
      for (int k = 15; k < 29; k += 2) {
        int dataj = value[k] + (value[k + 1] << 8);
        valores.add(dataj.toString());
      }

      if (value[29] == 0) {
        regulationDone = false;
      } else if (value[29] == 1) {
        regulationDone = true;
      }
    });
  }

  String textToShow(int index) {
    switch (index) {
      case 0:
        return 'Resistencia del sensor en gas a 20 grados';
      case 1:
        return 'Resistencia del sensor en gas a 30 grados';
      case 2:
        return 'Resistencia del sensor en gas a 40 grados';
      case 3:
        return 'Resistencia del sensor en gas a 50 grados';
      case 4:
        return 'Resistencia del sensor en gas a x grados';
      case 5:
        return 'Corrector de temperatura a 20 grados';
      case 6:
        return 'Corrector de temperatura a 30 grados';
      case 7:
        return 'Corrector de temperatura a 40 grados';
      case 8:
        return 'Corrector de temperatura a 50 grados';
      case 9:
        return 'Corrector de temperatura a x grados';
      case 10:
        return 'Resistencia de sensor en monoxido a 20 grados';
      case 11:
        return 'Resistencia de sensor en monoxido a 30 grados';
      case 12:
        return 'Resistencia de sensor en monoxido a 40 grados';
      case 13:
        return 'Resistencia de sensor en monoxido a 50 grados';
      case 14:
        return 'Resistencia de sensor en monoxido a x grados';
      case 15:
        return 'Resistencia del sensor de CH4 en aire limpio';
      case 16:
        return 'Resistencia del sensor de CO en aire limpio';
      default:
        return 'Error inesperado';
    }
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    Container(
                        margin: const EdgeInsets.only(left: 15),
                        child: const Text("Desconectando...")),
                  ],
                ),
              );
            },
          );
          Future.delayed(const Duration(seconds: 2), () async {
            print('aca estoy');
            await myDevice.device.disconnect();
            navigatorKey.currentState?.pop();
            navigatorKey.currentState?.pushReplacementNamed('/regbank');
          });

          return; // Retorna según la lógica de tu app
        },
        child: Center(
          child: Scaffold(
              backgroundColor: const Color.fromARGB(255, 1, 18, 28),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Row(children: [
                    const SizedBox(width: 15),
                    const Text('Regulación completada:',
                        style: TextStyle(color: Colors.white, fontSize: 22.0)),
                    const SizedBox(width: 40),
                    regulationDone
                        ? const Text('SI',
                            style: TextStyle(
                                color: Color.fromARGB(255, 29, 163, 169),
                                fontSize: 22.0,
                                fontWeight: FontWeight.bold))
                        : const Text('NO',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 22.0,
                                fontWeight: FontWeight.bold))
                  ]),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: valores.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(textToShow(index),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                          subtitle: Text(valores[index],
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 29, 163, 169),
                                  fontSize: 30)),
                        );
                      },
                    ),
                  )
                ],
              )),
        ));
  }
}

//CONTROL //ANOTHER PAGE

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});
  @override
  ControlPageState createState() => ControlPageState();
}

class ControlPageState extends State<ControlPage> {
  double _sliderValue = 100.0;

  @override
  void initState() {
    super.initState();
    try {
      String data = '57_IOT[7](0)';
      myDevice.toolsUuid.write(data.codeUnits);
    } catch (e, stackTrace) {
      print('Error al cortar el loop $e $stackTrace');
      // handleManualError(e, stackTrace);
    }
  }

  void _sendValueToBle(int value) async {
    try {
      final data = [value];
      myDevice.lightUuid.write(data, withoutResponse: true);
    } catch (e, stackTrace) {
      print('Error al mandar el valor del brillo $e $stackTrace');
      // handleManualError(e, stackTrace);
    }
  }

  void goodbye() async {
    try {
      String data = '57_IOT[7](1)';
      await myDevice.toolsUuid.write(data.codeUnits);
    } catch (e, stackTrace) {
      print('Error al volver al loop $e $stackTrace');
      // handleManualError(e, stackTrace);
    }
  }

  @override
  void dispose() {
    goodbye();
    super.dispose();
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    Container(
                        margin: const EdgeInsets.only(left: 15),
                        child: const Text("Desconectando...")),
                  ],
                ),
              );
            },
          );
          Future.delayed(const Duration(seconds: 2), () async {
            print('aca estoy');
            await myDevice.device.disconnect();
            navigatorKey.currentState?.pop();
            navigatorKey.currentState?.pushReplacementNamed('/regbank');
          });

          return; // Retorna según la lógica de tu app
        },
        child: Scaffold(
            backgroundColor: const Color.fromARGB(255, 1, 18, 28),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 200,
                    color: Colors.yellow.withOpacity(_sliderValue / 100),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  _buildCustomSlider(),
                  const SizedBox(
                    height: 30,
                  ),
                  Text(
                    'Valor del brillo: ${_sliderValue.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 20.0, color: Colors.white),
                  ),
                ],
              ),
            )));
  }

  Widget _buildCustomSlider() {
    return SizedBox(
      width: 300,
      height: 30,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: const Color.fromARGB(255, 29, 163, 169),
          inactiveTrackColor: const Color.fromARGB(255, 255, 255, 255),
          trackHeight: 30.0,
          thumbColor: const Color.fromARGB(255, 29, 163, 169),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
          overlayColor: const Color.fromARGB(255, 29, 163, 169).withAlpha(32),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 0.0),
        ),
        child: Slider(
          value: _sliderValue,
          min: 0.0,
          max: 100.0,
          onChanged: (double value) {
            setState(() {
              _sliderValue = value;
            });
            _sendValueToBle(_sliderValue.toInt());
          },
        ),
      ),
    );
  }
}

//OTA //ANOTHER PAGE

class OTAPage extends StatefulWidget {
  const OTAPage({super.key});
  @override
  OTAState createState() => OTAState();
}

class OTAState extends State<OTAPage> {
  var dataReceive = [];
  var dataToShow = 0;
  var progressValue = 0.0;
  var picprogressValue = 0.0;
  var writingprogressValue = 0.0;
  var picwritingprogressValue = 0.0;
  late Uint8List firmwareGlobal;
  bool sizeWasSend = false;
  bool otaPIC = false;

  @override
  void initState() {
    super.initState();
    stopLoop();
    subToProgress();
  }

  void stopLoop() {
    try {
      String data = '57_IOT[7](0)';
      myDevice.toolsUuid.write(data.codeUnits);
    } catch (e, stackTrace) {
      print('Error al cortar el loop $e $stackTrace');
      // handleManualError(e, stackTrace);
    }
  }

  void sendOTAWifi(int value) async {
    String url = '';
    if (value == 0) {
      //ota factory
      url =
          'https://raw.githubusercontent.com/CrisDores/57_IOT_PUBLIC/main/57_ota_factory_fw/firmware.bin';
    } else if (value == 1) {
      //ota work
      url =
          'https://raw.githubusercontent.com/CrisDores/57_IOT_PUBLIC/main/57_ota_fw/firmware.bin';
    } else if (value == 2) {
      //ota test
      url =
          'https://raw.githubusercontent.com/CrisDores/57_IOT_PUBLIC/main/test_zone/firmware.bin';
    } else if (value == 3) {
      //ota pic
      url =
          'https://raw.githubusercontent.com/CrisDores/57_IOT_PUBLIC/main/57_ota_factory_fw/firmware.hex';
      otaPIC = true;
    }

    if (otaPIC == true) {
      try {
        String data = '57_IOT[9]($url)';
        await myDevice.toolsUuid.write(data.codeUnits);
        print('Me puse corte re kawaii');
      } catch (e, stackTrace) {
        print('Error al enviar la OTA $e $stackTrace');
        // handleManualError(e, stackTrace);
        showToast('Error al enviar OTA');
      }
      showToast('Enviando OTA PIC...');
    } else {
      try {
        String data = '57_IOT[8]($url)';
        await myDevice.toolsUuid.write(data.codeUnits);
        print('Si mandé ota');
      } catch (e, stackTrace) {
        print('Error al enviar la OTA $e $stackTrace');
        // handleManualError(e, stackTrace);
        showToast('Error al enviar OTA');
      }
      showToast('Enviando OTA WiFi...');
    }
  }

  void sendOTABLE(int value) async {
    String data = '57_IOT[7](0)';
    myDevice.toolsUuid.write(data.codeUnits);
    showToast("Enviando OTA...");

    String url = '';
    if (value == 0) {
      url =
          'https://raw.githubusercontent.com/CrisDores/57_IOT_PUBLIC/main/57_ota_factory_fw/firmware.bin';
    } else if (value == 1) {
      url =
          'https://raw.githubusercontent.com/CrisDores/57_IOT_PUBLIC/main/57_ota_fw/firmware.bin';
    }

    if (sizeWasSend == false) {
      try {
        String dir = (await getApplicationDocumentsDirectory()).path;
        File file = File('$dir/firmware.bin');

        if (await file.exists()) {
          await file.delete();
        }

        var req = await dio.get(url);
        var bytes = req.data;

        await file.writeAsBytes(bytes);

        var firmware = await file.readAsBytes();
        firmwareGlobal = firmware;

        int size = firmware.length;

        var sizeInBytes = [
          size & 0xFF,
          (size >> 8) & 0xFF,
          (size >> 16) & 0xFF,
          (size >> 24) & 0xFF
        ];

        await myDevice.infoUuid.write(sizeInBytes, withoutResponse: false);
        sizeWasSend = true;

        sendchunk();
      } catch (e, stackTrace) {
        print('Error al enviar la OTA $e $stackTrace');
        // handleManualError(e, stackTrace);
        showToast("Error al enviar OTA");
      }
    }
  }

  void sendchunk() async {
    try {
      int mtuSize = 255;
      await writeLarge(firmwareGlobal, mtuSize);
    } catch (e, stackTrace) {
      print('El error es: $e $stackTrace');
      showToast('Error al enviar chunk');
      // handleManualError(e, stackTrace);
    }
  }

  Future<void> writeLarge(List<int> value, int mtu, {int timeout = 15}) async {
    int chunk = mtu - 3;
    for (int i = 0; i < value.length; i += chunk) {
      print('Mande chunk');
      List<int> subvalue = value.sublist(i, min(i + chunk, value.length));
      await myDevice.infoUuid.write(subvalue, withoutResponse: false);
    }
  }

  void subToProgress() async {
    print('Entre aquis mismito');
    if (!alreadySubOta) {
      await myDevice.otaUuid.setNotifyValue(true);
      alreadySubOta = true;
    }
    final otaSub = myDevice.otaUuid.onValueReceived.listen((event) {
      try {
        var fun = utf8.decode(event);
        fun = fun.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
        var parts = fun.split(':');
        if (parts[0] == '57_IOT_OTAPR') {
          print('Se recibio');
          setState(() {
            if (otaPIC == true) {
              picprogressValue = int.parse(parts[1]) / 100;
            } else {
              progressValue = int.parse(parts[1]) / 100;
            }
          });
          print('Progreso: ${parts[1]}');
        } else {
          switch (fun) {
            case '57_IOT_OTA:START':
              print('Header se recibio correctamente');
              break;
            case '57_IOT_OTA:SUCCESS':
              sizeWasSend = false;
              if (otaPIC == true) {
                otaPIC = false;
              } else {
                print('Estreptococo');
                String data = '57_IOT[7](1)';
                myDevice.toolsUuid.write(data.codeUnits);
                navigatorKey.currentState?.pushReplacementNamed('/regbank');
              }
              showToast("OTA completada exitosamente");
              break;
            case '57_IOT_OTA:FAIL':
              showToast("Fallo al enviar OTA");
              break;
            case '57_IOT_OTA:OVERSIZE':
              showToast("El archivo es mayor al espacio reservado");
              break;
            case '57_IOT_OTA:WIFI_LOST':
              showToast("Se perdió la conexión wifi");
              break;
            case '57_IOT_OTA:HTTP_LOST':
              showToast("Se perdió la conexión HTTP durante la actualización");
              break;
            case '57_IOT_OTA:STREAM_LOST':
              showToast("Excepción de stream durante la actualización");
              break;
            case '57_IOT_OTA:NO_WIFI':
              showToast("Dispositivo no conectado a una red Wifi");
              break;
            case '57_IOT_OTA_HTTP:FAIL':
              showToast("No se pudo iniciar una peticion HTTP");
              break;
            case '57_IOT_OTA:NO_ROLLBACK':
              showToast("Imposible realizar un rollback");
              break;
            default:
              break;
          }
        }
      } catch (e, stackTrace) {
        print('Error malevolo: $e $stackTrace');
        // handleManualError(e, stackTrace);
        // showToast('Error al actualizar progreso');
      }
    });
    myDevice.device.cancelWhenDisconnected(otaSub);
  }

  void goodbye() async {
    try {
      String data = '57_IOT[7](1)';
      await myDevice.toolsUuid.write(data.codeUnits);
    } catch (e, stackTrace) {
      print('Error al volver al loop $e $stackTrace');
      // handleManualError(e, stackTrace);
    }
  }

  @override
  void dispose() {
    goodbye();
    otaPIC = false;
    atemp = false;
    super.dispose();
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  Container(
                      margin: const EdgeInsets.only(left: 15),
                      child: const Text("Desconectando...")),
                ],
              ),
            );
          },
        );
        Future.delayed(const Duration(seconds: 2), () async {
          print('aca estoy');
          await myDevice.device.disconnect();
          navigatorKey.currentState?.pop();
          navigatorKey.currentState?.pushReplacementNamed('/regbank');
        });

        return; // Retorna según la lógica de tu app
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 1, 18, 28),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 40,
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(255, 68, 89, 99),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: picprogressValue,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color.fromARGB(255, 29, 163, 169)),
                      ),
                    ),
                  ),
                  Text(
                    'Progreso descarga OTA PIC: ${(picprogressValue * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 40,
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(255, 68, 89, 99),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: picwritingprogressValue,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color.fromARGB(255, 29, 163, 169)),
                      ),
                    ),
                  ),
                  Text(
                    'Progreso escritura OTA PIC: ${(picwritingprogressValue * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 40,
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(255, 68, 89, 99),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color.fromARGB(255, 29, 163, 169)),
                      ),
                    ),
                  ),
                  Text(
                    'Progreso descarga OTA ESP: ${(progressValue * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 40,
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(255, 68, 89, 99),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: writingprogressValue,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color.fromARGB(255, 29, 163, 169)),
                      ),
                    ),
                  ),
                  Text(
                    'Progreso escritura OTA ESP: ${(writingprogressValue * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => sendOTAWifi(1),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 29, 163, 169)),
                          foregroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 255, 255, 255)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.build,
                                      size: 16,
                                      color:
                                          Color.fromARGB(255, 255, 255, 255)),
                                  SizedBox(width: 20),
                                  Icon(Icons.wifi,
                                      size: 16,
                                      color:
                                          Color.fromARGB(255, 255, 255, 255)),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Mandar OTA trabajo(WiFi)',
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => sendOTAWifi(0),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 29, 163, 169)),
                          foregroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 255, 255, 255)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                          ),
                        ),
                        child: const Center(
                          // Added to center elements
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.factory_outlined,
                                        size: 15,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255)),
                                    SizedBox(width: 20),
                                    Icon(Icons.wifi,
                                        size: 15,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255)),
                                  ]),
                              SizedBox(height: 10),
                              Text(
                                'Mandar OTA fabrica (WiFi)',
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => sendOTABLE(1),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 29, 163, 169)),
                          foregroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 255, 255, 255)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                          ),
                        ),
                        child: const Center(
                          // Added to center elements
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.build,
                                        size: 16,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255)),
                                    SizedBox(width: 20),
                                    Icon(Icons.bluetooth,
                                        size: 16,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255)),
                                    SizedBox(height: 10),
                                  ]),
                              SizedBox(height: 10),
                              Text(
                                'Mandar OTA trabajo (BLE)',
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => sendOTABLE(0),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 29, 163, 169)),
                          foregroundColor: MaterialStateProperty.all<Color>(
                              const Color.fromARGB(255, 255, 255, 255)),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ),
                          ),
                        ),
                        child: const Center(
                          // Added to center elements
                          child: Column(
                            children: [
                              SizedBox(height: 10),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.factory_outlined,
                                        size: 15,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255)),
                                    SizedBox(width: 20),
                                    Icon(Icons.bluetooth,
                                        size: 15,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255)),
                                  ]),
                              SizedBox(height: 10),
                              Text(
                                'Mandar OTA fabrica (BLE)',
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: () {
                    otaPIC = true;
                    sendOTAWifi(3);
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 29, 163, 169)),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 255, 255, 255)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.memory,
                                  size: 15,
                                  color: Color.fromARGB(255, 255, 255, 255)),
                              SizedBox(width: 20),
                              Icon(Icons.wifi,
                                  size: 15,
                                  color: Color.fromARGB(255, 255, 255, 255)),
                            ]),
                        SizedBox(height: 10),
                        Text(
                          'Mandar OTA PIC',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

//DEBUG //ANOTHER PAGE

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});
  @override
  DebugState createState() => DebugState();
}

class DebugState extends State<DebugPage> {
  List<String> debug = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    updateDebugValues(debugValues);
    _subscribeDebug();
  }

  void updateDebugValues(List<int> values) {
    debug.clear();
    print('Aqui esta esto: $values');

    setState(() {
      for (int i = 0; i < values.length; i += 2) {
        int datas = values[i] + (values[i + 1] << 8);
        debug.add(datas.toString());
      }
    });
  }

  void _subscribeDebug() async {
    if (!alreadySubDebug) {
      await myDevice.debugUuid.setNotifyValue(true);
      alreadySubDebug = true;
    }
    print('Me turbosuscribi a regulacion');
    final debugSub =
        myDevice.debugUuid.onValueReceived.listen((List<int> status) {
      updateDebugValues(status);
    });

    myDevice.device.cancelWhenDisconnected(debugSub);
  }

  String _textToShow(int num) {
    switch (num + 1) {
      case 1:
        return 'Gasout: ';
      case 2:
        return 'Gasout estable CH4: ';
      case 3:
        return 'Gasout estable CO: ';
      case 4:
        return 'VCC: ';
      case 5:
        return 'VCC estable: ';
      case 6:
        return 'Temperatura: ';
      case 7:
        return 'Temperatura estable: ';
      case 8:
        return 'PWM Rising point: ';
      case 9:
        return 'PWM Falling point: ';
      case 10:
        return 'PWM: ';
      case 11:
        return 'PWM estable: ';
      default:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    Container(
                        margin: const EdgeInsets.only(left: 15),
                        child: const Text("Desconectando...")),
                  ],
                ),
              );
            },
          );
          Future.delayed(const Duration(seconds: 2), () async {
            print('aca estoy');
            await myDevice.device.disconnect();
            navigatorKey.currentState?.pop();
            navigatorKey.currentState?.pushReplacementNamed('/regbank');
          });

          return;
        },
        child: Center(
          child: Scaffold(
              backgroundColor: const Color.fromARGB(255, 1, 18, 28),
              body: Column(
                children: [
                  const Text('Valores del PIC ADC',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 30)),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child: ListView.builder(
                        controller: _scrollController,
                        itemCount: debug.length,
                        itemBuilder: (context, index) {
                          return ListBody(children: [
                            Row(
                              children: [
                                Text(_textToShow(index),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)),
                                Text(debug[index],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color:
                                            Color.fromARGB(255, 29, 163, 169),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20)),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                  disabledActiveTrackColor:
                                      const Color.fromARGB(255, 29, 163, 169),
                                  disabledInactiveTrackColor:
                                      const Color.fromARGB(255, 68, 89, 99),
                                  trackHeight: 12,
                                  thumbShape: SliderComponentShape.noThumb),
                              child: Slider(
                                value: double.parse(debug[index]),
                                min: 0,
                                max: 1023,
                                onChanged: null,
                                onChangeStart: null,
                              ),
                            ),
                          ]);
                        }),
                  ),
                ],
              )),
        ));
  }
}

//*------------------------------------------SECONDARY SCREENS------------------------------------------*\\

//LOADING //ANOTHER PAGE

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});
  @override
  LoadState createState() => LoadState();
}

class LoadState extends State<LoadingPage> {
  MyDevice myDevice = MyDevice();

  @override
  void initState() {
    super.initState();
    print('HOSTIAAAAAAAAAAAAAAAAAAAAAAAA');
    precharge().then((precharge) {
      if (precharge == true) {
        showToast('Dispositivo conectado exitosamente');
        navigatorKey.currentState?.pushReplacementNamed('/device');
      } else {
        showToast('Error en el dispositivo, intente nuevamente');
        myDevice.device.disconnect();
      }
    });
  }

  Future<bool> precharge() async {
    try {
      await myDevice.device.requestMtu(255);

      if (factoryMode) {
        calibrationValues = await myDevice.calibrationUuid.read();
        regulationValues = await myDevice.regulationUuid.read();
        debugValues = await myDevice.debugUuid.read();
        workValues = await myDevice.workUuid.read();
      }
      toolsValues = await myDevice.toolsUuid.read();
      print('Valores calibracion: $calibrationValues');
      print('Valores regulacion: $regulationValues');
      print('Valores tools: $toolsValues');
      print('Valores debug: $debugValues');
      print('Valores trabajo: $workValues');

      return Future.value(true);
    } catch (e, stackTrace) {
      print('Error en la precarga $e $stackTrace');
      showToast('Error en la precarga');
      // handleManualError(e, stackTrace);
      return Future.value(false);
    }
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                Container(
                  margin: const EdgeInsets.only(left: 15),
                  child: const Text('Desconectando...'),
                ),
              ],
            ),
          ),
        ).then((_) {
          Future.delayed(const Duration(seconds: 2), () async {
            print('Yendome');
            await myDevice.device.disconnect();
            navigatorKey.currentState?.pop();
            navigatorKey.currentState?.pushReplacementNamed('/regbank');
          });
        });

        return;
      },
      child: const Scaffold(
        backgroundColor: Color.fromARGB(255, 1, 18, 28),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 29, 163, 169),
              ),
              SizedBox(height: 20),
              Text(
                'Cargando...',
                style: TextStyle(color: Color.fromARGB(255, 29, 163, 169)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//DISCONECT //ANOTHER PAGE

class DisconectPage extends StatefulWidget {
  const DisconectPage({super.key});
  @override
  DisconectState createState() => DisconectState();
}

class DisconectState extends State<DisconectPage> {
  MyDevice myDevice = MyDevice();
  @override
  void initState() {
    super.initState();
    disconect();
  }

  void disconect() async {
    try {
      Future.delayed(const Duration(seconds: 2), () {
        String data = '57_IOT[6](1)';
        myDevice.toolsUuid.write(data.codeUnits);
        showToast('Dispositivos desconectados exitosamente');
      });
    } catch (e, stackTrace) {
      print('Error al desconectar a todos los usuarios $e $stackTrace');
      // handleManualError(e, stackTrace);
    }
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: Color.fromARGB(255, 1, 18, 28),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color.fromARGB(255, 29, 163, 169),
            ),
            SizedBox(height: 20),
            Text('Desconectando...',
                style: TextStyle(color: Color.fromARGB(255, 29, 163, 169))),
          ],
        )));
  }
}
