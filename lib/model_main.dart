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
      home: const ModelMainPage(),
    );
  }
}

class ModelMainPage extends StatefulWidget {
  const ModelMainPage({Key? key}) : super(key: key);

  @override
  _ModelChartPageState createState() => _ModelChartPageState();
}

class _ModelChartPageState extends State<ModelMainPage> {
  late Future<List<SonucModel>> sonucList;
  String? _selectedModel;
  SonucModel? _selectedSonuc;

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
        title: const Text('Model Grafiği'),
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
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButton<String>(
                      hint: const Text('Model Seçin'),
                      value: _selectedModel,
                      items: models.map((SonucModel model) {
                        return DropdownMenuItem<String>(
                          value: model.model,
                          child: Text(model.model),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          _selectedModel = value;
                          _selectedSonuc = models
                              .firstWhere((model) => model.model == value);
                        });
                      },
                    ),
                  ),
                ),
                if (_selectedSonuc != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Ortalama: ${_selectedSonuc!.ortalama}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  Expanded(
                    // Ekranın kalan alanını kapla
                    child: SingleChildScrollView(
                      // Kaydırılabilir alan oluştur
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
                              dataSource: _selectedSonuc!.sinavSonuclari.entries
                                  .toList(),
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
