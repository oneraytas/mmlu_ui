import 'dart:convert';
import 'package:mmlu/compare_main.dart';
import 'package:mmlu/model_main.dart';
import 'package:mmlu/sinav_main.dart';
import 'package:mmlu/sonuc_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Colors.white,
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
  String? _selectedFilter = "Ortalama";
  double _ortalamaFiltre = 0;
  String? _selectedSinav;
  bool _isAscending = true;
  String? _sortedColumn;

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

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _sortColumn(List<SonucModel> list, String column) {
    // Orijinal listeyi korumak için bir kopyasını oluştur
    List<SonucModel> sortedList = List.from(list);

    if (_sortedColumn == column) {
      _isAscending = !_isAscending;
    } else {
      _isAscending = true;
    }

    // Sıralama işlemini gerçekleştirin
    if (column == "Ortalama") {
      sortedList.sort((a, b) => _isAscending
          ? a.ortalama.compareTo(b.ortalama)
          : b.ortalama.compareTo(a.ortalama));
    } else {
      sortedList.sort((a, b) {
        if (a.sinavSonuclari[column] == null) return 1;
        if (b.sinavSonuclari[column] == null) return -1;
        return _isAscending
            ? a.sinavSonuclari[column]!.compareTo(b.sinavSonuclari[column]!)
            : b.sinavSonuclari[column]!.compareTo(a.sinavSonuclari[column]!);
      });
    }

    // Durumu güncelle ve sıralanmış listeyi kullan
    setState(() {
      _sortedColumn = column;
      sonucList = Future.value(sortedList); // Sıralı listeyi güncelle
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/icon.png', // İcon.png dosyası burada gösteriliyor
                    width: 130,
                    height: 130,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text('Leaderboard'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LeaderboardPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.model_training),
              title: const Text('Modeller'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ModelMainPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('Sınavlar'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SinavMainPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare),
              title: const Text('Karşılaştırma'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ModelComparePage()),
                );
              },
            ),
          ],
        ),
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
            List<SonucModel> filteredList = snapshot.data!;

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

            List<String> sinavlar =
                snapshot.data![0].sinavSonuclari.keys.toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
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
                    child: Card(
                      color: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            dataRowHeight: 60,
                            headingRowColor: MaterialStateProperty.all(
                                Colors.grey.withOpacity(0.3)),
                            headingTextStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                            columnSpacing: 24,
                            columns: [
                              DataColumn(
                                label: const Text('Sıra'),
                              ),
                              DataColumn(
                                label: GestureDetector(
                                  onTap: () {
                                    _sortColumn(filteredList, "Model");
                                  },
                                  child: Row(
                                    children: [
                                      const Text('Model'),
                                      if (_sortedColumn == "Model")
                                        Icon(
                                          _isAscending
                                              ? Icons.arrow_upward
                                              : Icons.arrow_downward,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_selectedFilter == "Ortalama") ...[
                                DataColumn(
                                  label: GestureDetector(
                                    onTap: () {
                                      _sortColumn(filteredList, "Ortalama");
                                    },
                                    child: Row(
                                      children: [
                                        const Text('Ortalama'),
                                        if (_sortedColumn == "Ortalama")
                                          Icon(
                                            _isAscending
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                ...sinavlar.map((sinav) {
                                  return DataColumn(
                                    label: GestureDetector(
                                      onTap: () {
                                        _sortColumn(filteredList, sinav);
                                      },
                                      child: Row(
                                        children: [
                                          Text(sinav),
                                          if (_sortedColumn == sinav)
                                            Icon(
                                              _isAscending
                                                  ? Icons.arrow_upward
                                                  : Icons.arrow_downward,
                                              size: 16,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ] else if (_selectedSinav != null) ...[
                                DataColumn(
                                  label: GestureDetector(
                                    onTap: () {
                                      _sortColumn(
                                          filteredList, _selectedSinav!);
                                    },
                                    child: Row(
                                      children: [
                                        Text(_selectedSinav!),
                                        if (_sortedColumn == _selectedSinav!)
                                          Icon(
                                            _isAscending
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                            rows: filteredList.asMap().entries.map(
                              (entry) {
                                int index = entry.key;
                                SonucModel sonuc = entry.value;

                                return DataRow(
                                  color:
                                      MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) {
                                      // All rows will have a light blue color.
                                      if (index == 0) {
                                        return Colors.grey.withOpacity(0.1);
                                      } else if (index.isEven) {
                                        return Colors.grey.withOpacity(0.1);
                                      }
                                      return Colors.white;
                                    },
                                  ),
                                  cells: [
                                    DataCell(Text((index + 1).toString())),
                                    DataCell(
                                      GestureDetector(
                                        onTap: () {
                                          _launchUrl(
                                              'https://huggingface.co/datasets/alibayram/yapay_zeka_turkce_mmlu_liderlik_tablosu');
                                        },
                                        child: Text(
                                          sonuc.model,
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                      ),
                                    ),
                                    if (_selectedFilter == "Ortalama") ...[
                                      DataCell(Text(
                                          sonuc.ortalama.toStringAsFixed(2))),
                                      ...sinavlar.map((sinav) {
                                        return DataCell(
                                          GestureDetector(
                                            onTap: () {
                                              _launchUrl(
                                                  'https://huggingface.co/datasets/alibayram/yapay_zeka_turkce_mmlu_model_cevaplari');
                                            },
                                            child: Text(
                                              sonuc.sinavSonuclari[sinav]
                                                      ?.toStringAsFixed(2) ??
                                                  "-",
                                              style: const TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ] else if (_selectedSinav != null) ...[
                                      DataCell(
                                        GestureDetector(
                                          onTap: () {
                                            _launchUrl(
                                                'https://huggingface.co/datasets/alibayram/yapay_zeka_turkce_mmlu_model_cevaplari');
                                          },
                                          child: Text(
                                            sonuc.sinavSonuclari[
                                                        _selectedSinav!]
                                                    ?.toStringAsFixed(2) ??
                                                "-",
                                            style: const TextStyle(
                                                color: Colors.black),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ).toList(),
                          ),
                        ),
                      ),
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
