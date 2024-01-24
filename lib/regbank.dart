// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
        length: 5,
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
                Tab(icon: Icon(Icons.app_registration)),
                Tab(icon: Icon(Icons.assignment)),
                Tab(icon: Icon(Icons.dew_point)),
                Tab(
                  icon: Icon(Icons.update),
                )
              ],
            ),
            actions: <Widget>[
              Row(
                children: [
                  IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 24.0,
                        semanticLabel: 'Wipe icon',
                      ),
                      onPressed: () {
                        showDialog(
                          context: navigatorKey.currentContext!,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Center(
                                  child: Text(
                                'Borrar datos de la hoja de calculo',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              )),
                              content:
                                  const Text('Esta acción no puede revertirse'),
                              actions: [
                                TextButton(
                                    onPressed: () async {
                                      String url =
                                          'https://script.google.com/macros/s/AKfycbw_yagA9NNUKmbAoVLsbg9R9sR9ZJCbNRk-TUdQDyXL3pVOUdeo7lrKFjQBIgZ2KazB/exec';
                                      final response = await dio.post(url);
                                      if (response.statusCode == 200) {
                                        print('Wipe completo');
                                      } else {
                                        print('Unu');
                                      }
                                      numbersToCheck.clear();
                                      deviceDiagnosisResults.clear();
                                    },
                                    child: const Text('Borrar'))
                              ],
                            );
                          },
                        );
                      }),
                  IconButton(
                    icon: const Icon(
                      Icons.person,
                      size: 24.0,
                      semanticLabel: 'Nickname icon',
                    ),
                    onPressed: () {
                      showDialog(
                        context: navigatorKey.currentContext!,
                        builder: (BuildContext context) {
                          return AlertDialog(
                              title: const Center(
                                  child: Text(
                                'Agrega un nombre de usuario:',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              )),
                              content: SingleChildScrollView(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                          width: 400,
                                          child: TextField(
                                              decoration: InputDecoration(
                                                  hintText: nickname),
                                              controller: nicknameController,
                                              onSubmitted: (value) {
                                                nickname =
                                                    nicknameController.text;
                                                print(
                                                    'El nickname actual: $nickname');
                                                nicknameController.clear();
                                                Navigator.pop(context);
                                              }))
                                    ]),
                              ));
                        },
                      );
                    },
                  ),
                ],
              )
            ],
          ),
          body: const TabBarView(
            children: [
              ScanTab(),
              RegisterTab(),
              DiagnosisTab(),
              RegulationTab(),
              UpdateTab(),
            ],
          ),
        ),
      ),
    );
  }
}

//REGISTER TAB //Upload the devices into the sheet

class RegisterTab extends StatefulWidget {
  const RegisterTab({super.key});
  @override
  RegisterTabState createState() => RegisterTabState();
}

class RegisterTabState extends State<RegisterTab> {
  int step = 0;
  String header = '';
  String initialvalue = '';
  String finalvalue = '';
  Map<String, bool> headersProcessed = {};
  final TextEditingController controller = TextEditingController();
  List<String> numbersTosend = [];
  double numbersProgress = 0.0;
  final FocusNode registerFocusNode = FocusNode();
  bool isRegister = false;

