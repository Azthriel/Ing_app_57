import 'dart:async';
import 'dart:io';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'master.dart';

class Regbank extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Regbank({super.key});

//!Visual
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Regulation Bank App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 29, 163, 169)),
        useMaterial3: true,
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 29, 163, 169),
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
            title: const Text('Configuración 57 IOT'),
            bottom: const TabBar(
              labelColor: Color.fromARGB(255, 255, 255, 255),
              unselectedLabelColor: Color.fromARGB(255, 1, 18, 28),
              indicatorColor: Color.fromARGB(255, 7, 135, 137),
              tabs: [
                Tab(icon: Icon(Icons.bluetooth_searching)),
                Tab(icon: Icon(Icons.assignment)),
                Tab(
                  icon: Icon(Icons.update),
                )
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ScanTab(),
              RegbankTab(),
              UpdateTab(),
            ],
          ),
        ),
      ),
    );
  }
}

//SCAN TAB //Scan and connection tab

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});
  @override
  ScanTabState createState() => ScanTabState();
}

class ScanTabState extends State<ScanTab> {
  List<BluetoothDevice> devices = [];
  List<BluetoothDevice> filteredDevices = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  late EasyRefreshController _controller;
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    filteredDevices = devices;
    _controller = EasyRefreshController(
      controlFinishRefresh: true,
    );
    scan();
  }

  void scan() async {
    if (bluetoothOn) {
      printLog('Entre a escanear');
      try {
        await FlutterBluePlus.startScan(
            withKeywords: ['Detector'],
            timeout: const Duration(seconds: 30),
            androidUsesFineLocation: true,
            continuousUpdates: false);
        FlutterBluePlus.scanResults.listen((results) {
          for (ScanResult result in results) {
            if (!devices
                .any((device) => device.remoteId == result.device.remoteId)) {
              setState(() {
                devices.add(result.device);
                devices
                    .sort((a, b) => a.platformName.compareTo(b.platformName));
                filteredDevices = devices;
              });
            }
          }
        });
      } catch (e, stackTrace) {
        printLog('Error al escanear $e $stackTrace');
        showToast('Error al escanear, intentelo nuevamente');
        // handleManualError(e, stackTrace);
      }
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 6));
      deviceName = device.platformName;
      myDeviceid = device.remoteId.toString();

      printLog('Teoricamente estoy conectado');

      MyDevice myDevice = MyDevice();

      device.connectionState.listen((BluetoothConnectionState state) {
        printLog('Estado de conexión: $state');
        switch (state) {
          case BluetoothConnectionState.disconnected:
            {
              showToast('Dispositivo desconectado');
              calibrationValues.clear();
              regulationValues.clear();
              toolsValues.clear();
              nameOfWifi = '';
              connectionFlag = false;
              alreadySubCal = false;
              alreadySubReg = false;
              alreadySubOta = false;
              alreadySubDebug = false;
              alreadySubWork = false;
              printLog(
                  'Razon: ${myDevice.device.disconnectReason?.description}');
              navigatorKey.currentState?.pushReplacementNamed('/regbank');
              break;
            }
          case BluetoothConnectionState.connected:
            {
              if (!connectionFlag) {
                connectionFlag = true;
                FlutterBluePlus.stopScan();
                myDevice.setup(device).then((valor) {
                  printLog('RETORNASHE $valor');
                  if (valor) {
                    navigatorKey.currentState?.pushReplacementNamed('/loading');
                  } else {
                    connectionFlag = false;
                    printLog('Fallo en el setup');
                    showToast('Error en el dispositivo, intente nuevamente');
                    myDevice.device.disconnect();
                  }
                });
              } else {
                printLog('Las chistosadas se apoderan del mundo');
              }
              break;
            }
          default:
            break;
        }
      });
    } catch (e, stackTrace) {
      if (e is FlutterBluePlusException && e.code == 133) {
        printLog('Error específico de Android con código 133: $e');
        showToast('Error de conexión, intentelo nuevamente');
      } else {
        printLog('Error al conectar: $e $stackTrace');
        showToast('Error al conectar, intentelo nuevamente');
        // handleManualError(e, stackTrace);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

//! Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 18, 28),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: TextField(
            focusNode: searchFocusNode,
            controller: searchController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              icon: Icon(Icons.search),
              iconColor: Colors.white,
              hintText: "Buscar dispositivo",
              hintStyle: TextStyle(color: Colors.white),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {
                filteredDevices = devices
                    .where((device) => device.platformName
                        .toLowerCase()
                        .contains(value.toLowerCase()))
                    .toList();
              });
            },
          )),
      body: EasyRefresh(
        controller: _controller,
        header: const ClassicHeader(
          dragText: 'Desliza para reescanear',
          armedText:
              'Suelta para reescanear\nO desliza para arriba para cancelar',
          readyText: 'Reescaneando dispositivos',
          processingText: 'Reescaneando dispositivos',
          processedText: 'Reescaneo completo',
          showMessage: false,
          textStyle: TextStyle(color: Color.fromARGB(255, 29, 163, 169)),
          iconTheme: IconThemeData(color: Color.fromARGB(255, 29, 163, 169)),
        ),
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 2));
          await FlutterBluePlus.stopScan();
          setState(() {
            devices.clear();
          });
          scan();
          _controller.finishRefresh();
        },
        child: ListView.builder(
          itemCount: filteredDevices.length,
          itemBuilder: (context, index) {
            var uwu = filteredDevices[index].platformName;
            var diagnosisResult = deviceDiagnosisResults[uwu] ?? 'unknown';
            return ListTile(
              title: Text(
                filteredDevices[index].platformName,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 29, 163, 169)),
              ),
              trailing: Icon(
                getDiagnosisIcon(diagnosisResult),
              ),
              subtitle: Text(
                '${filteredDevices[index].remoteId}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color.fromARGB(255, 7, 135, 137),
                ),
              ),
              onTap: () {
                connectToDevice(filteredDevices[index]);
                showToast('Intentando conectarse al dispositivo...');
              },
            );
          },
        ),
      ),
    );
  }
}

