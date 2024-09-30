import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leaderboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LeaderboardPage(),
    );
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<SonucModel>> sonucList;
  String? _selectedFilter; // Seçilen filtre
  double _ortalamaFiltre = 0; // Slider ile filtrelenecek ortalama
  String? _selectedSinav; // Seçilen sınav

  @override
  void initState() {
    super.initState();
    sonucList = loadSonuclar();
  }

  // JSON dosyasını yükleyen fonksiyon
  Future<List<SonucModel>> loadSonuclar() async {
    final String response = await rootBundle.loadString('assets/sonuclar.json');
    final List<dynamic> data = jsonDecode(response);
    return data.map((json) => SonucModel.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: FutureBuilder<List<SonucModel>>(
        future: sonucList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Veriler yüklenemedi.'));
          } else {
            List<SonucModel> filteredList = snapshot.data!;

            // Seçime göre listeyi filtrele
            if (_selectedFilter == "Ortalama") {
              filteredList = snapshot.data!
                  .where((sonuc) => sonuc.ortalama >= _ortalamaFiltre)
                  .toList();
            } else if (_selectedSinav != null && _selectedFilter != null) {
              filteredList = snapshot.data!
                  .where((sonuc) =>
                      sonuc.sinavSonuclari[_selectedSinav!] != null &&
                      sonuc.sinavSonuclari[_selectedSinav!]! >= _ortalamaFiltre)
                  .toList();
            }

            // Sınav isimlerini al (ComboBox için)
            List<String> sinavlar =
                snapshot.data![0].sinavSonuclari.keys.toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // ComboBox: Ortalama veya sınavları seçmek için
                      DropdownButton<String>(
                        hint: const Text('Filtre Seçin'),
                        value: _selectedFilter,
                        items: [
                          const DropdownMenuItem(
                              value: "Ortalama", child: Text("Ortalama")),
                          ...sinavlar.map((sinav) {
                            return DropdownMenuItem(
                              value: sinav,
                              child: Text(sinav),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value;
                            _selectedSinav = value != "Ortalama" ? value : null;
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      // Ortalama değeri Slider ile ayarlamak
                      Text(
                          'Filtre Değeri: ${_ortalamaFiltre.toStringAsFixed(1)}'),
                      Expanded(
                        child: Slider(
                          value: _ortalamaFiltre,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _ortalamaFiltre.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _ortalamaFiltre = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return DataTable(
                          columns: [
                            const DataColumn(label: Text('Model')),
                            const DataColumn(label: Text('Ortalama')),
                            ...sinavlar
                                .map((sinav) => DataColumn(label: Text(sinav)))
                                .toList(),
                          ],
                          rows: filteredList.map((sonuc) {
                            return DataRow(cells: [
                              DataCell(Text(sonuc.model)),
                              DataCell(Text(sonuc.ortalama.toString())),
                              ...sinavlar.map((sinav) {
                                return DataCell(
                                  Text(sonuc.sinavSonuclari[sinav].toString()),
                                );
                              }).toList(),
                            ]);
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

// JSON verisini modellemek için sınıf
class SonucModel {
  final String model;
  final double ortalama;
  final Map<String, int> sinavSonuclari;

  SonucModel({
    required this.model,
    required this.ortalama,
    required this.sinavSonuclari,
  });

  factory SonucModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> sinavSonuclari = {};
    json.forEach((key, value) {
      if (key != "model" && key != "ortalama") {
        sinavSonuclari[key] = value as int;
      }
    });
    return SonucModel(
      model: json['model'],
      ortalama: json['ortalama'],
      sinavSonuclari: sinavSonuclari,
    );
  }
}