  List<String> generateSerialNumbers(
      String header, int initialValue, int finalValue) {
    print('Header: $header');
    print('Initial: $initialvalue');
    print('Final: $finalvalue');
    List<String> serialNumbers = [];
    for (int i = initialValue; i <= finalValue; i++) {
      if (i < 10) {
        serialNumbers.add("${header}0$i");
      } else {
        serialNumbers.add("$header$i");
      }
    }
    print(serialNumbers);
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

  Future<void> cancelReg() async {
    setState(() {
      step = 0;
      headersProcessed.clear();
      numbersTosend.clear();
      numbersToCheck.clear();
      deviceDiagnosisResults.clear();
      header = '';
      initialvalue = '';
      finalvalue = '';
    });
  }

  Future<void> _addregister() async {
    print('mande alguito');

    setState(() {
      isRegister = true;
    });
    String serialNumbersJson = jsonEncode(numbersTosend);
    const String url =
        'https://script.google.com/macros/s/AKfycbxQeYSANepCxF_aB4-GzI9YNMrs25J_EwgYR1pxogqNEw5wzVjWAEQr1imBi98Zrn8c-A/exec';

    final Uri uri = Uri.parse(url).replace(queryParameters: {
      'serialNumbers': serialNumbersJson,
      'nickname': nickname ?? 'Anónimo',
    });

    // final response = await http.get(uri);
    final response = await dio.getUri(uri);
    if (response.statusCode == 200) {
      numbersToCheck.addAll(numbersTosend);
      print('Si llego');
      headersProcessed.clear();
      numbersTosend.clear();
      isRegister = false;
      setState(() {});
    } else {
      print('Unu');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 1, 18, 28),
        appBar: AppBar(
          title: const Text('Registro', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          centerTitle: true,
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
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              textToShow(step),
              style: const TextStyle(color: Color.fromARGB(255, 29, 163, 169)),
            ),
            Center(
                child: SizedBox(
                    width: 300,
                    child: TextField(
                        style: const TextStyle(
                            color: Color.fromARGB(255, 29, 163, 169)),
                        focusNode: registerFocusNode,
                        controller: controller,
                        keyboardType: TextInputType.number,
                        onSubmitted: (value) {
                          if (step == 0) {
                            header = value;
                            headersProcessed[header] = false;
                            step = step + 1;
                            controller.clear();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              registerFocusNode.requestFocus();
                            });
                          } else if (step == 1) {
                            initialvalue = value;
                            controller.clear();
                            step = step + 1;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              registerFocusNode.requestFocus();
                            });
                          } else if (step == 2) {
                            finalvalue = value;
                            numbersTosend.addAll(generateSerialNumbers(
                                header,
                                int.parse(initialvalue),
                                int.parse(finalvalue)));
                            headersProcessed[header] = true;
                            controller.clear();
                            step = 0;
                          }
                          print(step);
                          setState(() {});
                        }))),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromARGB(255, 29, 163, 169)),
                  foregroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromARGB(255, 255, 255, 255))),
              onPressed: isRegister
                  ? null
                  : () {
                      _addregister();
                      controller.clear();
                      step = 0;
                      setState(() {});
                    },
              child: const Text('REGISTRAR EQUIPOS'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 29, 163, 169)),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 255, 255, 255))),
                onPressed: () => cancelReg(),
                child: const Text('CANCELAR')),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              itemCount: headersProcessed.length,
              itemBuilder: (context, index) {
                String header = headersProcessed.keys.elementAt(index);
                bool isCharged = headersProcessed[header]!;
                return ListTile(
                  titleTextStyle:
                      const TextStyle(color: Color.fromARGB(255, 29, 163, 169)),
                  title: Text(header),
                  leadingAndTrailingTextStyle:
                      const TextStyle(color: Color.fromARGB(255, 29, 163, 169)),
                  trailing: isCharged ? const Text("--cargado") : null,
                );
              },
            ),
            const SizedBox(height: 10),
            if (isRegister) ...{
              const CircularProgressIndicator(
                color: Color.fromARGB(255, 29, 163, 169),
              ),
            }
          ],
        ));
  }
}

//DIAGNOSIS TAB //Ask for the state of the devices

class DiagnosisTab extends StatefulWidget {
  const DiagnosisTab({super.key});

  @override
  DiagnosisTabState createState() => DiagnosisTabState();
}

class DiagnosisTabState extends State<DiagnosisTab> {
  double progressValue = 0.0;
  List<String> version = [];
  List<int> ppmch4 = [];
  List<int> ppmco = [];
  bool isDiagnosing = false;
  Stopwatch? stopwatch;
  Timer? timer;

  // http.Client client = http.Client();