//REGBANK TAB //Regbank associates

class RegbankTab extends StatefulWidget {
  const RegbankTab({super.key});

  @override
  RegbankTabState createState() => RegbankTabState();
}

class RegbankTabState extends State<RegbankTab> {
  List<String> numbers = [];
  int step = 0;
  String header = '';
  String initialvalue = '';
  String finalvalue = '';
  final FocusNode registerFocusNode = FocusNode();
  final TextEditingController numbersController = TextEditingController();
  bool hearing = false;
  bool numbersAdded = false;
  Stopwatch? stopwatch;
  Timer? timer;
  double _rp = 1.0;
  String temp = '';

  //// ---------------------------------------------------------------------------------- ////

  List<Map<String, List<int>>> mapasDatos = [];
  Map<String, List<int>> streamData = {};
  Map<String, List<int>> diagnosis = {};
  Map<String, List<int>> regDone = {};
  Map<String, List<int>> espUpdate = {};
  Map<String, List<int>> picUpdate = {};
  Map<String, List<int>> regPoint1 = {};
  Map<String, List<int>> regPoint2 = {};
  Map<String, List<int>> regPoint3 = {};
  Map<String, List<int>> regPoint4 = {};
  Map<String, List<int>> regPoint5 = {};
  Map<String, List<int>> regPoint6 = {};
  Map<String, List<int>> regPoint7 = {};
  Map<String, List<int>> regPoint8 = {};
  Map<String, List<int>> regPoint9 = {};
  Map<String, List<int>> regPoint10 = {};

  //// ---------------------------------------------------------------------------------- ////

  @override
  void initState() {
    super.initState();
    setupMqtt5773();
  }

