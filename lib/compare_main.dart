import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:mmlu/sonuc_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Model Karşılaştırma',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ModelComparePage(),
    );
  }
}

class ModelComparePage extends StatefulWidget {
  const ModelComparePage({Key? key}) : super(key: key);

  @override
  _ModelComparePageState createState() => _ModelComparePageState();
}

class _ModelComparePageState extends State<ModelComparePage> {
  late Future<List<SonucModel>> sonucList;
  String? _selectedModel1;
  String? _selectedModel2;
  SonucModel? _selectedSonuc1;
  SonucModel? _selectedSonuc2;

  @override
  void initState() {
    super.initState();
    sonucList = loadSonuclar();
  }

  Future<List<SonucModel>> loadSonuclar() async {
    final String response = await rootBundle.loadString('assets/sonuclar.json');
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => SonucModel.fromJson(json)).toList();
  }

  double calculateAverage(Map<String, int> scores) {
    if (scores.isEmpty) return 0.0;
    return scores.values.reduce((a, b) => a + b) / scores.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Karşılaştırma'),
      ),
      body: FutureBuilder<List<SonucModel>>(
        future: sonucList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Veriler yüklenemedi: ${snapshot.error}'));
          } else {
            List<SonucModel> models = snapshot.data!;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton<String>(
                        hint: const Text('Model 1 Seçin'),
                        value: _selectedModel1,
                        items: models.map((SonucModel model) {
                          return DropdownMenuItem<String>(
                            value: model.model,
                            child: Text(model.model),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedModel1 = value;
                            _selectedSonuc1 = models
                                .firstWhere((model) => model.model == value);
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButton<String>(
                        hint: const Text('Model 2 Seçin'),
                        value: _selectedModel2,
                        items: models.map((SonucModel model) {
                          return DropdownMenuItem<String>(
                            value: model.model,
                            child: Text(model.model),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedModel2 = value;
                            _selectedSonuc2 = models
                                .firstWhere((model) => model.model == value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_selectedSonuc1 != null && _selectedSonuc2 != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Ortalama Model 1: ${calculateAverage(_selectedSonuc1!.sinavSonuclari)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Ortalama Model 2: ${calculateAverage(_selectedSonuc2!.sinavSonuclari)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  Expanded(
                    // Ekranın kalan alanını kapla
                    child: SingleChildScrollView(
                      // Kaydırılabilir alan oluştur
                      child: SizedBox(
                        height: 1500,
                        child: Row(
                          children: [
                            Expanded(
                              child: SfCartesianChart(
                                primaryXAxis: CategoryAxis(),
                                primaryYAxis: NumericAxis(
                                  isInversed: true,
                                  minimum: 0,
                                  maximum: 100,
                                ),
                                series: <CartesianSeries>[
                                  BarSeries<MapEntry<String, int>, String>(
                                    dataSource: _selectedSonuc1!
                                        .sinavSonuclari.entries
                                        .toList(),
                                    xValueMapper:
                                        (MapEntry<String, int> entry, _) =>
                                            entry.key,
                                    yValueMapper:
                                        (MapEntry<String, int> entry, _) =>
                                            entry.value,
                                    pointColorMapper:
                                        (MapEntry<String, int> entry, _) {
                                      // Renk ayarlama
                                      if (entry.value >
                                          (_selectedSonuc2!
                                                  .sinavSonuclari[entry.key] ??
                                              0)) {
                                        return Colors.green;
                                      } else if (entry.value <
                                          (_selectedSonuc2!
                                                  .sinavSonuclari[entry.key] ??
                                              0)) {
                                        return Colors.red;
                                      } else {
                                        return Colors.blue;
                                      }
                                    },
                                    dataLabelSettings: const DataLabelSettings(
                                        isVisible: true,
                                        labelPosition:
                                            ChartDataLabelPosition.outside),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SfCartesianChart(
                                primaryXAxis: CategoryAxis(
                                  isVisible: false,
                                ),
                                primaryYAxis: NumericAxis(
                                  minimum: 0,
                                  maximum: 100,
                                ),
                                series: <CartesianSeries>[
                                  BarSeries<MapEntry<String, int>, String>(
                                    dataSource: _selectedSonuc2!
                                        .sinavSonuclari.entries
                                        .toList(),
                                    xValueMapper:
                                        (MapEntry<String, int> entry, _) =>
                                            entry.key,
                                    yValueMapper:
                                        (MapEntry<String, int> entry, _) =>
                                            entry.value,
                                    pointColorMapper:
                                        (MapEntry<String, int> entry, _) {
                                      // Renk ayarlama
                                      if (entry.value >
                                          (_selectedSonuc1!
                                                  .sinavSonuclari[entry.key] ??
                                              0)) {
                                        return Colors.green;
                                      } else if (entry.value <
                                          (_selectedSonuc1!
                                                  .sinavSonuclari[entry.key] ??
                                              0)) {
                                        return Colors.red;
                                      } else {
                                        return Colors.blue;
                                      }
                                    },
                                    dataLabelSettings: const DataLabelSettings(
                                      isVisible: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            );
          }
        },
      ),
    );
  }
}