  Future<String> getStatusFromSerialNumber(String sn) async {
    String url = 'http://RB_IOT_$sn.local:8080/DIAGNOSIS_OK';
    print('Vine aquis $url');
    try {
      // final response = await client.get(Uri.parse(url));
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        if (response.data.toString().contains('DIAGNOSIS_OK')) {
          var texto = response.data.toString();
          String buscar = '(';
          int inicio = texto.indexOf(buscar);
          if (inicio != -1) {
            int fin = texto.indexOf(')', inicio);
            if (fin != -1) {
              version.add(texto.substring(inicio + 1, fin));
            } else {
              print('No se encontró el cierre de la versión en el texto.');
            }
          } else {
            print('No se encontró Version en el texto.');
          }
          updateDiagnosisResult('Detector$sn', 'ok');
          return 'OK';
        } else {
          updateDiagnosisResult('Detector$sn', 'error');
          return 'WRONG_RESPONSE';
        }
      } else {
        updateDiagnosisResult('Detector$sn', 'error');
        return 'WRONG_STATUS_CODE';
      }
    } catch (e, s) {
      print("Error: $e");
      print("Stacktrace: $s");
      if (e is TimeoutException) {
        updateDiagnosisResult('Detector$sn', 'error');
        return 'CONNECTION_TIMED_OUT';
      }
      updateDiagnosisResult('Detector$sn', 'error');
      return 'CONNECTION_ERROR';
    }
  }

  Future<String> diagnosisCH4(String sn) async {
    String url = 'http://RB_IOT_$sn.Local:8080/DIAGNOSIS_CH4';
    print('Vine aquis $url');
    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        if (response.data.toString().contains('DIAGNOSIS_CH4')) {
          var texto = response.data.toString();
          String buscar = '(';
          int inicio = texto.indexOf(buscar);
          if (inicio != -1) {
            int fin = texto.indexOf(')', inicio);
            if (fin != -1) {
              var payload = texto.substring(inicio + 1, fin);
              var parts = payload.split(':');
              int fun = int.parse(parts[0]);
              fun += int.parse(parts[1]) << 8;
              ppmch4.add(fun);
            } else {
              print('No se encontró el cierre del ppmch4 en el texto.');
            }
          } else {
            print('No se encontró ppmch4 en el texto.');
          }
          return 'OK';
        } else {
          return 'WRONG_RESPONSE';
        }
      } else {
        return 'WRONG_STATUS_CODE';
      }
    } catch (e, s) {
      print("Error: $e");
      print("Stacktrace: $s");
      if (e is TimeoutException) {
        return 'CONNECTION_TIMED_OUT';
      }
      return 'CONNECTION_ERROR';
    }
  }

  Future<String> diagnosisCO(String sn) async {
    String url = 'http://RB_IOT_$sn.Local:8080/DIAGNOSIS_CO';
    print('Vine aquis $url');
    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        if (response.data.toString().contains('DIAGNOSIS_CO')) {
          var texto = response.data.toString();
          String buscar = '(';
          int inicio = texto.indexOf(buscar);
          if (inicio != -1) {
            int fin = texto.indexOf(')', inicio);
            if (fin != -1) {
              var payload = texto.substring(inicio + 1, fin);
              var parts = payload.split(':');
              int fun = int.parse(parts[0]);
              fun += int.parse(parts[1]) << 8;
              ppmco.add(fun);
            } else {
              print('No se encontró el cierre del ppmco en el texto.');
            }
          } else {
            print('No se encontró ppmco en el texto.');
          }
          return 'OK';
        } else {
          return 'WRONG_RESPONSE';
        }
      } else {
        return 'WRONG_STATUS_CODE';
      }
    } catch (e, s) {
      print("Error: $e");
      print("Stacktrace: $s");
      if (e is TimeoutException) {
        return 'CONNECTION_TIMED_OUT';
      }
      return 'CONNECTION_ERROR';
    }
  }

  Future<void> updateGoogleSheet(int value) async {
    late String dataJson;
    late String tipe;
    String statusJson = jsonEncode(statusOfDevices);
    if (value == 1) {
      dataJson = jsonEncode(version);
      tipe = 'OK';
    } else if (value == 2) {
      dataJson = jsonEncode(ppmch4);
      tipe = 'CH4';
    } else {
      dataJson = jsonEncode(ppmco);
      tipe = 'CO';
    }

    const String url =
        'https://script.google.com/macros/s/AKfycbxXVphwIa0CLRRXiq3aj54atXYWwFnQon1G7Na5TPpOyD0LfXJflDWSnBf1TYgoSJGPZw/exec';

    final Uri uri = Uri.parse(url).replace(queryParameters: {
      'status': statusJson,
      'tipe': tipe,
      'data': dataJson,
      'nickname': nickname ?? 'Anónimo'
    });

    final response = await dio.getUri(uri);

    if (response.statusCode == 200) {
      print('Actualización exitosa');
    } else {
      print('Error al actualizar la hoja de cálculo');
    }
  }

  void startDiagnosis() async {
    stopwatch = Stopwatch()..start();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {});
    });

    setState(() {
      isDiagnosing = true;
      print('Cambio el estado $isDiagnosing');
    });

    print('Numeros a checkar $numbersToCheck');
    for (int i = 0; i < numbersToCheck.length; i++) {
      if (!isDiagnosing) {
        print('Rompo ciclo');
        break;
      }
      bool good = false;
      String status = '';
      for (int j = 0; j < 10; j++) {
        print('RETRY: $j');
        status = await getStatusFromSerialNumber(numbersToCheck[i]);
        if (status == 'OK') {
          good = true;
          break;
        } else {
          await Future.delayed(const Duration(seconds: 3));
        }
      }
      if (good == true) {
        good = false;
      } else {
        version.add('-');
      }
      statusOfDevices.add(status);

      setState(() {
        progressValue = (i + 1) / numbersToCheck.length;
      });
    }
    print(statusOfDevices);
    print(version);

    if (isDiagnosing) {
      await updateGoogleSheet(1);
    }

    stopwatch!.stop();
    timer!.cancel();

    setState(() {
      progressValue = 0.0;
      statusOfDevices.clear();
      deviceDiagnosisResults.clear();
      version.clear();
      isDiagnosing = false;
    });
  }

  void startDiagnosisCH4() async {
    stopwatch = Stopwatch()..start();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {});
    });

    setState(() {
      isDiagnosing = true;
      print('Cambio el estado $isDiagnosing');
    });

    print('Numeros a checkar $numbersToCheck');
    for (int i = 0; i < numbersToCheck.length; i++) {
      if (!isDiagnosing) {
        print('Rompo ciclo');
        break;
      }
      bool good = false;
      String status = '';
      for (int j = 0; j < 10; j++) {
        print('RETRY: $j');
        status = await diagnosisCH4(numbersToCheck[i]);
        if (status == 'OK') {
          good = true;
          break;
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      if (good == true) {
        good = false;
      } else {
        ppmch4.add(0);
      }
      statusOfDevices.add(status);

      setState(() {
        progressValue = (i + 1) / numbersToCheck.length;
      });
    }
    print(statusOfDevices);
    print(ppmch4);

    if (isDiagnosing) {
      await updateGoogleSheet(2);
    }

    stopwatch!.stop();
    timer!.cancel();

    setState(() {
      progressValue = 0.0;
      statusOfDevices.clear();
      deviceDiagnosisResults.clear();
      ppmch4.clear();
      isDiagnosing = false;
    });
  }

  void startDiagnosisCO() async {
    stopwatch = Stopwatch()..start();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {});
    });

    setState(() {
      isDiagnosing = true;
      print('Cambio el estado $isDiagnosing');
    });

    print('Numeros a checkar $numbersToCheck');
    for (int i = 0; i < numbersToCheck.length; i++) {
      if (!isDiagnosing) {
        print('Rompo ciclo');
        break;
      }
      bool good = false;
      String status = '';
      for (int j = 0; j < 10; j++) {
        print('RETRY: $j');
        status = await diagnosisCO(numbersToCheck[i]);
        if (status == 'OK') {
          good = true;
          break;
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      if (good == true) {
        good = false;
      } else {
        ppmco.add(0);
      }
      statusOfDevices.add(status);

      setState(() {
        progressValue = (i + 1) / numbersToCheck.length;
      });
    }
    print(statusOfDevices);
    print(ppmco);

    if (isDiagnosing) {
      await updateGoogleSheet(3);
    }

    stopwatch!.stop();
    timer!.cancel();

    setState(() {
      progressValue = 0.0;
      statusOfDevices.clear();
      deviceDiagnosisResults.clear();
      ppmco.clear();
      isDiagnosing = false;
    });
  }

  void cancelDiagnosis() {
    setState(() {
      isDiagnosing = false;
      progressValue = 0.0;
    });
  }

  String elapsedTime() {
    final time = stopwatch!.elapsed;
    return '${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    if (timer != null) {
      if (timer!.isActive) {
        timer!.cancel();
      }
    }
    // client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 1, 18, 28),
        appBar: AppBar(
          title: const Center(child: Text('Diagnosis')),
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
                        value: progressValue,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color.fromARGB(255, 29, 163, 169)),
                      ),
                    ),
                  ),
                  Text(
                    'Progreso del diagnostico: ${(progressValue * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 29, 163, 169)),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 255, 255, 255))),
                onPressed: isDiagnosing ? null : startDiagnosis,
                child: const Text('Empezar diagnosis'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 29, 163, 169)),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 255, 255, 255))),
                onPressed: isDiagnosing ? null : startDiagnosisCH4,
                child: const Text('Empezar diagnosis en CH4'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 29, 163, 169)),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 255, 255, 255))),
                onPressed: isDiagnosing ? null : startDiagnosisCO,
                child: const Text('Empezar diagnosis en CO'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 29, 163, 169)),
                    foregroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 255, 255, 255))),
                onPressed: isDiagnosing ? cancelDiagnosis : null,
                child: const Text('Cancelar'),
              ),
              isDiagnosing
                  ? Text(
                      'Tiempo transcurrido: ${elapsedTime()}',
                      style: const TextStyle(
                          color: Color.fromARGB(255, 29, 163, 169)),
                    )
                  : Container(),
            ],
          ),
        ));
  }
}