  //!TEST

  String textData(int i) {
    switch (i) {
      case 0:
        return 'Stream Data';
      case 1:
        return 'Diagnosis';
      case 2:
        return 'Regulation Done';
      case 3:
        return 'Esp Update';
      case 4:
        return 'Pic Update';
      case 5:
        return 'Regulation Point 1';
      case 6:
        return 'Regulation Point 2';
      case 7:
        return 'Regulation Point 3';
      case 8:
        return 'Regulation Point 4';
      case 9:
        return 'Regulation Point 5';
      case 10:
        return 'Regulation Point 6';
      case 11:
        return 'Regulation Point 7';
      case 12:
        return 'Regulation Point 8';
      case 13:
        return 'Regulation Point 9';
      case 14:
        return 'Regulation Point 10';
      default:
        return '';
    }
  }

  Future<void> exportDataAndShare(List<Map<String, List<int>>> lista) async {
    final fileName = 'Data_${DateTime.now().toIso8601String()}.txt';
    final directory = await getExternalStorageDirectory();
    if (directory != null) {
      final file = File('${directory.path}/$fileName');
      final buffer = StringBuffer();
      for (int i = 0; i < lista.length; i++) {
        buffer.writeln('----------${textData(i)}----------');
        buffer.writeln(
            "N.Serie /-/ TimeStamp /-/ PPMCH4 /-/ PPMCO /-/ RSCH4 /-/ RSCO /-/ AD Gasout Estable /-/ AD Gasout Estable CO /-/ Temperatura /-/ AD Temp Estable /-/ VCC /-/ AD VCC Estable /-/ AD PWM Estable");
        lista[i].forEach((key, value) {
          var parts = key.split('/-/');
          int ppmch4 = value[0] + (value[1] << 8);
          int ppmco = value[2] + (value[3] << 8);
          int rsch4 = value[4] + (value[5] << 8);
          int rsco = value[6] + (value[7] << 8);
          int adgsEs = value[8] + (value[9] << 8);
          int adgsEsCO = value[10] + (value[11] << 8);
          int temp = value[12];
          int adTempEs = value[13] + (value[14] << 8);
          int vcc = value[15] + (value[16] << 8);
          int advccEst = value[17] + (value[18] << 8);
          int adpwmEst = value[19] + (value[20] << 8);
          buffer.writeln(
              "${parts[0]} /-/ ${parts[1]} /-/ $ppmch4 /-/ $ppmco /-/ $rsch4 /-/ $rsco /-/ $adgsEs /-/ $adgsEsCO /-/ $temp /-/ $adTempEs /-/ $vcc /-/ $advccEst /-/ $adpwmEst ");
        });
      }
      await file.writeAsString(buffer.toString());
      shareFile(file.path);
    } else {
      printLog('Failed to get external storage directory');
    }
  }

  void shareFile(String filePath) {
    Share.shareFiles([filePath]);
  }

  //!TEST

