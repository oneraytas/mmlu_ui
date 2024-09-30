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
      title: 'Model Chart',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SinavMainPage(),
    );
  }
}

class SinavMainPage extends StatefulWidget {
  const SinavMainPage({Key? key}) : super(key: key);

  @override
  _ModelChartPageState createState() => _ModelChartPageState();
}

class _ModelChartPageState extends State<SinavMainPage> {
  late Future<List<SonucModel>> sonucList;
  String? _selectedExam; // Seçilen sınav
  Map<String, Map<String, int>> examResults = {}; // Sınav sonuçları için

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav Grafiği'),
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
            // Sınavlara göre modellerin sonuçlarını düzenle
            if (examResults.isEmpty) {
              for (var model in models) {
                model.sinavSonuclari.forEach((exam, score) {
                  if (!examResults.containsKey(exam)) {
                    examResults[exam] = {};
                  }
                  examResults[exam]![model.model] =
                      score; // Model adı ve puanı ekle
                });
              }
            }

            return Column(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButton<String>(
                      hint: const Text('Sınav Seçin'),
                      value: _selectedExam,
                      items: examResults.keys.map((String exam) {
                        return DropdownMenuItem<String>(
                          value: exam,
                          child: Text(exam),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedExam = value;
                        });
                      },
                    ),
                  ),
                ),
                if (_selectedExam != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Ortalama: ${calculateAverage(examResults[_selectedExam]!)}', // Ortalama hesaplama
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 1500, // Grafiğin yüksekliği
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        primaryYAxis: NumericAxis(
                          minimum: 0,
                          maximum: 100,
                        ),
                        series: <CartesianSeries>[
                          BarSeries<MapEntry<String, int>, String>(
                            dataSource: examResults[_selectedExam]!
                                .entries
                                .toList()
                              ..sort((a, b) =>
                                  a.value.compareTo(b.value)), // Ters sıralama
                            xValueMapper: (MapEntry<String, int> entry, _) =>
                                entry.key,
                            yValueMapper: (MapEntry<String, int> entry, _) =>
                                entry.value,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                            ),
                            spacing: 0.01, // Barların genişliğini artırır
                          ),
                        ],
                        tooltipBehavior: TooltipBehavior(enable: true),
                      ),
                    ),
                  ),
                ],
              ],
            );
          }
        },
      ),
    );
  }

  // Ortalama hesaplama fonksiyonu
  double calculateAverage(Map<String, int> scores) {
    if (scores.isEmpty) return 0.0;
    int totalScore = scores.values.reduce((a, b) => a + b);
    return totalScore / scores.length;
  }
}