//REGULATION TAB //Reg in the regbank

class RegulationTab extends StatefulWidget {
  const RegulationTab({super.key});

  @override
  RegulationTabState createState() => RegulationTabState();
}

class RegulationTabState extends State<RegulationTab> {
  final TextEditingController tempController = TextEditingController();
  final TextEditingController regPointController = TextEditingController();
  String temp = '';
  bool tempSubmitted = false;
  double individualProgressValue = 0.0;
  bool isRegulating = false;
  Stopwatch? stopwatch;
  Timer? timer;
  String rPoint = '';
  bool regSubmitted = false;
  List<String> regulationValues = [];

  Future<String> getRegulationValue(String sn) async {
    String url = 'http://RB_IOT_$sn.local:8080/REGP[$rPoint]($temp)';
    String payloadCompleto = '';
    print('Me voy a $url');

    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        if (response.data.toString().contains('PAYLOAD')) {
          var texto = response.data.toString();
          String buscar = 'PAYLOAD(';
          int inicio = texto.indexOf(buscar);
          if (inicio != -1) {
            int fin = texto.indexOf(')', inicio);
            if (fin != -1) {
              payloadCompleto = texto.substring(inicio + 1, fin);
              print(payloadCompleto);
            } else {
              print('No se encontró el cierre del PAYLOAD en el texto.');
            }
          } else {
            print('No se encontró PAYLOAD en el texto.');
          }
          return payloadCompleto;
        } else {
          return 'WRONG_RESPONSE';
        }
      } else {
        return 'WRONG_STATUS_CODE';
      }
    } catch (e) {
      print("Error: $e");
      if (e is TimeoutException) {
        return 'CONNECTION_TIMED_OUT';
      }
      return 'CONNECTION_ERROR';
    }
  }

  void startRegulation() async {
    stopwatch = Stopwatch()..start();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {});
    });

    setState(() {
      isRegulating = true;
      print('Cambio el estado reg $isRegulating');
    });
    print('Numeros a checkar $numbersToCheck');
    for (int i = 0; i <= numbersToCheck.length; i++) {
      if (!isRegulating) {
        print('Rompo ciclo');
        break;
      }
      String status = '';
      for (int j = 0; j < 3; j++) {
        print('RETRY: $j');
        status = await getRegulationValue(numbersToCheck[i]);
        if (status.contains('PAYLOAD')) {
          break;
        }
      }
      regulationValues.add(status);

      setState(() {
        individualProgressValue = (i + 1) / numbersToCheck.length;
      });
    }
    print(regulationValues);

    if (isRegulating) {
      await updateGoogleSheet();
    }

    setState(() {
      individualProgressValue = 0.0;
      regulationValues.clear();
    });

    stopwatch!.stop();
    timer!.cancel();

    setState(() {
      individualProgressValue = 0.0;
      regulationValues.clear();
      numbersToCheck.clear();

      isRegulating = false;
    });
  }

  Future<void> updateGoogleSheet() async {
    String regValJson = jsonEncode(regulationValues);
    String rPointJson = jsonEncode(rPoint);

    const String url =
        'https://script.google.com/macros/s/AKfycbzqV0ZzWWWFKZB22PZagwEZko0ZqZB1JDC8MKq8TRn5CK4XK2XFKceSUJRZW5vnwPk6VA/exec';

    final Uri uri = Uri.parse(url).replace(queryParameters: {
      'regVal': regValJson,
      'regPoint': rPointJson,
      'nickname': nickname ?? 'Anónimo'
    });

    // final response = await http.get(uri);
    final response = await dio.getUri(uri);

    if (response.statusCode == 200) {
      print('Actualización exitosa reg');
    } else {
      print('Error al actualizar la hoja de cálculo reg');
    }
  }

  String elapsedTime() {
    final time = stopwatch!.elapsed;
    return '${time.inMinutes}:${(time.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    if (timer != null) {
      if (timer!.isActive) {
        timer!.cancel();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 1, 18, 28),
        appBar: AppBar(
          title: const Center(child: Text('Regulación')),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                        value: individualProgressValue,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color.fromARGB(255, 29, 163, 169)),
                      ),
                    ),
                  ),
                  Text(
                    'Progreso de la regulación: ${(individualProgressValue * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                  width: 300,
                  child: TextField(
                    style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255)),
                    controller: tempController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        hintStyle: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255)),
                        hintText: tempSubmitted ? temp : 'Definir temperatura'),
                    onSubmitted: (value) {
                      temp = tempController.text;
                      tempController.clear();
                      tempSubmitted = true;
                      setState(() {});
                    },
                  )),
              const SizedBox(height: 10),
              SizedBox(
                  width: 300,
                  child: TextField(
                    style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255)),
                    controller: regPointController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        hintStyle: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255)),
                        hintText: regSubmitted
                            ? rPoint
                            : 'Definir punto de regulación'),
                    onSubmitted: (value) {
                      rPoint = regPointController.text;
                      regPointController.clear();
                      regSubmitted = true;
                      setState(() {});
                    },
                  )),
              const SizedBox(height: 10),
              ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 29, 163, 169)),
                      foregroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 255, 255, 255))),
                  onPressed: () => startRegulation(),
                  child: const Text('Empezar regulación')),
              const SizedBox(height: 10),
              ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 29, 163, 169)),
                      foregroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 255, 255, 255))),
                  onPressed: () {
                    setState(() {
                      isRegulating = false;
                      rPoint = '';
                      temp = '';
                      tempController.clear();
                      regPointController.clear();
                      tempSubmitted = false;
                      regSubmitted = false;
                    });
                  },
                  child: const Text('Cancelar')),
              const SizedBox(height: 10),
              isRegulating
                  ? Text('Tiempo transcurrido: ${elapsedTime()}')
                  : Container(),
            ],
          ),
        ));
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void scan() async {
    if (bluetoothOn) {
      print('Entre a escanear');
      try {
        await FlutterBluePlus.startScan(
            withKeywords: ['Detector'],
            timeout: const Duration(seconds: 30),
            androidUsesFineLocation: true,
            continuousUpdates: true);
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
        print('Error al escanear $e $stackTrace');
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

      print('Teoricamente estoy conectado');

      MyDevice myDevice = MyDevice();

      device.connectionState.listen((BluetoothConnectionState state) {
        print('Estado de conexión: $state');
        switch (state) {
          case BluetoothConnectionState.disconnected:
            {
              showToast('Dispositivo desconectado');
              calibrationValues.clear();
              regulationValues.clear();
              keysValues.clear();
              toolsValues.clear();
              nameOfWifi = '';
              connectionFlag = false;
              alreadySubCal = false;
              alreadySubReg = false;
              alreadySubOta = false;
              print('Razon: ${myDevice.device.disconnectReason?.description}');
              navigatorKey.currentState?.pushReplacementNamed('/regbank');
              break;
            }
          case BluetoothConnectionState.connected:
            {
              if (!connectionFlag) {
                connectionFlag = true;
                FlutterBluePlus.stopScan();
                myDevice.setup(device).then((valor) {
                  print('RETORNASHE $valor');
                  if (valor) {
                    navigatorKey.currentState?.pushReplacementNamed('/loading');
                  } else {
                    connectionFlag = false;
                    print('Fallo en el setup');
                    showToast('Error en el dispositivo, intente nuevamente');
                    myDevice.device.disconnect();
                  }
                });
              } else {
                print('Las chistosadas se apoderan del mundo');
              }
              break;
            }
          default:
            break;
        }
      });
    } catch (e, stackTrace) {
      if (e is FlutterBluePlusException && e.code == 133) {
        print('Error específico de Android con código 133: $e');
        showToast('Error de conexión, intentelo nuevamente');
      } else {
        print('Error al conectar: $e $stackTrace');
        showToast('Error al conectar, intentelo nuevamente');
        // handleManualError(e, stackTrace);
      }
    }
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
    print('Vine aquis $url');
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
      print("Error: $e");
      print("Stacktrace: $s");
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

    print('Vine aquis $url');
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
      print("Error: $e");
      print("Stacktrace: $s");
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