  void startTimer() {
    stopwatch = Stopwatch()..start();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {});
    });
  }

  String elapsedTime() {
    final time = stopwatch!.elapsed;
    return '${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  void setupMqtt5773() async {
    try {
      printLog('Haciendo setup');
      String deviceId = 'intelligentgas_IOT/${generateRandomNumbers(32)}';
      String hostname = 'Cristian.local';

      mqttClient5773 = MqttServerClient.withPort(hostname, deviceId, 1883);

      mqttClient5773!.logging(on: true);
      mqttClient5773!.onDisconnected = mqttonDisconnected;

      // Configuración de las credenciales
      mqttClient5773!.setProtocolV311();
      mqttClient5773!.keepAlivePeriod = 3;
      await mqttClient5773!.connect();
      printLog('Usuario conectado a mqtt');
      setState(() {});
    } catch (e, s) {
      printLog('Error setup mqtt $e $s');
    }
  }

  void mqttonDisconnected() {
    printLog('Desconectado de mqtt');
    setupMqtt5773();
  }

  void sendMessagemqtt(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    mqttClient5773!
        .publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  void subToTopicMQTT(String topic) {
    mqttClient5773!.subscribe(topic, MqttQos.atLeastOnce);
  }

  void unSubToTopicMQTT(String topic) {
    mqttClient5773!.unsubscribe(topic);
  }

  void listenToTopics() {
    mqttClient5773!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String topic = c[0].topic;
      var serialNumerito = topic.split('/');
      final List<int> message = recMess.payload.message;

      switch (message[0]) {
        case 0xF5: //Stream data
          streamData.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          // printLog(streamData);
          break;
        case 0xA1: //Diagnosis
          diagnosis.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xA2: //Reg Done
          regDone.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0XA3: //Esp Update
          espUpdate.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xA4: //Pic Update
          picUpdate.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xB0: //RegPoint 1
          regPoint1.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xB1: //RegPoint 2
          regPoint2.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xB2: //RegPoint 3
          regPoint3.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xB3: //RegPoint 4
          regPoint4.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xB4: //RegPoint 5
          regPoint5.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xB5: //RegPoint 6
          regPoint6.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xB6: //RegPoint 7
          regPoint7.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xB7: //RegPoint 8
          regPoint8.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xB8: //RegPoint 9
          regPoint9.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
        case 0xB9: //RegPoint 10
          regPoint10.addAll(
              {'${serialNumerito[1]}/-/${DateTime.now()}': message.sublist(1)});
          break;
      }

      printLog('Received message: ${message.toString()} from topic: $topic');
    });
  }

  List<String> generateSerialNumbers(
      String header, int initialValue, int finalValue) {
    printLog('Header: $header');
    printLog('Initial: $initialValue');
    printLog('Final: $finalValue');
    List<String> serialNumbers = [];
    for (int i = initialValue; i <= finalValue; i++) {
      if (i < 10) {
        serialNumbers.add("${header}0$i");
      } else {
        serialNumbers.add("$header$i");
      }
    }
    printLog('$serialNumbers');
    numbersAdded = true;
    return serialNumbers;
  }

  String textToShow(int data) {
    switch (data) {
      case 0:
        return 'Agrega la cabecera del número de serie';
      case 1:
        return 'Desde...';
      case 2:
        return 'Hasta...';
      default:
        return "Error Desconocido";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 18, 28),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 50,
            ),
            if (!hearing) ...[
              Text(
                textToShow(step),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Color.fromARGB(255, 29, 163, 169)),
              ),
              Center(
                  child: SizedBox(
                      width: 300,
                      child: TextField(
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255)),
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                            onPressed: () {
                              showDialog(
                                context: navigatorKey.currentContext!,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Center(
                                        child: Text(
                                      'Borrar lista de números',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    content: const Text(
                                        'Esta acción no puede revertirse'),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            numbers.clear();
                                            navigatorKey.currentState!.pop();
                                          },
                                          child: const Text('Borrar'))
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.delete_forever),
                          )),
                          focusNode: registerFocusNode,
                          controller: numbersController,
                          keyboardType: TextInputType.number,
                          onSubmitted: (value) {
                            if (step == 0) {
                              header = value;
                              step = step + 1;
                              numbersController.clear();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                registerFocusNode.requestFocus();
                              });
                            } else if (step == 1) {
                              initialvalue = value;
                              numbersController.clear();
                              step = step + 1;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                registerFocusNode.requestFocus();
                              });
                            } else if (step == 2) {
                              finalvalue = value;
                              numbers.addAll(generateSerialNumbers(
                                  header,
                                  int.parse(initialvalue),
                                  int.parse(finalvalue)));
                              printLog('Lista: $numbers');
                              numbersController.clear();
                              step = 0;
                            }
                            setState(() {});
                          }))),
              const SizedBox(
                height: 30,
              ),
            ],
            numbersAdded &&
                    mqttClient5773!.connectionStatus!.state ==
                        MqttConnectionState.connected
                ? ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromARGB(255, 29, 163, 169)),
                        foregroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromARGB(255, 255, 255, 255))),
                    onPressed: () {
                      if (!hearing) {
                        try {
                          for (int i = 0; i < numbers.length; i++) {
                            String topic = '015773_IOT/${numbers[i]}';
                            subToTopicMQTT(topic);
                          }
                        } catch (e, s) {
                          printLog('Error al sub $e $s');
                        }
                        listenToTopics();
                        startTimer();
                        hearing = true;
                      } else {
                        try {
                          for (int i = 0; i < numbers.length; i++) {
                            String topic = '015773_IOT/${numbers[i]}';
                            unSubToTopicMQTT(topic);
                          }
                        } catch (e, s) {
                          printLog('Error al unsub $e $s');
                        }
                        hearing = false;
                        stopwatch!.stop();
                        timer!.cancel();

                        //Crear Sheet aca
                        mapasDatos.addAll([
                          streamData,
                          diagnosis,
                          regDone,
                          espUpdate,
                          picUpdate,
                          regPoint1,
                          regPoint2,
                          regPoint3,
                          regPoint4,
                          regPoint5,
                          regPoint6,
                          regPoint7,
                          regPoint8,
                          regPoint9,
                          regPoint10
                        ]);
                        exportDataAndShare(mapasDatos);
                        setState(() {});
                      }
                    },
                    child: hearing
                        ? const Text(
                            'Cancelar la escucha',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255)),
                          )
                        : const Text(
                            'Iniciar la escucha',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255)),
                          ),
                  )
                : Container(),
            if (hearing) ...[
              const SizedBox(
                height: 30,
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 29, 163, 169)),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 255, 255, 255))),
                onPressed: () {
                  sendMessagemqtt('015773_RB', 'DIAGNOSIS_OK');
                },
                child: const Text('Hacer Diagnosis OK'),
              ),
              const SizedBox(
                height: 30,
              ),
              Text(
                'RP ${_rp.round()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color.fromARGB(255, 29, 163, 169), fontSize: 30),
              ),
              const SizedBox(
                height: 5,
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    disabledActiveTrackColor:
                        const Color.fromARGB(255, 29, 163, 169),
                    disabledInactiveTrackColor:
                        const Color.fromARGB(255, 68, 89, 99),
                    trackHeight: 20,
                    thumbShape: SliderComponentShape.noThumb),
                child: Slider(
                  value: _rp,
                  divisions: 11,
                  min: 0,
                  max: 11,
                  onChanged: (value) {
                    if (0 < value && value < 11) {
                      setState(() {
                        _rp = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255)),
                  decoration: const InputDecoration(
                      labelText: 'Temperatura (°C)',
                      labelStyle:
                          TextStyle(color: Color.fromARGB(255, 29, 163, 169)),
                      hintText: 'Añadir temperatura',
                      hintStyle:
                          TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.normal)),
                  onChanged: (value) {
                    temp = value;
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 29, 163, 169)),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 255, 255, 255))),
                onPressed: () {
                  sendMessagemqtt('015773_RB', 'REGPOINT_${_rp}_($temp)');
                },
                child: const Text('Enviar RegPoint'),
              ),
              const SizedBox(
                height: 30,
              ),
              Text(
                'Tiempo transcurrido: ${elapsedTime()}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

//UPGRADE TAB //Masive updates tab

class UpdateTab extends StatefulWidget {
  const UpdateTab({super.key});
  @override
  UpdateTabState createState() => UpdateTabState();
}

class UpdateTabState extends State<UpdateTab> {
  List<String> updateStatus = [];
  bool login = false;
  final TextEditingController loginController = TextEditingController();

  void updatePics() async {
    for (int i = 0; i < numbersToCheck.length; i++) {
      updateStatus.add(await sendUpdatePic(numbersToCheck[i]));
    }
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Resultado de la actualización"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: numbersToCheck.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                    title: Row(
                  children: [
                    Text(numbersToCheck[index]),
                    Text(updateStatus[index])
                  ],
                ));
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                updateStatus.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> sendUpdatePic(String sn) async {
    String url =
        'http://RB_IOT_$sn:8080/PIC_UPDATE(https://github.com/CrisDores/57_IOT_PUBLIC/raw/main/57_ota_factory_fw/firmware.hex)';
    printLog('Vine aquis $url');
    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        if (response.data.toString().contains('PIC_UPDATE_OK')) {
          return 'OK';
        } else {
          return 'WRONG_RESPONSE';
        }
      } else {
        return 'WRONG_STATUS_CODE';
      }
    } catch (e, s) {
      printLog("Error: $e");
      printLog("Stacktrace: $s");
      if (e is TimeoutException) {
        return 'CONNECTION_TIMED_OUT';
      }
      return 'CONNECTION_ERROR';
    }
  }

  void updateEsps() async {
    for (int i = 0; i < numbersToCheck.length; i++) {
      updateStatus.add(await sendUpdateEsp(numbersToCheck[i]));
    }
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Resultado de la actualización"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: numbersToCheck.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                    title: Row(
                  children: [
                    Text(numbersToCheck[index]),
                    Text(updateStatus[index])
                  ],
                ));
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                updateStatus.clear();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> sendUpdateEsp(String sn) async {
    String url =
        'http://RB_IOT_$sn:8080/ESP_UPDATE(https://github.com/CrisDores/57_IOT_PUBLIC/raw/main/57_ota_factory_fw/firmware.bin)';

    printLog('Vine aquis $url');
    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        if (response.data.toString().contains('ESP_UPDATE_OK')) {
          return 'OK';
        } else {
          return 'WRONG_RESPONSE';
        }
      } else {
        return 'WRONG_STATUS_CODE';
      }
    } catch (e, s) {
      printLog("Error: $e");
      printLog("Stacktrace: $s");
      if (e is TimeoutException) {
        return 'CONNECTION_TIMED_OUT';
      }
      return 'CONNECTION_ERROR';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 1, 18, 28),
        appBar: AppBar(
          title: const Center(child: Text('Actualizaciones múltiples')),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBar: const BottomAppBar(
            color: Colors.transparent,
            shadowColor: Colors.transparent,
            child: Center(
              child: Text(
                  'Tanto el dispositivo como los detectores\ndeben estar conectados a internet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.teal,
                      fontSize: 12,
                      backgroundColor: Colors.transparent)),
            )),
        body: login
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: () => updatePics(),
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                const Color.fromARGB(255, 29, 163, 169)),
                            foregroundColor: MaterialStateProperty.all<Color>(
                                const Color.fromARGB(255, 255, 255, 255))),
                        child: const Text('ACTUALIZAR PICS')),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () => updateEsps(),
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                const Color.fromARGB(255, 29, 163, 169)),
                            foregroundColor: MaterialStateProperty.all<Color>(
                                const Color.fromARGB(255, 255, 255, 255))),
                        child: const Text('ACTUALIZAR ESPS')),
                  ],
                ),
              )
            : Column(
                children: [
                  const SizedBox(
                    height: 200,
                  ),
                  Center(
                    child: SizedBox(
                        width: 300,
                        child: TextField(
                          style: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255)),
                          controller: loginController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ingresa la contraseña',
                            labelStyle: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255)),
                            hintStyle: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255)),
                          ),
                          onSubmitted: (value) {
                            if (loginController.text == '05112004') {
                              setState(() {
                                login = true;
                              });
                            } else {
                              showToast('Contraseña equivocada');
                            }
                          },
                        )),
                  ),
                ],
              ));
  }
}
