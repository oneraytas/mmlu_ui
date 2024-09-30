import 'dart:convert';
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
  String? _selectedFilter;
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

  void _sortColumn(List<SonucModel> list, String column, bool isAscending) {
    setState(() {
      _sortedColumn = column;
      _isAscending = isAscending;

      if (column == "Ortalama") {
        list.sort((a, b) => isAscending
            ? a.ortalama.compareTo(b.ortalama)
            : b.ortalama.compareTo(a.ortalama));
      } else {
        list.sort((a, b) {
          // Sınav sonucu null ise sona at
          if (a.sinavSonuclari[column] == null) return 1;
          if (b.sinavSonuclari[column] == null) return -1;
          return isAscending
              ? a.sinavSonuclari[column]!.compareTo(b.sinavSonuclari[column]!)
              : b.sinavSonuclari[column]!.compareTo(a.sinavSonuclari[column]!);
        });
      }
    });
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return DataTable(
                            headingRowHeight: 60,
                            columnSpacing: 16,
                            columns: [
                              DataColumn(
                                label: const Text('Sıra'),
                              ),
                              DataColumn(
                                label: GestureDetector(
                                  onTap: () {
                                    _sortColumn(
                                        filteredList, "Model", !_isAscending);
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
                                      _sortColumn(filteredList, "Ortalama",
                                          !_isAscending);
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
                                        _sortColumn(
                                            filteredList, sinav, !_isAscending);
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
                                      _sortColumn(filteredList, _selectedSinav!,
                                          !_isAscending);
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
                            rows: filteredList.asMap().entries.map((entry) {
                              int index = entry.key;
                              SonucModel sonuc = entry.value;

                              return DataRow(cells: [
                                DataCell(Text((index + 1).toString())),
                                DataCell(
                                  GestureDetector(
                                    onTap: () {
                                      _launchUrl(
                                          'https://huggingface.co/datasets/alibayram/yapay_zeka_turkce_mmlu_liderlik_tablosu');
                                    },
                                    child: Text(sonuc.model,
                                        style: const TextStyle(
                                            color: Colors.blue)),
                                  ),
                                ),
                                if (_selectedFilter == "Ortalama") ...[
                                  DataCell(Text(sonuc.ortalama.toStringAsFixed(
                                      2))), // Ortalama iki haneli gösteriliyor
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
                                                "-", // Sınav sonucu yoksa "-" göster
                                            style: const TextStyle(
                                                color: Colors.blue)),
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
                                          sonuc.sinavSonuclari[_selectedSinav!]
                                                  ?.toStringAsFixed(2) ??
                                              "-", // Sınav sonucu yoksa "-" göster
                                          style: const TextStyle(
                                              color: Colors.blue)),
                                    ),
                                  ),
                                ],
                              ]);
                            }).toList(),
                          );
                        },
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
